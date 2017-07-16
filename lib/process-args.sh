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
_globalSettings[USER_SET_GLOBAL_CONFIG_SOURCE]=false
_globalSettings[WORKSPACE]=${WORKSPACE:-$(pwd)}
_globalSettings[BUILD_WORKSPACE_TREE]=${BUILD_WORKSPACE_TREE:-true}

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
			_globalSettings[USER_SET_GLOBAL_CONFIG_SOURCE]=true
			if [ -z "$2" ]; then
				logError "-s|--settings requires a value." >&2
				hasCommandLineErrors=true
			else
				_globalSettings[GLOBAL_CONFIG_SOURCE]="$2"
				shift
			fi
		;;
		--settings=*)
			_globalSettings[USER_SET_GLOBAL_CONFIG_SOURCE]=true
			_globalSettings[GLOBAL_CONFIG_SOURCE]="${1#*=}"
		;;

		# Control whether to build the workspace directory tree
		-t|--buildtree)
			_globalSettings[BUILD_WORKSPACE_TREE]=true
		;;
		-T|--nobuildtree)
			_globalSettings[BUILD_WORKSPACE_TREE]=false
		;;

		# Set the RPM spec source
		-r|--rpmspecs)
			if [ -z "$2" ]; then
				logError "-r|--rpmspecs requires a value." >&2
				hasCommandLineErrors=true
			else
				_globalSettings[RPM_SPECS_SOURCE]="$2"
				shift
			fi
		;;
		--rpmspecs=*)
			_globalSettings[RPM_SPECS_SOURCE]="${1#*=}"
		;;

		# Set the working directory
		-w|--workspace)
			if [ -z "$2" ]; then
				logError "-w|--workspace requires a value." >&2
				hasCommandLineErrors=true
			else
				_globalSettings[WORKSPACE]="$2"
				shift
			fi
		;;
		--workspace=*)
			_globalSettings[WORKSPACE]="${1#*=}"
		;;

		# Explicit start of positional arguments
		--)
			shift
			break;
		;;

		# Unknown arguments
		-*)
			logError "Unknown option, $1." >&2
			hasCommandLineErrors=true
		;;

		# Implied start of positional arguments
		*)
			break;
		;;
	esac

	shift
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
