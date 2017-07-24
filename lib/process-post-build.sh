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

# If necessary, copy S?RPMS to S?RPM_DIRECTORY
actualRPMDir="${_globalSettings[WORKSPACE]}/RPMS"
actualSRPMDir="${_globalSettings[WORKSPACE]}/SRPMS"
desiredRPMDir="${_globalSettings[RPMS_DIRECTORY]}"
desiredSRPMDir="${_globalSettings[SRPMS_DIRECTORY]}"
tallyRPMs=$(ltrim "$(find "$actualRPMDir" -type f -name '*.rpm' | wc -l)")
tallySRPMs=$(ltrim "$(find "$actualSRPMDir" -type f -name '*.srpm' | wc -l)")
if [ 0 -lt $tallyRPMs -o 0 -lt $tallySRPMs ]; then
	packagesBuilt=true
	logVerbose "Post-processing ${tallyRPMs} RPM and ${tallySRPMs} SRPM packages..."
	if ! source "${_myLibDir}"/process-rpm-files-post.sh; then
		errorOut 3 "Unable to import the RPM file post-processing source."
	fi
else
	logWarning "Neither RPMs nor SRPMs were built."
fi

# POSTBUILD_ON_PARTIAL
# POSTBUILD_ON_FAIL
# POSTBUILD_COMMAND
runPostbuildCommand=false
postbuildCommand="${_globalSettings[POSTBUILD_COMMAND]}"
if [ ! -z "$postbuildCommand" ]; then
	if ${_globalSettings[POSTBUILD_ON_FAIL]}; then
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
		logInfo "Running post-build command"
		/usr/bin/env bash -c "$postbuildCommand"
		postbuildState=$?
		if [ 0 -ne $postbuildState ]; then
			logWarning "Received non-zero exit state from the post-build command, ${postbuildState}."
		fi
	fi
fi
unset postbuildState

# KEEP_FAILED_TEMP_WORKSPACE
if ${_globalSettings[USE_TEMP_WORKSPACE]}; then
	tempWorkDir="${_globalSettings[TEMP_WORKSPACE_DIRECTORY]}"
	deleteTempWorkspace=true

	if $packageFailures && ! ${_globalSettings[KEEP_FAILED_TEMP_WORKSPACE]}; then
		logInfo "Preserving temporary workspace directory, ${tempWorkDir}"
		deleteTempWorkspace=false
	fi

	if $deleteTempWorkspace && ! rm -rf "$tempWorkDir"; then
		logWarning "Unable to delete temporary workspace directory, ${tempWorkDir}"
	fi
fi
