################################################################################
# Defines a function, publishViaCopy, which provides logic that can copy all
# generated RPMs to a package repository directory that is accessible to the
# local file-system.
#
# Copyright 2001, 2018 William W. Kimball, Jr. MBA MSIS
################################################################################
# Functions must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

# Attempt to source the output logger functions
if ! source "${_myLibDir}"/set-logger.sh; then
	echo "ERROR:  Unable to import the logger source." >&2
	exit 3
fi

function publishViaCopy {
	local repositoryBase=${1?"ERROR:  The top-most directory of a yum repository must be provided as the first positional argument to ${FUNCNAME[0]}."}
	local publishSubdir=${2?"ERROR:  A subdirectory relative to ${repositoryBase} must be provided as the second positional argument to ${FUNCNAME[0]}."}
	local copyTo=$(realpath -m "${repositoryBase}/${publishSubdir}")
	shift 2

	# At least one source path must be provided
	if [ 1 -gt $# ]; then
		logError "One or more source paths must be provided as additional arguments to ${FUNCNAME[0]}."
		return 1
	fi

	# If the target already exists, it must be a directory
	if [ -e "$copyTo" ]; then
		if [ ! -d "$copyTo" ]; then
			logError "Publishing target already exists and is not a directory:  ${copyTo}"
			return 2
		fi
	else
		if ! mkdir -p "$copyTo"; then
			logError "Unable to create target publishing directory:  ${copyTo}"
			return 3
		fi
	fi

	# Publish all RPM files from any remaining path arguments
	while [ 0 -lt $# ]; do
		if ! cp -f "$1"/*.rpm "$copyTo"/; then
			logError "Unable to copy RPM files from ${1} to ${copyTo}."
			break
		fi
		shift
	done

	updateRepositoryMetadata "$repositoryBase"
}
