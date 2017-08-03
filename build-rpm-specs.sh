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
_myFuncDir="${_myLibDir}/func"
_myVersion='2017.7.16.1'
_pwDir="$(pwd)"
readonly _myDir _myFileName _myName _myLibDir _myFuncDir _myVersion _pwDir
export _myDir _myLibDir _myFuncDir

# Attempt to source the output logger functions
if ! source "${_myLibDir}"/set-logger.sh; then
	echo "ERROR:  Unable to import the logger source." >&2
	exit 3
fi

# Check pre-requisites
if ! source "${_myLibDir}"/check-prereqs.sh; then
	errorOut 3 "Unable to import the pre-requisites checker."
fi

# Process global configuration, which will be stored and shared via a settings
# map, and constrained by some value rules.  Reset them both to ensure no
# settings are being injected from elsewhere.
unset _globalSettings _globalSettingsRules
declare -A _globalSettings
declare -A _globalSettingsRules
_globalSettings[EXIT_CODE]=0		# The code this script will ultimately return to caller
_globalSettings[PACKAGES_BUILT]=0	# Number of successfully-built packages
_globalSettings[PACKAGES_FAILED]=0	# Number of failed package build attempts
if ! source "${_myLibDir}"/define-global-settings.sh; then
	errorOut 3 "Unable to import the global configuration source."
fi

# Handle pre-build processing
logInfo "Running pre-processing tasks..."
if ! source "${_myLibDir}"/process-pre-build.sh; then
	errorOut 3 "Unable to import the pre-build processing source."
fi

# Prepare the workspace
logInfo "Preparing an S/RPM building workspace at ${_globalSettings[TEMP_WORKSPACE]}..."
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
exit ${_globalSettings[EXIT_CODE]}
