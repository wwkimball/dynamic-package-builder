################################################################################
# Function for ../../build-rpm-specs.sh
################################################################################
# Functions must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

# Define functions only once
if type parseConfigFile &>/dev/null; then
	exit 0
fi

function parseConfigFile {
	local configFile=$1
	local configLine configKey configValue activeHereDocTag \
		dedentHereDocLength=-1 \
		dedentHereDoc=false \
		readingHereDoc=false \
		returnState=0

	# Do nothing when there is nothing to do
	if [ -z "$configFile" ]; then
		return 1
	fi

	while IFS= read -r configLine; do
		# Handle active HEREDOC reads
		if $readingHereDoc; then
			if [[ $configLine =~ ^[[:space:]]*${activeHereDocTag}[[:space:]]*$ ]]; then
				# Reached the end of the HEREDOC
				readingHereDoc=false
				dedentHereDoc=false
				dedentHereDocLength=-1
				activeHereDocTag=
				_configMap[$configKey]="${configValue:: -1}"
				#echo "!! C:${configKey}->${configValue}"
			else
				# Concatenate the line to the active HEREDOC
				if $dedentHereDoc; then
					if [ $dedentHereDocLength -gt -1 ]; then
						# Dedent the line
						configValue+="${configLine:${dedentHereDocLength}}"$'\n'
					else
						# First line, find the dedent length
						if [[ $configLine =~ ^([[:space:]]*)([^[:space:]]+.*)$ ]]; then
							dedentHereDocLength=${#BASH_REMATCH[1]}
							configValue+="${BASH_REMATCH[2]}"$'\n'
						else
							dedentHereDocLength=0
							configValue+="${configLine}"$'\n'
						fi
					fi
				else
					configValue+="${configLine}"$'\n'
				fi
				#echo "!! HEREDOC adding ${configLine}"
			fi

		# Ignore blank lines outside a HEREDOC
		elif [[ $configLine =~ ^[[:space:]]*$ ]]; then
			#echo "!! ignoring blank line outside HEREDOC"
			continue

		# Ignore full-comment lines outside a HEREDOC
		elif [[ $configLine =~ ^[[:space:]]*#.*$ ]]; then
			#echo "!! ignoring full-comment line outside HEREDOC"
			continue

		# HEREDOC, multi-line values, not dedented
		elif [[ $configLine =~ ^[[:space:]]*([A-Za-z][A-Za-z0-9_]*)[[:space:]]*[=:][[:space:]]*\<\<([A-Z_]+)$ ]]; then
			readingHereDoc=true
			dedentHereDoc=false
			configKey=${BASH_REMATCH[1]^^}
			activeHereDocTag=${BASH_REMATCH[2]}
			configValue=
			#echo "!! Non-dedented HEREDOC start:  ${activeHereDocTag}."

		# HEREDOC, multi-line values, dedented
		elif [[ $configLine =~ ^[[:space:]]*([A-Za-z][A-Za-z0-9_]*)[[:space:]]*[=:][[:space:]]*\<\<-([A-Z_]+)$ ]]; then
			readingHereDoc=true
			dedentHereDoc=true
			dedentHereDocLength=-1
			configKey=${BASH_REMATCH[1]^^}
			activeHereDocTag=${BASH_REMATCH[2]}
			configValue=
			#echo "!! Dedented HEREDOC start:  ${activeHereDocTag}."

		# Permit file input for values
		elif [[ $configLine =~ ^[[:space:]]*([A-Za-z][A-Za-z0-9_]*)[[:space:]]*[=:][[:space:]]*\<@[[:space:]]*(.+)$ ]]; then
			configKey=${BASH_REMATCH[1]^^}
			readValueFromFile=${BASH_REMATCH[2]}

			# Expand certain variables in the path
			if [[ $readValueFromFile =~ ^(~|\$HOME|\$\{HOME\})(.+)$ ]]; then
				readValueFromFile="${HOME}/${BASH_REMATCH[2]}"
			fi

			if [ -f "$readValueFromFile" ]; then
				configValue=$(cat "$readValueFromFile")
				if [ ! -z "$configValue" ]; then
					_configMap[$configKey]="$configValue"
					#echo "!! F:${configKey}->${configValue}"
				fi
			else
				echo "WARNING:  No such file, ${readValueFromFile}." >&2
			fi

		# Values generatd by executable commands (this is one of the primary
		# reasons that you're not allowed to run this as root).
		elif [[ $configLine =~ ^[[:space:]]*([A-Za-z][A-Za-z0-9_]*)[[:space:]]*[=:][[:space:]]*\<\$[[:space:]]*(.+)$ ]]; then
			configKey=${BASH_REMATCH[1]^^}
			configValue=$(eval ${BASH_REMATCH[2]})
			if [ 0 -ne $? ]; then
				echo "WARNING:  Command returned a non-zero result for key, ${configKey}." >&2
			else
				_configMap[$configKey]="$configValue"
			fi

		# Permit comments on lines with demarcated values
		elif [[ $configLine =~ ^[[:space:]]*([A-Za-z][A-Za-z0-9_]*)[[:space:]]*[=:][[:space:]]*\"([^\"]+)\"[[:space:]]*(#.*)?$ ]] \
			|| [[ $configLine =~ ^[[:space:]]*([A-Za-z][A-Za-z0-9_]*)[[:space:]]*[=:][[:space:]]*\'([^\']+)\'[[:space:]]*(#.*)?$ ]]
		then
			configKey=${BASH_REMATCH[1]^^}
			configValue=${BASH_REMATCH[2]}
			_configMap[$configKey]="$configValue"
			#echo "!! A:${configKey}->${configValue}"

		# Uncommented, bare lines; comments become value, so don't do this
		elif [[ $configLine =~ ^[[:space:]]*([A-Za-z][A-Za-z0-9_]*)[[:space:]]*[=:][[:space:]]*(.+)$ ]]; then
			configKey=${BASH_REMATCH[1]^^}
			configValue=${BASH_REMATCH[2]}
			_configMap[$configKey]="$configValue"
			#echo "!! B:${configKey}->${configValue}"

		# Unrecognized line format
		else
			echo "WARNING:  Unable to accept configuration line in ${configFile}:  ${configLine}" >&2
		fi
	done <"$configFile"

	# Make sure HEREDOCs were properly terminated to avoid accidental exclusion
	# of other necessary settings.
	if $readingHereDoc; then
		echo "ERROR:  Unterminated HEREDOC, ${activeHereDocTag}." >&2
		returnState=3
	fi

	return $returnState
}
