################################################################################
# Extension library for ../build-rpm-specs.sh
#
# Copyright 2001, 2018 William W. Kimball, Jr. MBA MSIS
################################################################################
# Extension libraries must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

# PREBUILD_COMMAND
prebuildCommand=$(cat <<EOCOMM
if ! source "${_myLibDir}"/load-contrib-functions.sh; then
	echo "ERROR:  Unable to import the contributed function loader!" >&2
fi
${_globalSettings[PREBUILD_COMMAND]}
EOCOMM
)
logDebug "Composed prebuild command:\n\r${prebuildCommand}"
if [ ! -z "${_globalSettings[PREBUILD_COMMAND]}" ]; then
	logInfo "Running pre-build command..."
	/usr/bin/env bash -c "$prebuildCommand"
	prebuildState=$?
	if [ 0 -ne $prebuildState ]; then
		errorOut 12 "Received non-zero exit state from the pre-build command, ${prebuildState}."
	fi
fi

# Cleanup
unset prebuildCommand prebuildState
