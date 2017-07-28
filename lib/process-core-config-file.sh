################################################################################
# Extension library for ../build-rpm-specs.sh
#
# Preconditions:
# * Declared before calling this code:  confFileSettings, _globalSettingsRules
################################################################################
# Extension libraries must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

# Import helper functions
if ! source "${_funcDir}"/parse-config-file.sh; then
	errorOut 3 "Unable to import the config file parser."
fi

# The configuration source may be a file or directory.  When it is a directory,
# attempt to source every file within it in alphabetical order.
configSource="${_globalSettings[GLOBAL_CONFIG_SOURCE]}"
logDebug "Loading global configuration from source, ${configSource}"
hasConfigError=false
if [ -d "$configSource" ]; then
	while IFS= read -r -d '' configFile; do
		if ! parseConfigFile "$configFile" confFileSettings _globalSettingsRules; then
			logError "Unable to read from configuration file, ${configFile}."
			hasConfigError=true
		fi
	done < <(find "$configSource" -maxdepth 1 -type f -iname '*.conf' -print0)
elif [ -e "$configSource" ]; then
	if ! parseConfigFile "$configSource" confFileSettings _globalSettingsRules; then
		logError "Unable to read from configuration file, ${configSource}."
		hasConfigError=true
	fi
elif ${_globalSettings[USER_SET_GLOBAL_CONFIG_SOURCE]}; then
	# User-specified settings file does not exist
	logWarning "No settings file found at ${configSource}."
fi

# Abort on error
if $hasConfigError; then
	exit 3
fi

# Cleanup
unset configSource configFile hasConfigError
