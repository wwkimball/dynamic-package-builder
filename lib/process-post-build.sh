################################################################################
# Extension library for ../build-rpm-specs.sh
################################################################################
# Extension libraries must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

# Import helper functions
if ! source "${_funcDir}"/trims.sh; then
	errorOut 3 "Unable to import the string trimming helpers."
fi

# Check for build successes and failures (these are not mutually exclusive)
packagesBuilt=false
packageFailures=false
if [ 0 -lt ${_globalSettings[PACKAGES_BUILT]} ]; then
	packagesBuilt=true
fi
if [ 0 -lt ${_globalSettings[PACKAGES_FAILED]} ]; then
	packageFailures=true
fi

# If necessary, copy S?RPMS to S?RPM_DIRECTORY
actualRPMDir="${_globalSettings[TEMP_WORKSPACE]}/RPMS"
actualSRPMDir="${_globalSettings[TEMP_WORKSPACE]}/SRPMS"
desiredRPMDir="${_globalSettings[RPMS_DIRECTORY]}"
desiredSRPMDir="${_globalSettings[SRPMS_DIRECTORY]}"
tallyRPMs=$(ltrim "$(find "$actualRPMDir" -type f -name '*.rpm' 2>/dev/null | wc -l)")
tallySRPMs=$(ltrim "$(find "$actualSRPMDir" -type f -name '*.src.rpm' 2>/dev/null | wc -l)")
if $packagesBuilt; then
	logVerbose "Post-processing ${tallyRPMs} RPM and ${tallySRPMs} SRPM packages..."

	if [ 0 -lt $tallyRPMs ] && [ "$actualRPMDir" != "$desiredRPMDir" ]; then
		logInfo "Copying generated RPMs from ${actualRPMDir} to ${desiredRPMDir}"
		if ! mkdir -p "$desiredRPMDir" \
			|| ! cp -Rf "$actualRPMDir"/* "$desiredRPMDir"/
		then
			logWarning "Unable to copy RPMs from ${actualRPMDir} to ${desiredRPMDir}"
		fi
	fi
	if [ 0 -lt $tallySRPMs ] && [ "$actualSRPMDir" != "$desiredSRPMDir" ]; then
		logInfo "Copying generated SRPMs from ${actualSRPMDir} to ${desiredSRPMDir}"
		if ! mkdir -p "$desiredSRPMDir" \
			|| ! cp -Rf "$actualSRPMDir"/* "$desiredSRPMDir"/
		then
			logWarning "Unable to copy SRPMs from ${actualSRPMDir} to ${desiredSRPMDir}"
		fi
	fi

	# If requested, FLATTEN_RPM_DIRECTORIES (SRPMS are already flat)
	if ${_globalSettings[FLATTEN_RPMS_DIRECTORY]} && [ 0 -lt $tallyRPMs ]; then
		logInfo "Flattening ${desiredRPMDir}"
		find "$desiredRPMDir" -type f -name '*.rpm' -exec mv {} "$desiredRPMDir" \;
		find "$desiredRPMDir" -type d ! \( -name $(basename "$desiredRPMDir") -o -name . \) -delete
	fi
else
	# If no packages were built, assume total failure
	packageFailures=true
	logError "Neither RPMs nor SRPMs were built."
	_globalSettings[EXIT_CODE]=103
fi

# POSTBUILD_ON_PARTIAL
# POSTBUILD_ON_FAIL
# POSTBUILD_COMMAND
runPostbuildCommand=false
if [ -z "${_globalSettings[POSTBUILD_COMMAND]}" ]; then
	# Nothing to do
	runPostbuildCommand=false
elif ${_globalSettings[POSTBUILD_ON_FAIL]}; then
	# Run the command, no matter what
	runPostbuildCommand=true
elif $packagesBuilt && ${_globalSettings[POSTBUILD_ON_PARTIAL]}; then
	# Run the command when at least one package was built
	runPostbuildCommand=true
elif $packagesBuilt && ! $packageFailures; then
	# Run the command when everything succeeded
	runPostbuildCommand=true
fi
if $runPostbuildCommand; then
	postbuildCommand=$(cat <<-EOCOMM
		source "${_myLibDir}"/load-contrib-functions.sh
		${_globalSettings[POSTBUILD_COMMAND]}
	EOCOMM
	)
	logDebug "Composed postbuild command:\r${postbuildCommand}"
	logInfo "Running post-build command"
	/usr/bin/env bash -c "$postbuildCommand"
	postbuildState=$?
	if [ 0 -ne $postbuildState ]; then
		logError "Received non-zero exit state from the post-build command, ${postbuildState}."
		_globalSettings[EXIT_CODE]=102
	fi
fi

# KEEP_FAILED_TEMP_WORKSPACE
if ${_globalSettings[USE_TEMP_WORKSPACE]}; then
	tempWorkDir="${_globalSettings[TEMP_WORKSPACE]}"
	deleteTempWorkspace=true

	if $packageFailures && ${_globalSettings[KEEP_FAILED_TEMP_WORKSPACE]}; then
		logInfo "Preserving failed temporary workspace directory, ${tempWorkDir}"
		deleteTempWorkspace=false
	fi

	if $deleteTempWorkspace && ! rm -rf "$tempWorkDir"; then
		logWarning "Unable to delete temporary workspace directory, ${tempWorkDir}"
	fi
fi

# Cleanup
unset packagesBuilt packageFailures actualRPMDir actualSRPMDir desiredRPMDir \
	desiredSRPMDir tallyRPMs tallySRPMs runPostbuildCommand postbuildCommand \
	postbuildState tempWorkDir deleteTempWorkspace
