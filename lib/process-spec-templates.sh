################################################################################
# Extension library for ../build-rpm-specs.sh
################################################################################
# Extension libraries must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

# Import helper functions
if ! source "${_funcDir}"/parse-config-file.sh; then
	errorOut 3 "Unable to import the config file parser."
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

function copyGlobalSettingsTo {
	declare -n targetMap=${1:?"ERROR:  A target map must be passed as the first positional argument to ${FUNCNAME[0]}."}
	for configKey in "${!_globalSettings[@]}"; do
		targetMap[$configKey]="${_globalSettings[$configKey]}"
	done
}

# Enter the SPECS directory so that relative directory references resolve
pushd "${_globalSettings[SPECS_DIRECTORY]}" &>/dev/null

# Gather some facts
packageArchitecture="$(uname -m)"
packageBuilder="$(whoami)"
if ! packageDistribution=$(rpmspec --eval '%{dist}' 2>/dev/null); then
	packageDistribution=$(rpm --eval '%{dist}' 2>/dev/null)
fi

# Loop over all *.spec files
while IFS= read -r -d '' specFile; do
	logDebug "Processing ${specFile}..."

	# Reset the config file map to just the global settings
	unset specConfigMap
	declare -A specConfigMap
	copyGlobalSettingsTo specConfigMap

	# Provide some important defaults
	specPathedName="${specFile%.*}"
	specConfigMap[PACKAGE_NAME]="${specPathedName##*/}"
	specConfigMap[PACKAGE_DIST]="${packageDistribution:1}"
	specConfigMap[PACKAGE_ARCH]="$packageArchitecture"
	specConfigMap[PACKAGE_BUILDER]="$packageBuilder"
	specConfigMap[PACKAGE_BUILT_TIME]="$(date +"%a %b %d %Y")"

	# Check for a matching *.conf file in the same directory
	specConfigFile="${specPathedName}.conf"
	if [ -e "$specConfigFile" ]; then
		# Ingest its contents into the specConfig hash
		if ! parseConfigFile "$specConfigFile" specConfigMap; then
			errorOut 20 "Unable to read from configuration file, ${configFile}."
		fi
	fi

	hadSubstitution=true
	while $hadSubstitution; do
		hadSubstitution=false	# Assume each will be the last loop

		# Parse the spec file until there are no remaining substitutions
		# TODO:  Protect against interminable recursion
		specSwapFile="${specPathedName}.swap"
		if ! echo -n >"$specSwapFile"; then
			errorOut 21 "Unable to create swap file, ${specSwapFile}"
		fi

		specLineNo=0
		while IFS= read -r specLine; do
			((specLineNo++))
			if [[ $specLine =~ ^(.*)\$\{:([A-Za-z0-9_]+)\}(.*)$ ]]; then
				hadSubstitution=true
				swapPre=${BASH_REMATCH[1]}
				swapVar=${BASH_REMATCH[2]}
				swapPost=${BASH_REMATCH[3]}
				swapValue=${specConfigMap[${swapVar}]}
				swapLine="${swapPre}${swapValue}${swapPost}"

				if [ -z "$swapValue" ]; then
					logWarning "Empty value for variable, ${swapVar}, at ${specFile}:${specLineNo}"
				fi
			elif [[ $specLine =~ ^(.*)\$\{:([A-Za-z0-9_]+):[=-]([^}]*)\}(.*)$ ]]
			then
				hadSubstitution=true
				swapPre=${BASH_REMATCH[1]}
				swapVar=${BASH_REMATCH[2]}
				swapDefault=${BASH_REMATCH[3]}
				swapPost=${BASH_REMATCH[4]}
				if [[ -v specConfigMap[$swapVar] ]]; then
					swapValue=${specConfigMap[$swapVar]}
				else
					swapValue="$swapDefault"
				fi
				swapLine="${swapPre}${swapValue}${swapPost}"

				if [ -z "$swapValue" ]; then
					logWarning "Empty value for variable, ${swapVar}, at ${specFile}:${specLineNo}"
				fi
			else
				swapLine="$specLine"
			fi

			# Check the post-interpolation result for file concatenations
			if [[ $swapLine =~ ^(.*)\$\{@([^}]+)\}(.*)$ ]]; then
				hadSubstitution=true
				swapPre=${BASH_REMATCH[1]}
				swapFile=${BASH_REMATCH[2]}
				swapPost=${BASH_REMATCH[3]}

				if [ -f "$swapFile" ]; then
					logVerbose "Injecting file, ${swapFile}, into spec at ${specFile}:${specLineNo}"
					swapLine="${swapPre}$(cat "$swapFile")${swapPost}"
				else
					errorOut 23 "No such file, ${swapFile}, for ${specFile}:${specLineNo}."
					swapLine="${swapPre}${swapPost}"
				fi
			fi

			echo "$swapLine">>"$specSwapFile"
		done <"$specFile"

		if ! rm -f "$specFile" || ! mv "$specSwapFile" "$specFile"; then
			errorOut 22 "Unable to swap ${specSwapFile} to ${specFile}."
		fi
	done

	logVerbose "$(cat <<EOCAT
Finished processing RPM specification file, ${specFile}:
$(cat ${specFile})
EOCAT
)"
done < <(find "${_globalSettings[SPECS_DIRECTORY]}" -maxdepth 1 -type f -name '*.spec' -print0)

popd &>/dev/null

# Cleanup
unset packageArchitecture packageBuilder packageDistribution
