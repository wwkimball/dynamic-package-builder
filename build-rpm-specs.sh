#!/bin/bash
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
readonly _myDir _myFileName _myLibDir _myVersion _pwDir

# Define default values for configuration values
configSource="${_pwDir}"/rpm-helpers.conf
workSpaceDir=${WORKSPACE:-$(pwd)}

# Process command-line arguments
source "${_myLibDir}"/process-args.sh

# Attempt to load the configuration file(s)
source "${_myLibDir}"/process-config-file.sh

cat <<EOF
WORKSPACE: ${workSpaceDir}
EOF
