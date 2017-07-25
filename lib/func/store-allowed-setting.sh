################################################################################
# Defines a function, storeAllowedSetting, which provides a generic means to
# store a value to an associative array with optiona constraints on the
# permissible values for each key.
################################################################################
# Functions must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

function storeAllowedSetting {
	local configKey="$1"
	local configValue="$2"
	local -n __configMap __valueRules
	local regexTest forceAdd=false

	# Bail out when the user fails to supply a config map.
	if [ $# -lt 3 ]; then
		logWarning "No __configMap passed to ${FUNCNAME[0]} for [$configKey]"
		return 1
	fi
	__configMap=$3

	# Allow all when only a config map is available
	if [ $# -gt 3 ]; then
		__valueRules=$4
		if [[ ! -v __valueRules[@] ]]; then
			# There are no value rules
			forceAdd=true
		fi
	else
		forceAdd=true
	fi
	if $forceAdd; then
		__configMap[$configKey]="$configValue"
		return 0
	fi

	# Check whether the value is permissible
	if [[ -v __valueRules[$configKey] ]]; then
		# Empty rules allow everything
		regexTest="${__valueRules[$configKey]}"
		if [ -z "$regexTest" ]; then
			regexTest='^.*$'
		fi

		if [[ $configValue =~ $regexTest ]]; then
			__configMap[$configKey]="$configValue"
		else
			# Unacceptable value
			return 3
		fi
	else
		# Unacceptable key
		return 2
	fi
}
