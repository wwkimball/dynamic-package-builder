################################################################################
# Defines a function, parseConfigFile, which provides configuration file parsing
# capabilities.  The results are stored into an associative array as a key-value
# data store.  The function caller declares and identifies the associative array
# and passes the configuration file path.  The configuration file defines keys,
# values, and comments as follows:
# 1. Whitespace before the key, on either side of the assignment operator,
#    after the value, and on otherwise empty lines is ignored.
# 2. Keys and values may be separated by either = or : assignment operators.
#    So, these lines are equivalent:
#    KEY = VALUE
#    KEY: VALUE
# 3. Values may be bare (non-demarcated) or demarcated with either ' or "
#    symbols, however comments may be added only after demarcated values lest #
#    would otherwise never be allowed as part of a value.
# 4. Values may be dedented or non-dedented HEREDOCs.  A non-dedented HEREDOC is
#    identified as all the content between <<HERETAG and HERETAG, where HERETAG
#    is any arbitrary sequence of capitalized letters and underscore characters.
#    A dedented HEREDOC is indicated by prefixing the arbitrary HERETAG with a -
#    symbol.  Whereas a non-dedented HEREDOC value preserves all whitespace
#    between the HERETAGs, a dedented HEREDOC strips the leading whitespace from
#    every line, up to the number of whitespace characters present on the first
#    line, up to the first non-whitespace character.
# 5. Unterminated HEREDOCs will generate a fatal error.
# 6. Outside of HEREDOCs, # marks the start of a comment.  Entire lines may be
#    commented.  Comments may appear at the end of any line except when it is a
#    key=value line with no demarcation of the value.  HEREDOC values are
#    treated verbatim, so # is not ignored.  Examples:
#    KEY = VALUE   # THIS COMMENT BECOMES PART OF THE NON-DEMARCATED VALUE!
#    KEY = 'Value' # This comment is ignored
#    KEY = "Value" # This comment is also ignored
# 7. Outside of HEREDOCs, blank lines are ignored.  HEREDOC values are treated
#    verbatim, so blank lines become part of the value.
# 8. Values can be read from external files by using the form:
#    KEY = <@ /path/to/file-containing-the-value
# 9. Values can be read from executable statements by using the form:
#    KEY = <$ some-executable-command-sequence-that-writes-to-STDOUT
# 10. All key names are cast to upper-case, so the following are equivalent:
#    key = value
#    KEY = value
#    Key = value
# 11. Key names must begin with an alphabetic character but may otherwise
#    consist of any alphanumeric characters and the _ symbol.
################################################################################
# Functions must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

function parseConfigFile {
	local -n configMap=${1:?"ERROR:  An associative array variable name must be specified as the first positional arugment to ${BASH_FUNC[0]}."}
	local configFile=${2:?"ERROR:  A configuration file must be specified as the second positional argument to ${BASH_FUNC[0]}."}
	local configLine configKey configValue activeHereDocTag \
		dedentHereDocLength=-1 \
		dedentHereDoc=false \
		readingHereDoc=false \
		lineNumber=0 \
		hereDocStartLine=-1 \
		returnState=0

	# Do nothing when there is nothing to do
	if [ ! -f "$configFile" ]; then
		echo "ERROR:  Configuration file not found:  ${configFile}." >&2
		return 2
	fi

	while IFS= read -r configLine; do
		((lineNumber++))
		# Handle active HEREDOC reads
		if $readingHereDoc; then
			if [[ $configLine =~ ^[[:space:]]*${activeHereDocTag}[[:space:]]*$ ]]; then
				# Reached the end of the HEREDOC
				readingHereDoc=false
				dedentHereDoc=false
				dedentHereDocLength=-1
				hereDocStartLine=-1
				activeHereDocTag=
				configMap[$configKey]="${configValue:: -1}"
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
			fi

		# Ignore blank lines outside a HEREDOC
		elif [[ $configLine =~ ^[[:space:]]*$ ]]; then
			continue

		# Ignore full-comment lines outside a HEREDOC
		elif [[ $configLine =~ ^[[:space:]]*#.*$ ]]; then
			continue

		# HEREDOC, multi-line values, not dedented
		elif [[ $configLine =~ ^[[:space:]]*([A-Za-z][A-Za-z0-9_]*)[[:space:]]*[=:][[:space:]]*\<\<([A-Z_]+)$ ]]; then
			readingHereDoc=true
			dedentHereDoc=false
			hereDocStartLine=$lineNumber
			configKey=${BASH_REMATCH[1]^^}
			activeHereDocTag=${BASH_REMATCH[2]}
			configValue=

		# HEREDOC, multi-line values, dedented
		elif [[ $configLine =~ ^[[:space:]]*([A-Za-z][A-Za-z0-9_]*)[[:space:]]*[=:][[:space:]]*\<\<-([A-Z_]+)$ ]]; then
			readingHereDoc=true
			dedentHereDoc=true
			dedentHereDocLength=-1
			hereDocStartLine=$lineNumber
			configKey=${BASH_REMATCH[1]^^}
			activeHereDocTag=${BASH_REMATCH[2]}
			configValue=

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
					configMap[$configKey]="$configValue"
				fi
			else
				echo "WARNING:  No such file specified in ${configFile}:${lineNumber}:  ${readValueFromFile}." >&2
			fi

		# Values generated by executable commands (this is one of the primary
		# reasons that you're not allowed to run this as root).
		elif [[ $configLine =~ ^[[:space:]]*([A-Za-z][A-Za-z0-9_]*)[[:space:]]*[=:][[:space:]]*\<\$[[:space:]]*(.+)$ ]]; then
			configKey=${BASH_REMATCH[1]^^}
			configValue=$(eval ${BASH_REMATCH[2]})
			if [ 0 -ne $? ]; then
				echo "WARNING:  Command returned a non-zero result for key in ${configFile}:${lineNumber}:  ${configKey}." >&2
			else
				configMap[$configKey]="$configValue"
			fi

		# Permit comments on lines with demarcated values
		elif [[ $configLine =~ ^[[:space:]]*([A-Za-z][A-Za-z0-9_]*)[[:space:]]*[=:][[:space:]]*\"([^\"]+)\"[[:space:]]*(#.*)?$ ]] \
			|| [[ $configLine =~ ^[[:space:]]*([A-Za-z][A-Za-z0-9_]*)[[:space:]]*[=:][[:space:]]*\'([^\']+)\'[[:space:]]*(#.*)?$ ]]
		then
			configKey=${BASH_REMATCH[1]^^}
			configValue=${BASH_REMATCH[2]}
			configMap[$configKey]="$configValue"

		# Uncommented, bare lines; comments become value, so don't do this
		elif [[ $configLine =~ ^[[:space:]]*([A-Za-z][A-Za-z0-9_]*)[[:space:]]*[=:][[:space:]]*(.+)$ ]]; then
			configKey=${BASH_REMATCH[1]^^}
			configValue=${BASH_REMATCH[2]}
			configMap[$configKey]="$configValue"

		# Unrecognized line format
		else
			echo "WARNING:  Unrecognized line format in ${configFile}:${lineNumber}:  ${configLine}" >&2
		fi
	done <"$configFile"

	# Make sure HEREDOCs were properly terminated to avoid accidental exclusion
	# of other necessary settings.
	if $readingHereDoc; then
		echo "ERROR:  Unterminated HEREDOC in ${configFile}:${hereDocStartLine}:  ${activeHereDocTag}." >&2
		returnState=3
	fi

	return $returnState
}
