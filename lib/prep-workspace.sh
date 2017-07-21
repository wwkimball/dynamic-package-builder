################################################################################
# Extension library for ../build-rpm-specs.sh
################################################################################
# Extension libraries must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

# Import helper functions
if ! source "${_funcDir}"/interpolate-variables.sh; then
	errorOut 3 "Unable to import the interpolate-variables helper."
fi

# Expand certain variables in the path
workspaceDir="$(realpath -m "$(interpolateVariables "${_globalSettings[WORKSPACE]}")")"
_globalSettings[WORKSPACE]="$workspaceDir"

# PURGE_TEMP_WORKSPACES_ON_START
if ${_globalSettings[PURGE_TEMP_WORKSPACES_ON_START]}; then
	logDebug "Would destroy:  ${_globalSettings[TEMP_WORKSPACE_DIRECTORY_MASK]}"
	#rm -rf "${_globalSettings[TEMP_WORKSPACE_DIRECTORY_MASK]}"
fi

# Ensure USE_TEMP_WORKSPACE is set appropriately
if ! ${_globalSettings[USE_TEMP_WORKSPACE]}; then
	# SPECS_DIRECTORY
	if ${_globalSettings[USER_SET_SPECS_DIRECTORY]}; then
		expectedSpecsDirectory="${workspaceDir}/SPECS"
		if [ "$expectedSpecsDirectory" != "${_globalSettings[SPECS_DIRECTORY]}" ]
		then
			logDebug "Expecting SPECS_DIRECTORY:  ${expectedSpecsDirectory}"
			logWarning "Forcing USE_TEMP_WORKSPACE because the indicated SPECS directory is outside the WORKSPACE."
			_globalSettings[USE_TEMP_WORKSPACE]=true
		fi
	fi

	# SOURCES_DIRECTORY
	if ${_globalSettings[USER_SET_SOURCES_DIRECTORY]}; then
		expectedSourcesDirectory="${workspaceDir}/SOURCES"
		if [ "$expectedSourcesDirectory" != "${_globalSettings[SOURCES_DIRECTORY]}" ]
		then
			logDebug "Expecting SOURCES_DIRECTORY:  ${expectedSourcesDirectory}"
			logWarning "Forcing USE_TEMP_WORKSPACE because the indicated SOURCES directory is outside the WORKSPACE."
			_globalSettings[USE_TEMP_WORKSPACE]=true
		fi
	fi
fi

# USE_TEMP_WORKSPACE

# Build the mandatory RPM workspace directory tree
exit 0
logDebug "Ensuring the required RPM building subdirectories exist at ${_globalSettings[WORKSPACE]}."
if ! mkdir -p "${_globalSettings[WORKSPACE]}"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}; then
	errorOut 4 "Unable to create RPM building workspace at ${_globalSettings[WORKSPACE]}."
fi

# PURGE_RPMS_ON_START

# Optionally destroy all *.spec files in the RPM specs directory, presumably
# because they are to be dynamically reconstructed.
# PURGE_SPECS_ON_START

# Optionally run executables found in the RPM specs directory to potentially
# create more specs files.
# EXECUTABLE_SPECS

# Cleanup
unset workspaceDir
