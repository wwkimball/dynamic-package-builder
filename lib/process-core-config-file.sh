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

# Set configuration rules (allowable keys and their values)
declare -A configValueRules
configValueRules[EXECUTABLE_SPECS]='^(true|false)$'
configValueRules[GLOBAL_CONFIG_SOURCE]='^.+$'
configValueRules[OUTPUT_DEBUG]='^(true|false)$'
configValueRules[OUTPUT_VERBOSE]='^(true|false)$'
configValueRules[POSTBUILD_COMMAND]='^.+$'
configValueRules[POSTBUILD_ON_FAIL]='^(true|false)$'
configValueRules[POSTBUILD_ON_PARTIAL]='^(true|false)$'
configValueRules[PREBUILD_COMMAND]='^.+$'
configValueRules[PURGE_RPMS_ON_START]='^(true|false)$'
configValueRules[PURGE_SPECS_ON_START]='^(true|false)$'
configValueRules[PURGE_TEMP_WORKSPACES_ON_START]='^(true|false)$'
configValueRules[RPMBUILD_ARGS]='^[^;&]+$'
configValueRules[SOURCES_DIRECTORY]='^.+$'
configValueRules[SPECS_DIRECTORY]='^.+$'
configValueRules[USE_TEMP_WORKSPACE]='^(true|false)$'
configValueRules[WORKSPACE]='^.+$'

# The configuration source may be a file or directory.  When it is a directory,
# attempt to source every file within it in alphabetical order.
configSource="${_globalSettings[GLOBAL_CONFIG_SOURCE]}"
hasConfigError=false
if [ -d "$configSource" ]; then
	while IFS= read -r -d '' configFile; do
		if ! parseConfigFile _globalSettings "$configFile" configValueRules; then
			logError "Unable to read from configuration file, ${configFile}."
			hasConfigError=true
		fi
	done < <(find "$configSource" -maxdepth 1 -type f -iname '*.conf' -print0)
elif [ -e "$configSource" ]; then
	if ! parseConfigFile _globalSettings "$configFile" configValueRules; then
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
unset configSource configFile hasConfigError configKey parseConfigFile \
	configValueRules
