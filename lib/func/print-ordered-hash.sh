################################################################################
# Defines a function, printOrderedHash, which provides a generic means to
# print all elements of an associative array, sorted by key.
################################################################################
# Functions must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

function printOrderedHash {
	local printFunction=${1?"ERROR:  The name of a function to call with key-value pairs must be provided as the first positional argument to ${FUNCNAME[0]}."}
	local -n printHash=${2?"ERROR:  The name of an associative array must be passed as the second positional argument to ${FUNCNAME[0]}."}
	local hashKeys=("${!printHash[@]}")
	local plainKeys="${hashKeys[*]}"
	local sortedKeys=$(echo "${plainKeys// /$'\n'}" | sort)
	local hashKey

	while read -r hashKey; do
		$printFunction "$hashKey" "${printHash[$hashKey]}"
	done <<<"$sortedKeys"
}
