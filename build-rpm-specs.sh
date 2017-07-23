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
readonly _myDir _myFileName _myName _myLibDir _funcDir _myVersion _pwDir

# Bail if the file cannot be sourced without error
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
logVerbose "Processing global configuration..."
if ! source "${_myLibDir}"/define-global-settings.sh; then
	errorOut 3 "Unable to import the global configuration source."
fi

# PREBUILD_COMMAND
if [ ! -z "${_globalSettings[PREBUILD_COMMAND]}" ]; then
	logInfo "Running pre-build command"
	${_globalSettings[PREBUILD_COMMAND]}
	prebuildState=$?
	if [ 0 -ne $prebuildState ]; then
		errorOut 12 "Received non-zero exit state from the pre-build command, ${prebuildState}."
	fi
fi
unset prebuildState

# Prepare the workspace
logVerbose "Preparing for RPM building at ${_globalSettings[WORKSPACE]}..."
if ! source "${_myLibDir}"/prep-workspace.sh; then
	errorOut 3 "Unable to import the workstation preparation source."
fi

# Interpolate variables in the spec templates
logVerbose "Interpolating variables in all RPM specification files..."
if ! source "${_myLibDir}"/process-spec-templates.sh; then
	errorOut 3 "Unable to import the spec template processing source."
fi

# Run rpmbuild against every *.spec file in the RPM specs directory
packagesBuilt=false
packageFailures=false
while IFS= read -r -d '' specFile; do
	logInfo "Building ${specFile}..."
	if rpmbuild \
		--define "_topdir ${_globalSettings[WORKSPACE]}" \
		-ba "$specFile" \
		"${_globalSettings[RPMBUILD_ARGS]}"
	then
		packagesBuilt=true
	else
		logWarning "${specFile} has failed to build."
		packageFailures=true
	fi
done < <(find "${_globalSettings[SPECS_DIRECTORY]}" -maxdepth 1 -type f -name '*.spec' -print0)

# TODO:  Remove these debugging lines
touch "${_globalSettings[WORKSPACE]}"/RPMS/test.rpm
touch "${_globalSettings[WORKSPACE]}"/SRPMS/test.srpm

# Handle post-build processing
logVerbose "Post-processing..."
if ! source "${_myLibDir}"/process-post-build.sh; then
	errorOut 3 "Unable to import the post-build processing source."
fi
