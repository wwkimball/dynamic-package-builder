################################################################################
# Defines a function, interpolateVariables, which provides a generic means to
# replace all variables with their respective values within a string.
################################################################################
# Functions must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

function __interpolateVariables__copyHashTo {
	declare -n sourceMap=${1:?"ERROR:  A source map must be passed as the first positional argument to ${FUNCNAME[0]}."}
	declare -n targetMap=${2:?"ERROR:  A target map must be passed as the second positional argument to ${FUNCNAME[0]}."}
	for configKey in "${!sourceMap[@]}"; do
		targetMap[$configKey]="${sourceMap[$configKey]}"
	done
}

function interpolateVariables {
	local templateString="$1"
	local recursionLimit=${INTERPOLATION_RECURSION_LIMIT:-5}
	local fullTemplate fullVariable variableName replaceValue hasVarMap=false
	local -A variableMap
	local -A variablesSeen

	# No nulls
	if [ -z "$templateString" ]; then
		return 0;
	fi

	# Accept any number of variable maps; combine them into one for lookups
	shift
	while [ $# -gt 0 ]; do
		__interpolateVariables__copyHashTo $1 variableMap
		hasVarMap=true
		shift
	done

	#while [[ $templateString =~ ^.*(\$\{?([A-Za-z0-9_]+)\}?).*$ ]]; do
	while [[ $templateString =~ ^.*(\$\{:([A-Za-z0-9_]+)\}).*$ ]]; do
		fullTemplate=${BASH_REMATCH[0]}
		fullVariable=${BASH_REMATCH[1]}
		variableName=${BASH_REMATCH[2]}
		replaceValue="${!variableName}"

		# Matches in the external variable map override environment variables
		if $hasVarMap && [[ -v variableMap[$variableName] ]]; then
			replaceValue="${variableMap[$variableName]}"
		fi

		# Protect against interminable substitution loops caused when
		# VAR=$VAR
		# VAR1=$VAR2; VAR2=$VAR1
		# VAR1=$VAR2; VAR2=$VAR3; VAR3=$VAR1
		if [[ -v variablesSeen[$variableName] ]]; then
			((variablesSeen[$variableName]++))
			if [ $recursionLimit -lt ${variablesSeen[$variableName]} ]; then
				echo "WARNING:  String interpolation cancelled due to more than ${recursionLimit} replacements for variable, ${variableName}, in ${templateString}.  Set INTERPOLATION_RECURSION_LIMIT higher if you believe this to be too sensitive." >&2
				return 1
			fi
		else
			variablesSeen[$variableName]=1
		fi

		# Report empty values
		if [ -z "$replaceValue" ]; then
			echo "WARNING:  No substitution value available for variable, ${fullVariable}." >&2
		fi

		templateString=${fullTemplate//${fullVariable}/${replaceValue}}
	done

	# Treat a leading ~ as a variable
	if [[ $templateString =~ ^~(.*)$ ]]; then
		templateString="${HOME}/${BASH_REMATCH[1]}"
	fi

	echo "$templateString"
}
