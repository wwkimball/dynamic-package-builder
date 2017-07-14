#!/bin/bash
################################################################################
# Extension library for ../build-rpm-specs.sh
################################################################################
# Extension libraries must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

function printVersion {
	echo $_myVersion
}

function printUsage {
	echo "${_myFileName} [OPTIONS] [-- RPMBUILD OPTIONS]"
}

function printHelp {
	echo "Help yourself."
	echo "Version: $(printVersion)"
}

# Process command-line arguments.  Allow environment variables to be used to set
# default values, but command-line arguments override them.  Any positional
# arguments are saved to _positionalArgs.
declare -a _positionalArgs
workSpaceDir=${WORKSPACE:-$(pwd)}
hasCommandLineErrors=false
while [ $# -gt 0 ]; do
	case $1 in
		# Help requests
		-h|--help)
			printHelp
			exit 0
		;;

		# Set the working directory
		-w|--workspace)
			workSpaceDir="$2"
			shift 2
		;;
		--workspace=*)
			workSpaceDir="${1#*=}"
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

# Copy any remaining arguments into _positionalArgs but strip off any unclean
# demarcation symbols.
declare -a cliArguments=("$@")
argumentCount=${#cliArguments[@]}
for ((i = 0; i < argumentCount; i++)); do
	testArgument=${cliArguments[$i]}
	echo "i:${i}: [${testArgument}]"


done

# Cleanup
unset printVersion printUsage printHelp \
	hasCommandLineErrors cliArguments argumentCount
