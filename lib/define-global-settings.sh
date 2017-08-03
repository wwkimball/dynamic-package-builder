################################################################################
# Extension library for ../build-rpm-specs.sh
# Defaults < Environment Variables < Config Settings < Command-Line Arguments
################################################################################
# Extension libraries must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

# Import helper functions
if ! source "${_myFuncDir}"/store-allowed-setting.sh; then
	errorOut 3 "Unable to import the store-allowed-setting helper."
fi
if ! source "${_myFuncDir}"/interpolate-variables.sh; then
	errorOut 3 "Unable to import the interpolate-variables helper."
fi
if ! source "${_myFuncDir}"/print-ordered-hash.sh; then
	errorOut 3 "Unable to import the print-ordered-hash helper."
fi

# Copy collected settings to the global configuration map
function __defineGlobalSettings__applySettingsToGlobalConfig {
	local -n settingsMap=${1?"ERROR:  A settings map must be provided as the first positional argument to ${FUNCNAME[0]}."}
	local configKey

	for configKey in "${!settingsMap[@]}"; do
		_globalSettings[$configKey]="${settingsMap[$configKey]}"

		# Changing some settings triggers other down-stream code
		case "$configKey" in
			GLOBAL_CONFIG_SOURCE)
				_globalSettings[USER_SET_GLOBAL_CONFIG_SOURCE]=true
			;;
			SOURCES_DIRECTORY)
				_globalSettings[USER_SET_SOURCES_DIRECTORY]=true
			;;
			SPECS_DIRECTORY)
				_globalSettings[USER_SET_SPECS_DIRECTORY]=true
			;;
			USE_TEMP_WORKSPACE)
				_globalSettings[USER_SET_USE_TEMP_WORKSPACE]=true
			;;
		esac
	done
}

# Report formatter for key-value printing
function __defineGlobalSettings__logDebugKV {
	logDebug "...$1 => $2"
}

# Set configuration rules (allowable configuration keys and their values)
_globalSettingsRules[BUILD_RPMS]='^(true|false)$'
_globalSettingsRules[BUILD_SRPMS]='^(true|false)$'
_globalSettingsRules[EXECUTABLE_SPECS]='^(true|false)$'
_globalSettingsRules[FLATTEN_RPMS_DIRECTORY]='^(true|false)$'
_globalSettingsRules[GLOBAL_CONFIG_SOURCE]='^.+$'
_globalSettingsRules[KEEP_FAILED_TEMP_WORKSPACE]='^(true|false)$'
_globalSettingsRules[OUTPUT_DEBUG]='^(true|false)$'
_globalSettingsRules[OUTPUT_VERBOSE]='^(true|false)$'
_globalSettingsRules[POSTBUILD_COMMAND]='^.+$'
_globalSettingsRules[POSTBUILD_ON_FAIL]='^(true|false)$'
_globalSettingsRules[POSTBUILD_ON_PARTIAL]='^(true|false)$'
_globalSettingsRules[PREBUILD_COMMAND]='^.+$'
_globalSettingsRules[PURGE_RPMS_ON_START]='^(true|false)$'
_globalSettingsRules[PURGE_SPECS_ON_START]='^(true|false)$'
_globalSettingsRules[PURGE_SRPMS_ON_START]='^(true|false)$'
_globalSettingsRules[PURGE_TEMP_WORKSPACES_ON_START]='^(true|false)$'
_globalSettingsRules[RPMBUILD_ARGS]='^[^;&]+$'
_globalSettingsRules[RPMS_DIRECTORY]='^.+$'
_globalSettingsRules[SOURCES_DIRECTORY]='^.+$'
_globalSettingsRules[SPECS_DIRECTORY]='^.+$'
_globalSettingsRules[SRPMS_DIRECTORY]='^.+$'
_globalSettingsRules[USE_TEMP_WORKSPACE]='^(true|false)$'
_globalSettingsRules[WORKSPACE]='^.+$'

# Define global configuration defaults (the map is declared by the parent)
_globalSettings[BUILD_RPMS]=true
_globalSettings[BUILD_SRPMS]=true
_globalSettings[EXECUTABLE_SPECS]=false
_globalSettings[FLATTEN_RPMS_DIRECTORY]=false
_globalSettings[GLOBAL_CONFIG_SOURCE]="${_myPWDir}/rpm-helpers.conf"
_globalSettings[KEEP_FAILED_TEMP_WORKSPACE]=true
_globalSettings[OUTPUT_DEBUG]=false
_globalSettings[OUTPUT_VERBOSE]=false
_globalSettings[POSTBUILD_COMMAND]=
_globalSettings[POSTBUILD_ON_FAIL]=false
_globalSettings[POSTBUILD_ON_PARTIAL]=false
_globalSettings[PREBUILD_COMMAND]=
_globalSettings[PURGE_RPMS_ON_START]=false
_globalSettings[PURGE_SPECS_ON_START]=false
_globalSettings[PURGE_SRPMS_ON_START]=false
_globalSettings[PURGE_TEMP_WORKSPACES_ON_START]=false
_globalSettings[RPMBUILD_ARGS]=
_globalSettings[RPMS_DIRECTORY]="${_myPWDir}/RPMS"
_globalSettings[SOURCES_DIRECTORY]="${_myPWDir}/SOURCES"
_globalSettings[SPECS_DIRECTORY]="${_myPWDir}/SPECS"
_globalSettings[SRPMS_DIRECTORY]="${_myPWDir}/SRPMS"
_globalSettings[USE_TEMP_WORKSPACE]=false
_globalSettings[WORKSPACE]="${_myPWDir}"

