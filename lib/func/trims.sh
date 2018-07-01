################################################################################
# Defines a set of functions that trim whitespace characters from the left,
# right, or both ends of a string.
#
# Copyright 2001, 2018 William W. Kimball, Jr. MBA MSIS
################################################################################
# Functions must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

function ltrim {
	local trimVal=$1
	if [ -z "$trimVal" ]; then
		return 0
	fi
	echo "${trimVal#"${trimVal%%[![:space:]]*}"}"
}

function rtrim {
	local trimVal=$1
	if [ -z "$trimVal" ]; then
		return 0
	fi
	echo "${trimVal%"${trimVal##*[![:space:]]}"}"
}

function alltrim {
	echo "$(rtrim "$(ltrim "$1")")"
}
