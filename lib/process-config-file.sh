#!/bin/bash
################################################################################
# Extension library for ../build-rpm-specs.sh
################################################################################
# Extension libraries must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

# Do nothing when there is nothing to do
if [ -z "$configSource" ]; then
	exit 0
fi

# The configuration source may be a file or directory.  When it is a directory,
# attempt to source every file within it in alphabetical order.
hasConfigError=false
if [ -d "$configSource" ]; then
	while IFS= read -r -d '' configFile; do
		if ! source "$configFile"; then
			echo "ERROR:  Unable to read from configuration file, ${configFile}." >&2
			hasConfigError=true
		fi
	done < <(find "$configSource" -maxdepth 1 -type f -iname '*.conf' -print0)
elif [ -e "$configSource" ]; then
	if ! source "$configSource"; then
		echo "ERROR:  Unable to read from configuration file, ${configFile}." >&2
		hasConfigError=true
	fi
fi

# Abort on error
if $hasConfigError; then
	exit 3
fi

# Cleanup
unset configFile hasConfigError
