################################################################################
# Extension library for ../build-rpm-specs.sh
################################################################################
# Extension libraries must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

# PREBUILD_COMMAND
prebuildCommand="source \"${_myLibDir}\"/load-contrib-functions.sh"$'\r'
prebuildCommand+="${_globalSettings[PREBUILD_COMMAND]}"
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
