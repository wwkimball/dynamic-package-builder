################################################################################
# Defines a function, updateRepositoryMetadata, which provides logic that can
# generate or update RPM/yum repository metadata.
#
# Copyright 2001, 2018 William W. Kimball, Jr. MBA MSIS
################################################################################
# Functions must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

function updateRepositoryMetadata {
	local repositoryDir=${1:?"ERROR:  The path to the top directory of an RPM repository must be provided as the first positional argument to ${FUNCNAME[0]}."}
	mkdir -p "$repositoryDir"

	# Update the repository metadata.  Try with SQLite, then without on failure.
	if [ -d "$repositoryDir"/repodata ]; then
		logInfo "Updating repository metadata for ${repositoryDir}."
		if ! createrepo --database --update "$repositoryDir" 2>/dev/null; then
			rm -rf "$repositoryDir"/.repodata
			createrepo --no-database --update "$repositoryDir"
		fi
	else
		logInfo "Creating new repository metadata for ${repositoryDir}."
		if ! createrepo --database "$repositoryDir" 2>/dev/null; then
			rm -rf "$repositoryDir"/{.repodata,repodata}
			createrepo --no-database "$repositoryDir"
		fi
	fi
}
