################################################################################
# Extension library for ../build-rpm-specs.sh
################################################################################
# Extension libraries must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

# Import helper functions
if ! source "${_funcDir}"/process-config-file.sh; then
	errorOut 3 "Unable to import the config file processor."
fi

# The configuration source may be a file or directory.  When it is a directory,
# attempt to source every file within it in alphabetical order.
configSource="${_globalSettings[GLOBAL_CONFIG_SOURCE]}"
hasConfigError=false
if [ -d "$configSource" ]; then
	while IFS= read -r -d '' configFile; do
		if ! parseConfigFile _globalSettings "$configFile" _globalSettingsRules; then
			logError "Unable to read from configuration file, ${configFile}."
			hasConfigError=true
		fi
	done < <(find "$configSource" -maxdepth 1 -type f -iname '*.conf' -print0)
elif [ -e "$configSource" ]; then
	if ! parseConfigFile _globalSettings "$configFile" _globalSettingsRules; then
		logError "Unable to read from configuration file, ${configFile}."
		hasConfigError=true
	fi
elif ${_globalSettings[USER_SET_GLOBAL_CONFIG_SOURCE]}; then
	# User-specified settings file does not exit
	logWarning "No settings file found at ${configSource}."
fi

# Abort on error
if $hasConfigError; then
	exit 3
fi

# Report all gathered configuration values
echo
logDebug "Accepted Configuration Values:"
for configKey in "${!_globalSettings[@]}"; do
  logDebug "...${configKey} => ${_globalSettings[$configKey]}"
done
echo

# Cleanup
unset configSource configFile hasConfigError configKey parseConfigFile
