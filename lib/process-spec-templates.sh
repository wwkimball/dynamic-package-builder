################################################################################
# Extension library for ../build-rpm-specs.sh
################################################################################
# Extension libraries must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

# Import helper functions
if ! source "${_myFuncDir}"/parse-config-file.sh; then
	errorOut 3 "Unable to import the config file parser."
fi
if ! source "${_myFuncDir}"/print-ordered-hash.sh; then
	errorOut 3 "Unable to import the print-ordered-hash helper."
fi

function __processSpecTemplates__copyGlobalSettingsTo {
	local -n targetMap=${1:?"ERROR:  A target map must be passed as the first positional argument to ${FUNCNAME[0]}."}
	local configKey
	for configKey in "${!_globalSettings[@]}"; do
		targetMap[$configKey]="${_globalSettings[$configKey]}"
	done
}

function __processSpecTemplates__logDebugKV {
	logDebug "...$1 => $2"
}

# Load contrib functions
if ! source "${_myLibDir}"/load-contrib-functions.sh; then
	errorOut 3 "Unable to import the contrib function loader."
fi

# Enter the SPECS directory so that relative directory references resolve
pushd "${_globalSettings[SPECS_DIRECTORY]}" &>/dev/null

# Loop over all *.spec files
recursionLimit=${INCLUDE_RECURSION_LIMIT:-5}
while IFS= read -r -d '' specFile; do
	logDebug "Processing ${specFile}..."

	# Reset interminable recursion markers
	unset seenIncludes
	declare -A seenIncludes

	# Reset the config file map to just the global settings
	unset specConfigMap
	declare -A specConfigMap
	__processSpecTemplates__copyGlobalSettingsTo specConfigMap

	# Provide some important defaults
	specPathedName="${specFile%.*}"
	specConfigMap[PACKAGE_NAME]="${specPathedName##*/}"
	specConfigMap[PACKAGE_DIST]="${_globalSettings[BUILD_HOST_OS_DISTRIBUTION]}"
	specConfigMap[PACKAGE_ARCH]="${_globalSettings[BUILD_HOST_CPU_ARCHITECTURE]}"
	specConfigMap[PACKAGE_BUILDER]="${_globalSettings[BUILD_HOST_USER_NAME]}"
	specConfigMap[PACKAGE_BUILD_HOST]="${_globalSettings[BUILD_HOST_NAME]}"
	specConfigMap[PACKAGE_BUILT_TIME]="$(date +"%a %b %d %Y")"

	# Check for a matching *.conf file in the same directory
	specConfigFile="${specPathedName}.conf"
	if [ -e "$specConfigFile" ]; then
		# Ingest its contents into the specConfig hash
		if ! parseConfigFile "$specConfigFile" specConfigMap; then
			errorOut 20 "Unable to read from configuration file, ${specConfigFile}."
		fi
	fi

	# DEBUG:  Report all gathered configuration values
	logDebug "Accepted configuration values from all sources, including ${specConfigFile}:"
	printOrderedHash __processSpecTemplates__logDebugKV specConfigMap

	hadSubstitution=true		# Emulate a do...while loop construct
	while $hadSubstitution; do
		hadSubstitution=false	# Assume each will be the last loop

		# Parse the spec file until there are no remaining substitutions
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

				# Canonicalize the include file to better detect interminable
				# recursion cases.
				includeFile=$(realpath -m "$swapFile")
				if [[ -v seenIncludes[$includeFile] ]]; then
					((seenIncludes[$includeFile]++))
					if [ $recursionLimit -lt ${seenIncludes[$includeFile]} ]; then
						errorOut 22 "File inclusion cancelled due to more than ${recursionLimit} instances of, ${includeFile}, in ${specFile}.  Set INCLUDE_RECURSION_LIMIT higher if you believe this to be too sensitive." >&2
					fi
				else
					seenIncludes[$includeFile]=1
				fi

				if [ -f "$includeFile" ]; then
					logVerbose "Injecting file, ${includeFile}, into spec at ${specFile}:${specLineNo}"
					swapLine="${swapPre}$(cat "$includeFile")${swapPost}"
				else
					errorOut 23 "No such file, ${includeFile}, for ${specFile}:${specLineNo}."
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
unset contribSource contribDir funcFile recursionLimit specFile seenIncludes \
	specConfigMap specPathedName specConfigFile hadSubstitution specSwapFile \
	specLineNo specLine swapPre swapVar swapPost swapValue swapLine \
	swapDefault swapFile includeFile \
	__processSpecTemplates__copyGlobalSettingsTo \
	__processSpecTemplates__logDebugKV
