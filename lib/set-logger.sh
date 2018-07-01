################################################################################
# Extension library for ../build-rpm-specs.sh
#
# Copyright 2001, 2018 William W. Kimball, Jr. MBA MSIS
################################################################################
# Extension libraries must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

# Define color codes
_colBlue='\033[0;34m'
_colDarkGray='\033[0;90m'
_colLightRed='\033[0;91m'
_colLightGreen='\033[0;92m'
_colLightYellow='\033[0;93m'
_colLightMagenta='\033[0;95m'
_colEnd='\033[00m'

###
# Echos a string in a color.
##
function _echoInColor {
	local echoColor echoMessage
	echoColor=$1
	shift
	echo -en "${echoColor}${@}${_colEnd}"
}

###
# Prints a colored ERROR prefix.
##
function _echoPrefixError {
	echo -e "$(_echoInColor $_colLightRed 'ERROR: ')"
}

###
# Prints a colored WARNING prefix.
##
function _echoPrefixWarning {
	echo -e "$(_echoInColor $_colLightYellow 'WARNING: ')"
}

###
# Prints a colored INFO prefix.
##
function _echoPrefixInfo {
	echo -e "$(_echoInColor $_colLightGreen 'INFO: ')"
}

###
# Prints a colored verbose INFO prefix.
##
function _echoPrefixVerbose {
	echo -e "$(_echoInColor $_colBlue 'INFO: ')"
}

###
# Prints a colored DEBUG prefix.
##
function _echoPrefixDebug {
	echo -e "$(_echoInColor $_colLightMagenta 'DEBUG: ')"
}

###
# Prints an ERROR message
##
function logError {
	echo -e "$(_echoPrefixError) $@" >&2
}

###
# Prints a WARNING message
##
function logWarning {
	echo -e "$(_echoPrefixWarning) $@"
}

###
# Prints an INFO message
##
function logInfo {
	echo -e "$(_echoPrefixInfo) $@"
}

###
# Prints a verbose-only INFO message
##
function logVerbose {
	if [[ -v _globalSettings[OUTPUT_VERBOSE] ]] \
		&& ${_globalSettings[OUTPUT_VERBOSE]}
	then
		echo -e "$(_echoPrefixVerbose) $@"
	fi
}

###
# Prints an DEBUG message
##
function logDebug {
	if [[ -v _globalSettings[OUTPUT_DEBUG] ]] \
		&& ${_globalSettings[OUTPUT_DEBUG]}
	then
		echo -e "$(_echoPrefixDebug) $@"
	fi
}

###
# Prints and ERROR message and abends the process with an exit code
##
function errorOut {
	local errorCode=${1:-1}
	shift
	logError $@
	exit $errorCode
}
