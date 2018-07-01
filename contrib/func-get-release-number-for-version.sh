################################################################################
# Defines a function, getReleaseNumberForVersion, which provides logic that can
# generate the next appropriate release number for a given package version.
# This function tracks release numbers within a structured data file that is
# saved to a given directory.  The directory is subdivided by given package
# architecture and operating system.
#
# Copyright 2001, 2018 William W. Kimball, Jr. MBA MSIS
################################################################################
# Functions must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

function getReleaseNumberForVersion {
	local packageName=${1:?"ERROR:  A package name must be provided as the first positional argument to ${FUNCNAME[0]}."}
	local packageVersion=${2:?"ERROR:  A package version must be provided as the second positional argument to ${FUNCNAME[0]}."}
	local packageArchitecture=${3:?"ERROR:  A package architecture must be provided as the third positional argument to ${FUNCNAME[0]}."}
	local packageOS=${4:?"ERROR:  A package operating system tag must be provided as the fourth positional argument to ${FUNCNAME[0]}."}
	local baseDataDirectory=${5:?"ERROR:  A base directory where package release numbers can be permanently tracked must be provided as the fifth positional argument to ${FUNCNAME[0]}."}
	local releaseNumber=${6:-1}
	local dataFileDir="${baseDataDirectory}/${packageOS}/${packageArchitecture}"
	local dataFileBaseName="${dataFileDir}/${packageName}"
	local dataFile="${dataFileBaseName}.tab"
	local swapFile="${dataFileBaseName}.swap"
	local versionRecord recVersion recCreated recModified rowCount

	# Check that the data directory can be utilized
	if [ ! -d "$dataFileDir" ]; then
		if ! mkdir -p "$dataFileDir"; then
			errorOut 70 "Unable to create data storage directory, ${dataFileDir}"
		fi
	fi

	if [ -f "$dataFile" ]; then
		versionRecord=$(grep "^${packageVersion}"$'\t' "${dataFile}")
		if [ 0 -eq $? ]; then
			IFS=$'\t' read -r recVersion releaseNumber recCreated recModified <<<"$versionRecord"
			((releaseNumber++))

			if ! echo -e "${recVersion}\t${releaseNumber}\t${recCreated}\t$(date)" >"$swapFile"
			then
				errorOut 71 "Unable to save incremented release number to swap file, ${swapFile}."
			fi

			# Don't bother copying zero rows
			rowCount=$(wc -l ${dataFile} | cut -d' ' -f1)
			if [ 1 -lt $rowCount ]; then
				if ! grep -v "^${recVersion}"$'\t' "$dataFile" >>"$swapFile"; then
					errorOut 72 "Unable to copy other release records to swap file, ${swapFile}."
				fi
			fi
		else
			if ! echo -e "${packageVersion}\t${releaseNumber}\t$(date)\t$(date)" >"$swapFile"
			then
				errorOut 73 "Unable to add a new version record to swap file, ${swapFile}."
			fi

			if ! cat "$dataFile" >>"$swapFile"; then
				errorOut 74 "Unable to transfer previous records from ${dataFile} to a swap file, ${swapFile}."
			fi
		fi

		if ! rm -f "$dataFile"; then
			errorOut 75 "Unable to remove old data file, ${dataFile}."
		fi
		if ! mv "$swapFile" "$dataFile"; then
			errorOut 76 "Unable to save updated data file, ${swapFile}, to ${dataFile}."
		fi
	else
		if ! echo -e "${packageVersion}\t${releaseNumber}\t$(date)\t$(date)" >"$dataFile"; then
			errorOut 77 "Unable to create original data file, ${dataFile}."
		fi
	fi

	echo "$releaseNumber"
}
