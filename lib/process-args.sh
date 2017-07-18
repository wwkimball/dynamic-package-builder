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
_globalSettings[USE_TEMP_WORKSPACE]=${USE_TEMP_WORKSPACE:-false}
_globalSettings[USER_SET_USE_TEMP_WORKSPACE]=false
_globalSettings[SPECS_DIRECTORY]=${SPECS_DIRECTORY:-$(pwd)/SPECS}
_globalSettings[SOURCES_DIRECTORY]=${SOURCES_DIRECTORY:-$(pwd)/SOURCES}

_globalSettings[BUILD_WORKSPACE_TREE]=${BUILD_WORKSPACE_TREE:-true}
_globalSettings[FLUSH_OLD_SPECS]=false

# Process command-line arguments.  Allow environment variables to be used to set
# default values, but command-line arguments override them.  Any positional
# arguments are saved to _positionalArgs.
hasCommandLineErrors=false

# * GLOBAL_CONFIG_SOURCE|--globalconfig|-g:  Directory or file from which all of
#   these global settings can be configured using the same key names as the
#   environment variables.
# * WORKSPACE|--workspace|-w:  The root of the directory tree from where RPM
#   source files are pulled and -- unless USE_TEMP_WORKSPACE is enabled -- where
#   RPM build activities will be conducted.
# * USE_TEMP_WORKSPACE|--tempworkspace|-t|-T|--notempworkspace:  Create a unique
#   temporary workspace to which all SPECS and SOURCES are copied before RPM
#   building begins.  This is forced only when necessary and not specifically
#   disabled.  It is not enabled by default because copying SPECS and SOURCES
#   can be either unnecessarily wasteful or simply a bad idea, like when
#   SOURCES are very large or EXECUTABLE_SPECS is enabled and the executables
#   require a specific relative directory structure.
# * SPECS_DIRECTORY|--rpmspecs|-r:  Where are your RPM SPECS files?  If not
#   ${WORKSPACE}/SPECS, then USE_TEMP_WORKSPACE must be true.  If it is forced
#   by the user to false, then the build must be halted.
# * SOURCES_DIRECTORY|--sources|-s:  Where are your SOURCES files?  If not
#   ${WORKSPACE}/SOURCES, then USE_TEMP_WORKSPACE must be true.  If it is forced
#   by the user to false, then the build must be halted.
# * EXECUTABLE_SPECS|--execspecs|-x|-X|--noexecspecs:  Set true to run any
#   executables in SPECS_DIRECTORY to dynamically generate *.spec files.  false
#   by default.
# * PREBUILD_COMMAND|--precmd|-e:  Command to run before RPM building occurs
#   (and before EXECUTABLE_SPECS is enacted).
# * POSTBUILD_COMMAND|--postcmd|-o:  Command to run after all RPM building
#   activities have concluded successfully but before cleanup.
# * POSTBUILD_ON_PARTIAL|--postpartial|-p|-P|--nopostpartial:  Should
#   POSTBUILD_COMMAND be run for partial successes (when at least one RPM has
#   been generated)?
# * POSTBUILD_ON_FAIL|--postfail|-f|-F|--nopostfail:  Should POSTBUILD_COMMAND
#   be run for total failure (when no RPMs were built, at all)?
# * KEEP_FAILED_TEMP_WORKSPACE|--keepfailedtemp|-k|-K|--nokeepfailedtemp:
#   Boolean to indicate whether to preserve temp workspaces on failure.  true
#   by default.
# * PURGE_TEMP_WORKSPACES_ON_START|--purgeoldtemps|-m:  Boolean to indicate
#   whether to destroy previous temp workspaces on start.  true by default.
# * PURGE_SPECS_ON_START|--purgespecs|-c:  Boolean to indicate whether to
#   destroy all *.spec files at startup.  This is useful for projects that
#   dynamically create *.spec files at build-time.  false by default.
# * PURGE_RPMS_ON_START|--purgerpms|-k:  Boolean to indicate whether to destroy
#   all previously-build *.rpm files at startup.  false by default.
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
		-g|--globalconfig)
			_globalSettings[USER_SET_GLOBAL_CONFIG_SOURCE]=true
			if [ -z "$2" ]; then
				logError "-s|--settings requires a value."
				hasCommandLineErrors=true
			else
				_globalSettings[GLOBAL_CONFIG_SOURCE]="$2"
				shift
			fi
		;;
		--globalconfig=*)
			testValue="${1#*=}"
			if [ -z "$testValue" ]; then
				logError "--settings= requires a value."
				hasCommandLineErrors=true
			else
				_globalSettings[USER_SET_GLOBAL_CONFIG_SOURCE]=true
				_globalSettings[GLOBAL_CONFIG_SOURCE]="$testValue"
			fi
		;;

		# Set the RPM specs directory
		-r|--rpmspecs)
			if [ -z "$2" ]; then
				logError "-r|--rpmspecs requires a value."
				hasCommandLineErrors=true
			else
				_globalSettings[SPECS_DIRECTORY]="$2"
				shift
			fi
		;;
		--rpmspecs=*)
			testValue="${1#*=}"
			if [ -z "$testValue" ]; then
				logError "--rpmspecs= requires a value."
				hasCommandLineErrors=true
			else
				_globalSettings[SPECS_DIRECTORY]="$testValue"
			fi
		;;

		# Set the RPM sources directory
		-s|--sources)
			if [ -z "$2" ]; then
				logError "-s|--sources requires a value."
				hasCommandLineErrors=true
			else
				_globalSettings[SOURCES_DIRECTORY]="$2"
				shift
			fi
		;;
		--sources=*)
			testValue="${1#*=}"
			if [ -z "$testValue" ]; then
				logError "--sources= requires a value."
				hasCommandLineErrors=true
			else
				_globalSettings[SOURCES_DIRECTORY]="$testValue"
			fi
		;;

		# Control whether to use a temporary workspace
		-t|--tempworkspace)
			_globalSettings[USER_SET_USE_TEMP_WORKSPACE]=true
			_globalSettings[USE_TEMP_WORKSPACE]=true
		;;
		-T|--notempworkspace)
			_globalSettings[USER_SET_USE_TEMP_WORKSPACE]=true
			_globalSettings[USE_TEMP_WORKSPACE]=false
		;;

		# Set the working directory
		-w|--workspace)
			if [ -z "$2" ]; then
				logError "-w|--workspace requires a value."
				hasCommandLineErrors=true
			else
				_globalSettings[WORKSPACE]="$2"
				shift
			fi
		;;
		--workspace=*)
			testValue="${1#*=}"
			if [ -z "$testValue" ]; then
				logError "--workspace= requires a value."
				hasCommandLineErrors=true
			else
				_globalSettings[WORKSPACE]="$testValue"
			fi
		;;

		# Control whether to use a temporary workspace
		-x|--execspecs)
			_globalSettings[EXECUTABLE_SPECS]=true
		;;
		-X|--noexecspecs)
			_globalSettings[EXECUTABLE_SPECS]=false
		;;

		# Explicit start of positional arguments
		--)
			shift
			break;
		;;

		# Unknown arguments
		-*)
			logError "Unknown option, $1."
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
	hasCommandLineErrors cliArguments argumentCount \
	testValue
