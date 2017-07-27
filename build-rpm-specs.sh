#!/usr/bin/env bash
################################################################################
# Attempts to build RPMs from all *.spec files found in a specified directory.
# Will also attempt to run any executable files in the same directory, just in
# case those files can generate any *.spec files.  Also handles much of the
# standard boilerplate and setup that is typical of most RPM builds.
################################################################################
_myDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_myFileName=$(basename ${BASH_SOURCE[0]})
_myName=${_myFileName%.*}
_myLibDir="${_myDir}/lib"
_funcDir="${_myLibDir}/func"
_myVersion='2017.7.16.1'
_pwDir="$(pwd)"
_exitCode=0
readonly _myDir _myFileName _myName _myLibDir _funcDir _myVersion _pwDir

# Attempt to source the output logger functions
if ! source "${_myLibDir}"/set-logger.sh; then
	echo "ERROR:  Unable to import the logger source." >&2
	exit 3
fi

# Prohibit running as root
if [ 0 -eq $(id -u) ]; then
	errorOut 126 "You must not run ${_myFileName} as root!"
fi

# Bash 4.3+ is required
if [[ $BASH_VERSION =~ ^([0-9]+\.[0-9]+).+$ ]]; then
	bashMajMin=${BASH_REMATCH[1]}
	bashMinVer='4.3'
	if [ 0 -ne $(bc <<< "${bashMinVer} > ${bashMajMin}") ]; then
		errorOut 127 "bash version ${bashMinVer} or higher is required.  You have ${BASH_VERSION}."
	fi
	unset bashMajMin bashMinVer
else
	errorOut 128 "Unable to identify the installed version of bash."
fi

# rpmbuild must be installed
if ! which rpmbuild &>/dev/null; then
	errorOut 125 "The rpmbuild program must be installed and accessible on the PATH."
fi

# Process global configuration
logInfo "Processing global configuration..."
if ! source "${_myLibDir}"/define-global-settings.sh; then
	errorOut 3 "Unable to import the global configuration source."
fi

# PREBUILD_COMMAND
if [ ! -z "${_globalSettings[PREBUILD_COMMAND]}" ]; then
	logInfo "Running pre-build command..."
	/usr/bin/env bash -c "${_globalSettings[PREBUILD_COMMAND]}"
	prebuildState=$?
	if [ 0 -ne $prebuildState ]; then
		errorOut 12 "Received non-zero exit state from the pre-build command, ${prebuildState}."
	fi
fi
unset prebuildState

# Prepare the workspace
logInfo "Preparing an S/RPM building workspace at ${_globalSettings[WORKSPACE]}..."
if ! source "${_myLibDir}"/prep-workspace.sh; then
	errorOut 3 "Unable to import the workstation preparation source."
fi

# Interpolate variables in the spec templates
logInfo "Interpolating variables in all RPM specification files..."
if ! source "${_myLibDir}"/process-spec-templates.sh; then
	errorOut 3 "Unable to import the spec template processing source."
fi

# Interpolate variables in the spec templates
logInfo "Building S/RPMs from your spec files..."
if ! source "${_myLibDir}"/process-rpm-specs.sh; then
	errorOut 3 "Unable to import the spec processing source."
fi

# Handle post-build processing
logInfo "Running post-processing tasks..."
if ! source "${_myLibDir}"/process-post-build.sh; then
	errorOut 3 "Unable to import the post-build processing source."
fi

# Report overall success/fail to the caller
exit $_exitCode
