################################################################################
# Extension library for ../build-rpm-specs.sh
################################################################################
# Extension libraries must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

# Import all functions from the rpm-helpers project, then the pwd, then the
# SPECS contrib directories.
for contribSource in "${_myDir}" . "${_globalSettings[SPECS_DIRECTORY]}"; do
	contribDir="${contribSource}/contrib"
	if [ -d "$contribDir" ]; then
		while IFS= read -r -d '' funcFile; do
			if ! source "$funcFile"; then
				logWarning "Unable to source contributed function from source file:  ${funcFile}"
			fi
		done < <(find "${contribDir}" -maxdepth 1 -type f -iname 'func-*.sh' -print0)
	fi
done

# Cleanup
unset contribSource contribDir funcFile