# Define other, internal global settings
_globalSettings[TEMP_WORKSPACE]=
_globalSettings[TEMP_WORKSPACE_MASK]=
_globalSettings[TEMP_WORKSPACE_PREFIX]=rpm-workspace-
_globalSettings[TEMP_WORKSPACE_SUFFIX]=.tmp
_globalSettings[USER_SET_GLOBAL_CONFIG_SOURCE]=false
_globalSettings[USER_SET_SOURCES_DIRECTORY]=false
_globalSettings[USER_SET_SPECS_DIRECTORY]=false
_globalSettings[USER_SET_USE_TEMP_WORKSPACE]=false

# Add some build host facts for later re-use
if ! hostOSDistribution=$(rpmspec --eval '%{dist}' 2>/dev/null); then
	hostOSDistribution=$(rpm --eval '%{dist}' 2>/dev/null)
fi
_globalSettings[BUILD_HOST_CPU_ARCHITECTURE]=$(uname -m)
_globalSettings[BUILD_HOST_NAME]=$(hostname -f)
_globalSettings[BUILD_HOST_OS_DISTRIBUTION]="${hostOSDistribution:1}"
_globalSettings[BUILD_HOST_USER_NAME]=$(whoami)

# Import permissible environment variables
declare -A envVarSettings
logVerbose "Processing environment variables..."
if ! source "${_myLibDir}"/process-environment-variables.sh; then
	errorOut 3 "Unable to import the environment variable processing source."
fi
__defineGlobalSettings__applySettingsToGlobalConfig envVarSettings

# Process command-line arguments, which override environment variables by the
# same key.
declare -A cliSettings
logVerbose "Processing command-line arguments..."
if ! source "${_myLibDir}"/process-args.sh; then
	errorOut 3 "Unable to import the argument processing source."
fi
__defineGlobalSettings__applySettingsToGlobalConfig cliSettings

# Attempt to load the core configuration file(s).  These are for setting the
# overall behavior of the RPM build, not each RPM.
declare -A confFileSettings
logVerbose "Processing the global configuration file(s)..."
if ! source "${_myLibDir}"/process-core-config-file.sh; then
	errorOut 3 "Unable to import the core config processing source."
fi
__defineGlobalSettings__applySettingsToGlobalConfig confFileSettings

# Reapply CLI arguments to override config file settings, if any were set
__defineGlobalSettings__applySettingsToGlobalConfig cliSettings

# Update dynamic global variables
_globalSettings[TEMP_WORKSPACE]="${_globalSettings[WORKSPACE]}/${_globalSettings[TEMP_WORKSPACE_PREFIX]}$(date +'%Y-%m-%d-%H-%M-%S')-${$}-${RANDOM}${_globalSettings[TEMP_WORKSPACE_SUFFIX]}"
_globalSettings[TEMP_WORKSPACE_MASK]="${_globalSettings[TEMP_WORKSPACE_PREFIX]}*${_globalSettings[TEMP_WORKSPACE_SUFFIX]}"

# Interpolate all variables in the global configuration
for configKey in "${!_globalSettings[@]}"; do
	if ! _globalSettings[$configKey]=$(interpolateVariables "${_globalSettings[$configKey]}" _globalSettings)
	then
		errorOut 1 "Unable to interpolate all variables found in ${configKey}."
	fi
done

# Canonicalize paths in the global configuration; none can be blank or root
for configKey in RPMS_DIRECTORY SOURCES_DIRECTORY SPECS_DIRECTORY \
	SRPMS_DIRECTORY TEMP_WORKSPACE WORKSPACE
do
	userValue="${_globalSettings[$configKey]}"
	if [ -z "$userValue" ]; then
		errorOut 1 "${configKey} cannot be empty."
	else
		canonValue="$(realpath -m "$(interpolateVariables "$userValue")")"

		if [ -z "$canonValue" ]; then
			errorOut 1 "${configKey} cannot be empty."
		elif [ '/' == "$canonValue" ]; then
			errorOut 1 "${configKey} cannot be root."
		fi

		_globalSettings[$configKey]="$canonValue"
	fi
done

# DEBUG:  Report all gathered configuration values
logDebug "Accepted configuration values from all sources:"
printOrderedHash __defineGlobalSettings__logDebugKV _globalSettings

# Cleanup
unset envVarSettings cliSettings confFileSettings configKey userValue \
	canonValue hostOSDistribution \
	__defineGlobalSettings__applySettingsToGlobalConfig \
	__defineGlobalSettings__logDebugKV
