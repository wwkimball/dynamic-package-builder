################################################################################
# Extension library for ../build-rpm-specs.sh
################################################################################
# Extension libraries must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

# Expand certain variables in the path
workspaceDir=${_globalSettings[WORKSPACE]}
if [[ $workspaceDir =~ ^(~|\$HOME|\$\{HOME\})(.*)$ ]]; then
	workspaceDir="${HOME}/${BASH_REMATCH[2]}"
fi
_globalSettings[WORKSPACE]="$workspaceDir"

# Build the mandatory RPM workspace directory tree
logDebug "Ensuring the required RPM building subdirectories exist at ${_globalSettings[WORKSPACE]}."
if ! mkdir -p "${_globalSettings[WORKSPACE]}"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}; then
	errorOut 4 "Unable to create RPM building workspace at ${_globalSettings[WORKSPACE]}."
fi

# Optionally destroy all *.spec files in the RPM specs directory, presumably
# because they are to be dynamically reconstructed.

# Optionally run executables found in the RPM specs directory to potentially
# create more specs files.

# Cleanup
#unset configSource configFile hasConfigError configKey parseConfigFile
