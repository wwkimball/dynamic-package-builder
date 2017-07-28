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

# PURGE_RPMS_ON_START and PURGE_SRPMS_ON_START
if ${_globalSettings[PURGE_RPMS_ON_START]}; then
	logInfo "Deleting old RPM files from all directories under ${_globalSettings[RPMS_DIRECTORY]}"
	while IFS= read -r -d '' rpmFile; do
		logDebug "Deleting old RPM file:  ${rpmFile}"
		if ! rm -f "$rpmFile"; then
			errorOut 11 "Unable to delete old RPM file:  ${rpmFile}"
		fi
	done < <(find "${_globalSettings[RPMS_DIRECTORY]}" -type f -iname "*.rpm" -print0)
fi
if ${_globalSettings[PURGE_SRPMS_ON_START]}; then
	logInfo "Deleting old SRPM files from all directories under ${_globalSettings[SRPMS_DIRECTORY]}"
	while IFS= read -r -d '' rpmFile; do
		logDebug "Deleting old SRPM file:  ${rpmFile}"
		if ! rm -f "$rpmFile"; then
			errorOut 11 "Unable to delete old SRPM file:  ${rpmFile}"
		fi
	done < <(find "${_globalSettings[SRPMS_DIRECTORY]}" -type f -iname "*.src.rpm" -print0)
fi

# PURGE_TEMP_WORKSPACES_ON_START
if ${_globalSettings[PURGE_TEMP_WORKSPACES_ON_START]}; then
	logInfo "Deleting old workspaces matching:  ${_globalSettings[WORKSPACE]}/${_globalSettings[TEMP_WORKSPACE_DIRECTORY_MASK]}"
	while IFS= read -r -d '' tempWorkspace; do
		logDebug "Deleting old workspace directory:  ${tempWorkspace}"
		if ! rm -rf "$tempWorkspace"; then
			logWarning "Unable to delete old workspace directory:  ${tempWorkspace}"
		fi
	done < <(find "${_globalSettings[WORKSPACE]}" -maxdepth 1 -type d -name "${_globalSettings[TEMP_WORKSPACE_DIRECTORY_MASK]}" -print0)
fi

# Ensure USE_TEMP_WORKSPACE is set appropriately
if ! ${_globalSettings[USE_TEMP_WORKSPACE]}; then
	# SPECS_DIRECTORY
	if ${_globalSettings[USER_SET_SPECS_DIRECTORY]}; then
		expectedSpecsDirectory="${workspaceDir}/SPECS"
		logDebug "Expecting SPECS_DIRECTORY:  ${expectedSpecsDirectory}"
		if [ "$expectedSpecsDirectory" != "${_globalSettings[SPECS_DIRECTORY]}" ]
		then
			logWarning "Forcing USE_TEMP_WORKSPACE because the indicated SPECS directory differs from the required location, ${expectedSpecsDirectory}."
			_globalSettings[USE_TEMP_WORKSPACE]=true
		fi
	fi
fi
if ! ${_globalSettings[USE_TEMP_WORKSPACE]}; then
	# SOURCES_DIRECTORY
	if ${_globalSettings[USER_SET_SOURCES_DIRECTORY]}; then
		expectedSourcesDirectory="${workspaceDir}/SOURCES"
		logDebug "Expecting SOURCES_DIRECTORY:  ${expectedSourcesDirectory}"
		if [ "$expectedSourcesDirectory" != "${_globalSettings[SOURCES_DIRECTORY]}" ]
		then
			logWarning "Forcing USE_TEMP_WORKSPACE because the indicated SOURCES directory differs from the required location, ${expectedSourcesDirectory}."
			_globalSettings[USE_TEMP_WORKSPACE]=true
		fi
	fi
fi

# USE_TEMP_WORKSPACE
if ${_globalSettings[USE_TEMP_WORKSPACE]}; then
	logInfo "Creating temporary workspace at ${_globalSettings[TEMP_WORKSPACE_DIRECTORY]}"
	if ! mkdir -p "${_globalSettings[TEMP_WORKSPACE_DIRECTORY]}"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
	then
		errorOut 2 "Unable to create temporary workspace at ${_globalSettings[TEMP_WORKSPACE_DIRECTORY]}"
	fi

	# Moving WORKSPACE to TEMP_WORKSPACE_DIRECTORY
	_globalSettings[WORKSPACE]="${_globalSettings[TEMP_WORKSPACE_DIRECTORY]}"

	# Copy all SPECS and SOURCES
	copyFrom="${_globalSettings[SPECS_DIRECTORY]}"
	copyTo="${_globalSettings[TEMP_WORKSPACE_DIRECTORY]}/SPECS"
	if stat "${copyFrom}"/* &>/dev/null; then
		if ! cp -R "$copyFrom"/* "$copyTo"; then
			errorOut 2 "Unable to copy SPECS files from ${copyFrom} to ${copyTo}"
		fi
	else
		# There's nothing to do if there aren't any SPECS files
		errorOut 2 "There are no files to copy from ${copyFrom} to ${copyTo}"
	fi
	_globalSettings[SPECS_DIRECTORY]="${copyTo}"

	copyFrom="${_globalSettings[SOURCES_DIRECTORY]}"
	copyTo="${_globalSettings[TEMP_WORKSPACE_DIRECTORY]}/SOURCES"
	if stat "${copyFrom}"/* &>/dev/null; then
		if ! cp -R "$copyFrom"/* "$copyTo"; then
			errorOut 2 "Unable to copy SOURCES files from ${copyFrom} to ${copyTo}"
		fi
	fi
	_globalSettings[SOURCES_DIRECTORY]="${copyTo}"
else
	# Build the mandatory RPM workspace directory tree at WORKSPACE
	logDebug "Ensuring the required RPM building subdirectories exist at ${_globalSettings[WORKSPACE]}."
	if ! mkdir -p "${_globalSettings[WORKSPACE]}"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}; then
		errorOut 4 "Unable to create RPM building workspace at ${_globalSettings[WORKSPACE]}."
	fi
fi

# Optionally destroy all *.spec files in the RPM specs directory, presumably
# because they are to be dynamically reconstructed.
# PURGE_SPECS_ON_START
if ${_globalSettings[PURGE_SPECS_ON_START]}; then
	logInfo "Deleting old spec files, if any exist"
	if ! rm -f "${_globalSettings[SPECS_DIRECTORY]}"/*.spec; then
		errorOut 9 "Unable to delete old spec files from ${_globalSettings[SPECS_DIRECTORY]}"
	fi
fi

# Optionally run executables found in the RPM specs directory to potentially
# create more specs files.
# EXECUTABLE_SPECS
if ${_globalSettings[EXECUTABLE_SPECS]}; then
	logInfo "Running all executables in ${_globalSettings[SPECS_DIRECTORY]}"

	# Enter the SPECS directory to run all executables within
	pushd "${_globalSettings[SPECS_DIRECTORY]}" &>/dev/null

	while IFS= read -r -d '' execFile; do
		if [ ! -x "$execFile" ]; then
			logDebug "Skipping non-executable file, ${execFile}"
			continue
		fi

		logDebug "Running executable:  ${execFile}"
		/usr/bin/env bash -c "$execFile"
		execState=$?
		if [ 0 -ne $execState ]; then
			errorOut 10 "Executable file, ${execFile}, returned non-zero exit state:  ${execState}"
		fi
	done < <(find . -maxdepth 1 -type f -print0)

	# Return to the previous directory
	popd &>/dev/null
fi

# Cleanup
unset workspaceDir copyFrom copyTo execFile execState rpmFile \
	expectedSpecsDirectory expectedSourcesDirectory
