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
_myVersion='2003.8.12.1'
_pwDir="$(pwd)"
_libDir="${_myDir}/lib"
_funcDir="${_libDir}/func"
readonly _myDir _myFileName _myLibDir _myVersion _pwDir

# Bash 4.x is required
if (( ${BASH_VERSION%%.*} < 4 )); then
	echo "ERROR:  bash version 4 or higher is required.  You have ${BASH_VERSION}." >&2
	exit 127
fi

# Prohibit running as root
if [ 0 -eq $(id -u) ]; then
	echo "ERROR:  You must not run ${_myFileName} as root!" >&2
	exit 126
fi

# Define default values for configuration values
declare -A _configMap
declare -a _positionalArgs
_configMap[CONFIG_SOURCE]="${_pwDir}"/rpm-helpers.conf
_configMap[WORKSPACE]=${WORKSPACE:-$(pwd)}

# Process command-line arguments
source "${_myLibDir}"/process-args.sh

# Attempt to load the configuration file(s)
source "${_myLibDir}"/process-core-config-file.sh

cat <<EOF
WORKSPACE: ${_configMap[WORKSPACE]}
EOF
