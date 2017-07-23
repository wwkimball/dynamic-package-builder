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

function copyGlobalSettingsTo {
	declare -n targetMap=${1:?"ERROR:  A target map must be passed as the first positional argument to ${BASH_FUNC[0]}."}
	for configKey in "${!_globalSettings[@]}"; do
		targetMap[$configKey]="${_globalSettings[$configKey]}"
	done
}

# ${:VAR_NAME} => from a varMap (which overrides globals).  External
#   configuration files for spec files are found by matching the spec filename
#   against a conf file by the same name in the same directory.
# ${:VAR_NAME:[-=]default} => Same as ${:VAR_NAME} except that 'default' becomes
#   the value when VAR_NAME results in a null value.
# ${@FILE_CONCAT} => Content is copied verbatim into the spec file.  These names
#   can be derived dynamically after the ${:} pass, so variable substitution is
#   performed again after the injection, which can result in more injections,
#   which will need more substitutions, and so on.

# TODO:  Also import helpful functions that most RPM specification templates
# would benefit from so their authors won't have to redefine such common code.

# Enter the SPECS directory so that relative directory references resolve
pushd "${_globalSettings[SPECS_DIRECTORY]}" &>/dev/null

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
	specConfigMap[PACKAGE_ARCH]="$(uname -m)"

	# Check for a matching *.conf file in the same directory
	specConfigFile="${specPathedName}.conf"
	if [ -e "$specConfigFile" ]; then
		# Ingest its contents to specConfig hash
		if ! parseConfigFile specConfigMap "$specConfigFile"; then
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

		while IFS= read -r specLine; do
			if [[ $specLine =~ ^(.*)\$\{:([A-Za-z0-9_]+)\}(.*)$ ]]; then
				hadSubstitution=true
				swapPre=${BASH_REMATCH[1]}
				swapVar=${BASH_REMATCH[2]}
				swapPost=${BASH_REMATCH[3]}
				swapLine="${swapPre}${specConfigMap[${swapVar}]}${swapPost}"
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
					swapLine="${swapPre}$(cat "$swapFile")${swapPost}"
				else
					logWarning "No such file, ${swapFile}, for ${specFile}."
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
