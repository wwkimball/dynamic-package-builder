################################################################################
# Extension library for ../build-rpm-specs.sh
################################################################################
# Attempt to source the output logger functions
if ! source "${_myLibDir}"/set-logger.sh; then
	echo "ERROR:  Unable to import the logger source." >&2
	exit 3
fi

# Import all functions from this project, then the pwd, then the SPECS contrib
# directories.
for contribSource in "${_myDir}" . "${_globalSettings[SPECS_DIRECTORY]}"; do
	contribDir="${contribSource}/contrib"
	logDebug "Searching for contributed functions in directory:  ${contribDir}"
	if [ -d "$contribDir" ]; then
		while IFS= read -r -d '' funcFile; do
			logDebug "Loading contributed function from source file:  ${funcFile}"
			if ! source "$funcFile"; then
				logWarning "Unable to source contributed function from source file:  ${funcFile}"
			fi
		done < <(find "${contribDir}" -maxdepth 1 -type f -iname 'func-*.sh' -print0)
	fi
done

# Cleanup
unset contribSource contribDir funcFile
