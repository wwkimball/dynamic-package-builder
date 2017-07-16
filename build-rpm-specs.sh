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

# Prohibit running as root
if [ 0 -eq $(id -u) ]; then
	echo "ERROR:  You must not run ${_myFileName} as root!" >&2
	exit 126
fi

# Bash 4.3+ is required
if [[ $BASH_VERSION =~ ^([0-9]+\.[0-9]+).+$ ]]; then
	bashMajMin=${BASH_REMATCH[1]}
	bashMinVer='4.3'
	if [ 0 -ne $(bc <<< "${bashMinVer} > ${bashMajMin}") ]; then
		echo "ERROR:  bash version ${bashMinVer} or higher is required.  You have ${BASH_VERSION}." >&2
		exit 127
	fi
	unset bashMajMin bashMinVer
else
	echo "ERROR:  Unable to identify the installed version of bash." >&2
	exit 128
fi

# Define the global configuration settings map
declare -A _globalSettings

# Process command-line arguments
source "${_myLibDir}"/process-args.sh

# Attempt to load the core configuration file(s).  These are for setting the
# overall behavior of the RPM build, like the primary workspace directory and
# other routine configuration like whether to build the full RPM construction
# directory tree.
source "${_myLibDir}"/process-core-config-file.sh

# Optionally destroy all *.spec files in the RPM specs directory, presumably
# because they are to be dynamically reconstructed.

# Optionally run executables found in the RPM specs directory to potentially
# create more specs files.

# Run rpmbuild against every *.spec file in the RPM specs directory.

# If any *.rpm files were created, validate them.

# Optionally move validated RPMs to a publication directory.

cat <<EOF

Known Settings:
WORKSPACE: ${_globalSettings[WORKSPACE]}

Args for rpmbuild:
${_globalSettings[RPMBUILD_ARGS]}
EOF
