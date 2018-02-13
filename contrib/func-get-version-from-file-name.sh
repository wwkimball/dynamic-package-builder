################################################################################
# Defines a function, getVersionFromFileName, which provides logic that can
# identify the version of a product from its file-name, provided the version
# number appears in the file-name in a reliable, identifiable way.
################################################################################
# Functions must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

function getVersionFromFileName {
	local fileSpec fileName versionNumber
	fileSpec=${1:?"ERROR:  A file-name must be provided as the first positional argument to ${FUNCNAME[0]}."}
	fileName=${fileSpec##*/}

	# Strip off any RPM-style Release Tag
	if [[ $fileName =~ ^(.*[[:digit:]]+(\.[[:digit:]]+)*)-[[:digit:]].*$ ]]; then
		fileName=${BASH_REMATCH[1]}
	fi

	# Attempt to identify the version number
	versionNumber=
	if [[ $fileName =~ ^.+-([[:digit:]]+(\.[[:digit:]]+)*).*$ ]]; then
		versionNumber=${BASH_REMATCH[1]}
	elif [[ $fileName =~ ^.+[^[:digit:]\.]([[:digit:]]+(\.[[:digit:]]+)*).*$ ]]; then
		versionNumber=${BASH_REMATCH[1]}
	else
		errorOut 70 "A version number could not be found in file-name, ${fileName}."
	fi

	echo "$versionNumber"
}
