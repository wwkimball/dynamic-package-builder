################################################################################
# Defines a function, interpolateVariables, which provides a generic means to
# replace all variables with their respective values within a string.
################################################################################
# Functions must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

function interpolateVariables {
	local templateString=$1
	local recursionLimit=${2:-5}
	local fullTemplate fullVariable variableName replaceValue
	local -A variablesSeen

	# No nulls
	if [ -z "$templateString" ]; then
		return 0;
	fi

	while [[ $templateString =~ ^.*(\$\{?([A-Za-z0-9_]+)\}?).*$ ]]; do
		fullTemplate=${BASH_REMATCH[0]}
		fullVariable=${BASH_REMATCH[1]}
		variableName=${BASH_REMATCH[2]}
		replaceValue="${!variableName}"

		if [[ -v _globalSettings[$variableName] ]]; then
			replaceValue="${_globalSettings[$variableName]}"
		fi

		# Protect against interminable substitution loops caused when
		# VAR1=${VAR2} && VAR2=${VAR1}
		if [[ -v variablesSeen[$variableName ]]; then
			variablesSeen[$variableName]=1
		else
			((variablesSeen[$variableName]++))
			if [ $recursionLimit -lt ${variablesSeen[$variableName]} ]; then
				echo "WARNING:  String interpolation cancelled due to more than ${recursionLimit} recursions on variable, ${variableName}, in ${templateString}." >&2
				return 1
			fi
		fi

		templateString=${fullTemplate//${fullVariable}/${replaceValue}}
	done

	# Treat a leading ~ as a variable
	if [[ $templateString =~ ^~(.*)$ ]]; then
		templateString="${HOME}/${BASH_REMATCH[1]}"
	fi

	echo "$templateString"
}
