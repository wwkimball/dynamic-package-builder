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
	local fullTemplate fullVariable variableName replaceValue

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

		templateString=${fullTemplate//${fullVariable}/${replaceValue}}
	done

	# Treat a leading ~ as a variable
	if [[ $templateString =~ ^(~|\$HOME|\$\{HOME\})(.*)$ ]]; then
		templateString="${HOME}/${BASH_REMATCH[2]}"
	fi

	echo "$templateString"
}
