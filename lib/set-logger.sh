################################################################################
# Extension library for ../build-rpm-specs.sh
################################################################################
# Extension libraries must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

# Define color codes
_colRed='\033[0;31m'
_colYellow='\033[0;33m'
_colGreen='\033[0;32m'
_colBlue='\033[0;34m'
_colPurple='\033[0;35m'
_colTeal='\033[0;36m'
_colGray='\033[0;37m'
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
	echo -e "$(_echoInColor $_colRed 'ERROR: ')"
}

###
# Prints a colored WARNING prefix.
##
function _echoPrefixWarning {
	echo -e "$(_echoInColor $_colYellow 'WARNING: ')"
}

###
# Prints a colored INFO prefix.
##
function _echoPrefixInfo {
	echo -e "$(_echoInColor $_colGreen 'INFO: ')"
}

###
# Prints a colored DEBUG prefix.
##
function _echoPrefixDebug {
	echo -e "$(_echoInColor $_colGray 'DEBUG: ')"
}

###
# Prints an ERROR message
##
function logError {
	echo -e "$(_echoPrefixError) $@"
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
# Prints an DEBUG message
##
function logDebug {
	echo -e "$(_echoPrefixDebug) $@"
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
