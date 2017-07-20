#!/usr/bin/env bash
################################################################################
# Attempts to build RPMs from all *.spec files found in a specified directory.
# Will also attempt to run any executable files in the same directory, just in
# case those files can generate any *.spec files.  Also handles much of the
# standard boilerplate and setup that is typical of most RPM builds.
################################################################################
_myDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_myFileName=$(basename ${BASH_SOURCE[0]})
_myLibDir="${_myDir}/lib"
_myVersion='2017.7.16.1'
_pwDir="$(pwd)"
_libDir="${_myDir}/lib"
_funcDir="${_libDir}/func"
readonly _myDir _myFileName _myLibDir _myVersion _pwDir

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

# Define the global configuration settings map
declare -A _globalSettings

# Process command-line arguments
if ! source "${_myLibDir}"/process-args.sh; then
	errorOut 3 "Unable to import the argument processing source."
fi

# Attempt to load the core configuration file(s).  These are for setting the
# overall behavior of the RPM build, not each RPM.
logVerbose "Processing the global configuration file(s)..."
if ! source "${_myLibDir}"/process-core-config-file.sh; then
	errorOut 3 "Unable to import the core config processing source."
fi

# Prepare the workspace
logVerbose "Preparing the workspace for RPM building..."
if ! source "${_myLibDir}"/prep-workspace.sh; then
	errorOut 3 "Unable to import the workstation preparation source."
fi

# Run rpmbuild against every *.spec file in the RPM specs directory.

# If any *.rpm files were created, validate them.

# Optionally move validated RPMs to a publication directory.

logDebug "$(cat <<EOF

Known Settings:
WORKSPACE: ${_globalSettings[WORKSPACE]}

Args for rpmbuild:
${_globalSettings[RPMBUILD_ARGS]}
EOF
)"
