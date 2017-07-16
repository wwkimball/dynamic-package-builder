################################################################################
# Extension library for ../build-rpm-specs.sh
################################################################################
# Extension libraries must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

function printVersion {
	cat <<EOVER
${_myFileName} ${_myVersion}
Copyright (c) 2003-2017, William W. Kimball Jr. MBA MSIS
License:  ISC
EOVER
}

function printUsage {
	echo "${_myFileName} [OPTIONS] [-- RPMBUILD OPTIONS]"
}

function printHelp {
	cat <<EOHELP
Help yourself.

$(printVersion)

$(cat "${_myDir}"/LICENSE)
EOHELP
}

# Define global configuration defaults
_globalSettings[GLOBAL_CONFIG_SOURCE]=${GLOBAL_CONFIG_SOURCE:-"${_pwDir}/rpm-helpers.conf"}
_globalSettings[WORKSPACE]=${WORKSPACE:-$(pwd)}

# Process command-line arguments.  Allow environment variables to be used to set
# default values, but command-line arguments override them.  Any positional
# arguments are saved to _positionalArgs.
hasCommandLineErrors=false
while [ $# -gt 0 ]; do
	case $1 in
		# Help requests
		-h|--help)
			printHelp
			exit 0
		;;

		# Version query
		-v|--version)
			printVersion
			exit 0
		;;

		# Set the core configuration source
		-s|--settings)
			if [ -z "$2" ]; then
				echo "ERROR:  -s|--settings requires a value." >&2
				hasCommandLineErrors=true
			else
				_globalSettings[GLOBAL_CONFIG_SOURCE]="$2"
				shift
			fi
			shift
		;;
		--settings=*)
			_globalSettings[GLOBAL_CONFIG_SOURCE]="${1#*=}"
			shift
		;;

		# Set the RPM spec source
		-r|--rpmspecs)
			if [ -z "$2" ]; then
				echo "ERROR:  -r|--rpmspecs requires a value." >&2
				hasCommandLineErrors=true
			else
				_globalSettings[RPM_SPECS_SOURCE]="$2"
				shift
			fi
			shift
		;;
		--rpmspecs=*)
			_globalSettings[RPM_SPECS_SOURCE]="${1#*=}"
			shift
		;;

		# Set the working directory
		-w|--workspace)
			if [ -z "$2" ]; then
				echo "ERROR:  -w|--workspace requires a value." >&2
				hasCommandLineErrors=true
			else
				_globalSettings[WORKSPACE]="$2"
				shift
			fi
			shift
		;;
		--workspace=*)
			_globalSettings[WORKSPACE]="${1#*=}"
			shift
		;;

		# Explicit start of positional arguments
		--)
			shift
			break;
		;;

		# Unknown arguments
		-*)
			echo "ERROR:  Unknown option, $1." >&2
			hasCommandLineErrors=true
			shift
		;;

		# Implied start of positional arguments
		*)
			break;
		;;
	esac
done

# Don't process any further with fatal command input errors
if $hasCommandLineErrors; then
	exit 1
fi

# Copy any remaining arguments as pass-through aguments for rpmbuild.
_globalSettings[RPMBUILD_ARGS]="$*"

# Cleanup
unset printVersion printUsage printHelp \
	hasCommandLineErrors cliArguments argumentCount
