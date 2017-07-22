################################################################################
# Extension library for ../build-rpm-specs.sh
################################################################################
# Extension libraries must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

# Import helper functions
if ! source "${_funcDir}"/store-allowed-setting.sh; then
	errorOut 3 "Unable to import the store-allowed-setting helper."
fi
if ! source "${_funcDir}"/trims.sh; then
	errorOut 3 "Unable to import the trims helper."
fi

function processEnvVars__tryStoreAllowedSetting {
	local configKey=${1:?"ERROR:  A configuration key must be specified as the first positional argument to ${BASH_FUNC[0]}."}
	local configValue=$(alltrim "$2")
	local storeResult

	# Bail out when the user fails to supply a config map.
	if [ $# -lt 3 ]; then
		errorOut 42 "Bug!  No configMap passed to ${BASH_FUNC[0]} for ${configKey} from the command-line."
		return 1
	fi

	storeAllowedSetting "$configKey" "$configValue" $3 $4
	storeResult=$?

	case $storeResult in
		0)	# Successful storage
			logDebug "Accepted configuration from matching environment variable:  ${configKey} = ${configValue}"
		;;

		1)	# No configMap
			errorOut 42 "Bug!  The configuration map could not be dereferenced in ${BASH_FUNC[0]}."
		;;

		2)	# Unacceptable configKey
			errorOut 1 "Unacceptable configuration key from the environment:  ${configKey}"
		;;

		3)	# Unacceptable configValue
			errorOut 1 "Unacceptable configuration value for environment variable ${configKey}:  ${configValue}"
		;;

		*)	# Unknown result
			errorOut 42 "Bug!  Indeterminate error encountered while attempting to store configuration from environment variables:  ${configKey} = ${configValue}"
		;;
	esac

	return $storeResult
}

# Process expected environment variables.
hasEnvVarErrors=false
for configKey in "${!_globalSettingsRules[@]}"; do
	configValue="${!configKey}"
	if [ ! -z "$configValue" ]; then
		if ! processEnvVars__tryStoreAllowedSetting \
			"$configKey" "$configValue" envVarSettings _globalSettingsRules
		then
			hasEnvVarErrors=true
		fi
	fi
done

# Don't process any further with fatal input errors
if $hasEnvVarErrors; then
	exit 1
fi

# Cleanup
unset hasEnvVarErrors configValue processEnvVars__tryStoreAllowedSetting
