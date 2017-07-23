################################################################################
# Extension library for ../build-rpm-specs.sh
################################################################################
# Extension libraries must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

# Import helper functions
if ! source "${_funcDir}"/store-allowed-setting.sh; then
	errorOut 3 "Unable to import the store-allowed-setting helper."
fi
if ! source "${_funcDir}"/trims.sh; then
	errorOut 3 "Unable to import the trims helper."
fi

function processArgs__tryStoreAllowedSetting {
	local configKey=${1:?"ERROR:  A configuration key must be specified as the first positional argument to ${BASH_FUNC[0]}."}
	local configValue=$(alltrim "$2")
	local storeResult

	# Bail out when the user fails to supply a config map.
	if [ $# -lt 3 ]; then
		errorOut 42 "Bug!  No configMap passed to ${BASH_FUNC[0]} for ${configKey} from the command-line."
		return 1
	fi

	storeAllowedSetting "$configKey" "$configValue" $3 $4
	storeResult=$?

	case $storeResult in
		0)	# Successful storage
			logDebug "Accepted configuration from the command-line:  ${configKey} = ${configValue}"
		;;

		1)	# No configMap
			errorOut 42 "Bug!  The configuration map could not be dereferenced in ${BASH_FUNC[0]}."
		;;

		2)	# Unacceptable configKey
			errorOut 1 "Unacceptable configuration key from the command-line:  ${configKey}"
		;;

		3)	# Unacceptable configValue
			errorOut 1 "Unacceptable configuration value for key ${configKey} from the command-line:  ${configValue}"
		;;

		*)	# Unknown result
			errorOut 42 "Bug!  Indeterminate error encountered while attempting to store configuration from the command-line:  ${configKey} = ${configValue}"
		;;
	esac

	return $storeResult
}

function printVersion {
	cat <<EOVER
${_myFileName} ${_myVersion}
Copyright (c) 2003-2017, William W. Kimball Jr. MBA MSIS
License:  ISC
EOVER
}

function printUsage {
	echo "${_myFileName} [OPTIONS] [[--] RPMBUILD_ARGS]"
}

function printHelp {
	cat <<EOHELP
At its heart, ${_myName} simply attempts to build RPM and SRPM files from
your sources and RPM specification files.  Because there is little value in
merely wrapping the rpmbuild program, this script family does quite a bit more.

The reality of RPM building is that there is no such thing as a permanently
static RPM specification file.  Packagers who truly adhere to RPM standards
have a fundamental need to produce a unique RPM file every time they run the
rpmbuild program.  At the very least, the release tag number must be incremented
or reset depending on the package version and permanently tracked throughout the
life-span of the source project.  Alone, that is no trivial task but it -- and a
litany of other routine RPM and SRPM file handling chores -- is made simple by
${_myName}.

The default configuration of this script is adequate for the majority of RPM
tasks.  Point it at a directory where your SPECS and SOURCES already exist and
just run it to generate RPM and SRPM files.  Tweak the defaults to take control
whenever you'd rather do something a little different or extend the automation
to take on more of your routine.  Configuration can be supplied via environment
variables, configuration files, and command-line arguments exclusively or
together.  These configuraiton sources are prioritized such that command-line
arguments > configuration file settings > environment variables > defaults.

OPTIONS: aAcCdefFghikKmMopPrstTvwxX => bBDEGHIjJlLnNOqQRSuUVWyYzZ

BUILD_RPMS
BUILD_SRPMS

  -x, --execspecs, EXECUTABLE_SPECS=true
    Run any executables in the SPECS_DIRECTORY, presumably to dynamically
    generate *.spec files.  Default: false

  -X, --noexecspecs, EXECUTABLE_SPECS=false
    Disable running executables in the SPECS_DIRECTORY.  This is the default.

FLATTEN_RPMS_DIRECTORY
FLATTEN_SRPMS_DIRECTORY

  -g FILE_OR_PATH, --globalconfig=FILE_OR_PATH, GLOBAL_CONFIG_SOURCE
    Directory or file from which all of these global settings can be configured
    using the same key names as the environment variables.  When a directory is
    supplied, all *.conf files in that directory (not subdirectories) will be
    consumed.  Default: ./rpm-helpers.conf

  -a, --keepfailedtemp, KEEP_FAILED_TEMP_WORKSPACE=true
    When USE_TEMP_WORKSPACE is enabled also enable this option to preserve the
    temporary workspace whenever any RPM build fails.  Otherwise, the temporary
    workspace is always destroyed.  This can be helpful for troubleshooting your
    RPM builds but should not be left enabled beyond active debugging.  Default:
    false

  -A, --nokeepfailedtemp, KEEP_FAILED_TEMP_WORKSPACE=false
    Always clean up temporary workspaces, even when an error occurs during RPM
    building.  This is the default.

  -d, --debug, OUTPUT_DEBUG
    Maximize the console output level to include debugging messages.  This is
    very noisy.

  -v, --verbose, OUTPUT_VERBOSE
    Increase the console output level to include verbose informative messages.

  -o COMMAND, --postcmd=COMMAND, POSTBUILD_COMMAND
    Command to run after all RPM building activities have concluded successfully
    but before cleanup.

  -p, --postpartial, POSTBUILD_ON_PARTIAL=true
    Run POSTBUILD_COMMAND when at least one RPM or SRPM is successfully
    generated, even if all others were aborted by errors.

  -P, --nopostpartial, POSTBUILD_ON_PARTIAL=false
    Don't run POSTBUILD_COMMAND when any build fails.  This is the default.

  -f, --postfail, POSTBUILD_ON_FAIL=true
    Run POSTBUILD_COMMAND even when all RPM build attempts fail, resulting in no
    RPMs and SRPMs.

  -F, --nopostfail, POSTBUILD_ON_FAIL=false
    Don't allow POSTBUILD_COMMAND to run when all RPM build attempts fail.  This
    is the default.

  -e COMMAND, --precmd=COMMAND, PREBUILD_COMMAND
    Command to run before RPM building occurs (and before EXECUTABLE_SPECS is
    enacted).

  -k, --purgerpms, PURGE_RPMS_ON_START=true
    Destroy all *.rpm and *.srpm files found in RPMS_DIRECTORY and
    SRPMS_DIRECTORY at start.  This is useful for builds that publish the RPM
    and SRPM files to an external repository so that old packages aren't left on
    the local file-system.

  -K, --nopurgerpms, PURGE_RPMS_ON_START=false
    Do not delete any RPM or SRPM files on start.  This is the default.

  -c, --purgespecs, PURGE_SPECS_ON_START=true
    Destroy all *.spec files found in SPECS_DIRECTORY at start.  This is useful
    for projects that dynamically create all *.spec files at run-time.  Default:
    false

  -C, --nopurgespecs, PURGE_SPECS_ON_START=false
    Don't destroy any *.spec files in SPECS_DIRECTORY at start.  This is the
    default.


PURGE_SRPMS_ON_START


  -m, --purgeoldtemps, PURGE_TEMP_WORKSPACES_ON_START=true
    Destroy any ligering temporary workspaces found in WORKSPACE while setting
    up for the next run.  Default: false

  -M, --nopurgeoldtemps, PURGE_TEMP_WORKSPACES_ON_START=false
    Do not destroy old temporary workspaces found in WORKSPACE while setting up
    for the next run.  If you are using -- or are being forced to use --
    temporary workspaces that you do do not clean up, this can cause your file-
    system to become quite full and is strongly discouraged.  This is the
    default.


RPMBUILD_ARGS
RPMS_DIRECTORY


  -s DIRECTORY, --sources=DIRECTORY, SOURCES_DIRECTORY
    Location of your source file(s) for the RPM.  If not ${WORKSPACE}/SOURCES,
    then USE_TEMP_WORKSPACE must be true and will be made so, if necessary.
    Default:  ./SOURCES

  -r DIRECTORY, --rpmspecs=DIRECTORY, SPECS_DIRECTORY
    Location of your RPM specification files.  If not \${WORKSPACE}/SPECS, then
    USE_TEMP_WORKSPACE must be true and will be made so, if necessary.  Default:
    ./SPECS

SRPMS_DIRECTORY

  -t, --tempworkspace, USE_TEMP_WORKSPACE=true
    Create a unique temporary workspace to which all SPECS and SOURCES are
    copied before RPM building begins.  This is forced only when necessary and
    not specifically disabled.  It is not enabled by default because copying
    SPECS and SOURCES can be either unnecessarily wasteful or simply a bad idea,
    like when SOURCES are very large or EXECUTABLE_SPECS is enabled and the
    executables require a specific relative directory structure.  Default: false

  -T, --notempworkspace, USE_TEMP_WORKSPACE=false
    Disable use of temporary workspaces, if possible.  A warning will be issued
    and a temporary workspace will be used anyway when the supplied workspace
    isn't properly built for RPM activities.  This is the default.

  -w DIRECTORY, --workspace=DIRECTORY, WORKSPACE
    The root of the directory tree from where RPM source files are pulled and
    -- unless USE_TEMP_WORKSPACE is enabled -- where RPM build activities will
    be conducted.  Default: .

$(printVersion)

$(cat "${_myDir}"/LICENSE)
EOHELP
}

# Process command-line arguments.  Allow environment variables to be used to set
# default values, but command-line arguments override them.  Any positional
# arguments are saved to _positionalArgs.
hasCommandLineErrors=false
while [ $# -gt 0 ]; do
	case $1 in
		# Control whether to destroy all *.spec files in SPECS_DIRECTORY during
		# setup.
		-c|--purgespecs)
			cliSettings[PURGE_SPECS_ON_START]=true
		;;
		-C|--nopurgespecs)
			cliSettings[PURGE_SPECS_ON_START]=false
		;;

		# Enable debugging output
		-d|--debug)
			cliSettings[OUTPUT_VERBOSE]=true
			cliSettings[OUTPUT_DEBUG]=true
		;;

		# Set the pre-build command
		-e|--precmd)
			if [ -z "$2" ]; then
				logError "-e|--precmd requires a value."
				hasCommandLineErrors=true
			else
				processArgs__tryStoreAllowedSetting \
					PREBUILD_COMMAND "$2" \
					cliSettings _globalSettingsRules
				shift
			fi
		;;
		--precmd=*)
			testValue="${1#*=}"
			if [ -z "$testValue" ]; then
				logError "--precmd= requires a value."
				hasCommandLineErrors=true
			else
				processArgs__tryStoreAllowedSetting \
					PREBUILD_COMMAND "$testValue" \
					cliSettings _globalSettingsRules
			fi
		;;

		# Control whether to run POSTBUILD_COMMAND even when all RPM builds fail
		-f|--postfail)
			cliSettings[POSTBUILD_ON_FAIL]=true
		;;
		-F|--nopostfail)
			cliSettings[POSTBUILD_ON_FAIL]=false
		;;

		# Set the core configuration source
		-g|--globalconfig)
			if [ -z "$2" ]; then
				logError "-s|--globalconfig requires a value."
				hasCommandLineErrors=true
			else
				processArgs__tryStoreAllowedSetting \
					GLOBAL_CONFIG_SOURCE "$2" \
					cliSettings _globalSettingsRules
				shift
			fi
		;;
		--globalconfig=*)
			testValue="${1#*=}"
			if [ -z "$testValue" ]; then
				logError "--globalconfig= requires a value."
				hasCommandLineErrors=true
			else
				processArgs__tryStoreAllowedSetting \
					GLOBAL_CONFIG_SOURCE "$testValue" \
					cliSettings _globalSettingsRules
			fi
		;;

		# Help requests
		-h|--help)
			printHelp
			exit 0
		;;

		# Version query
		-i|--version)
			printVersion
			exit 0
		;;

		# Control whether to destroy all *.rpm files anywhere in
		# ${WORKSPACE}/{RPMS,SRPMS} during setup.
		-k|--purgerpms)
			cliSettings[PURGE_RPMS_ON_START]=true
		;;
		-K|--nopurgerpms)
			cliSettings[PURGE_RPMS_ON_START]=false
		;;

		# Control whether to purge all old temporary workspaces under WORKSPACE
		# at the start of this run.
		-m|--purgeoldtemps)
			cliSettings[PURGE_TEMP_WORKSPACES_ON_START]=true
		;;
		-M|--nopurgeoldtemps)
			cliSettings[PURGE_TEMP_WORKSPACES_ON_START]=false
		;;

		# Set the pre-build command
		-o|--postcmd)
			if [ -z "$2" ]; then
				logError "-o|--postcmd requires a value."
				hasCommandLineErrors=true
			else
				processArgs__tryStoreAllowedSetting \
					POSTBUILD_COMMAND "$2" \
					cliSettings _globalSettingsRules
				shift
			fi
		;;
		--postcmd=*)
			testValue="${1#*=}"
			if [ -z "$testValue" ]; then
				logError "--postcmd= requires a value."
				hasCommandLineErrors=true
			else
				processArgs__tryStoreAllowedSetting \
					POSTBUILD_COMMAND "$testValue" \
					cliSettings _globalSettingsRules
			fi
		;;

		# Control whether to run POSTBUILD_COMMAND when one or more, but not
		# all, RPMs are successfully built.
		-p|--postpartial)
			cliSettings[POSTBUILD_ON_PARTIAL]=true
		;;
		-P|--nopostpartial)
			cliSettings[POSTBUILD_ON_PARTIAL]=false
		;;

		# Set the RPM specs directory
		-r|--rpmspecs)
			if [ -z "$2" ]; then
				logError "-r|--rpmspecs requires a value."
				hasCommandLineErrors=true
			else
				processArgs__tryStoreAllowedSetting \
					SPECS_DIRECTORY "$2" \
					cliSettings _globalSettingsRules
				shift
			fi
		;;
		--rpmspecs=*)
			testValue="${1#*=}"
			if [ -z "$testValue" ]; then
				logError "--rpmspecs= requires a value."
				hasCommandLineErrors=true
			else
				processArgs__tryStoreAllowedSetting \
					SPECS_DIRECTORY "$testValue" \
					cliSettings _globalSettingsRules
			fi
		;;

		# Set the RPM sources directory
		-s|--sources)
			if [ -z "$2" ]; then
				logError "-s|--sources requires a value."
				hasCommandLineErrors=true
			else
				processArgs__tryStoreAllowedSetting \
					SOURCES_DIRECTORY "$2" \
					cliSettings _globalSettingsRules
				shift
			fi
		;;
		--sources=*)
			testValue="${1#*=}"
			if [ -z "$testValue" ]; then
				logError "--sources= requires a value."
				hasCommandLineErrors=true
			else
				processArgs__tryStoreAllowedSetting \
					SOURCES_DIRECTORY "$testValue" \
					cliSettings _globalSettingsRules
			fi
		;;

		# Control whether to use a temporary workspace
		-t|--tempworkspace)
			cliSettings[USE_TEMP_WORKSPACE]=true
		;;
		-T|--notempworkspace)
			cliSettings[USE_TEMP_WORKSPACE]=false
		;;

		# Enable verbose output
		-v|--verbose)
			cliSettings[OUTPUT_VERBOSE]=true
		;;

		# Set the working directory
		-w|--workspace)
			if [ -z "$2" ]; then
				logError "-w|--workspace requires a value."
				hasCommandLineErrors=true
			else
				processArgs__tryStoreAllowedSetting \
					WORKSPACE "$2" \
					cliSettings _globalSettingsRules
				shift
			fi
		;;
		--workspace=*)
			testValue="${1#*=}"
			if [ -z "$testValue" ]; then
				logError "--workspace= requires a value."
				hasCommandLineErrors=true
			else
				processArgs__tryStoreAllowedSetting \
					WORKSPACE "$testValue" \
					cliSettings _globalSettingsRules
			fi
		;;

		# Control whether to run executablse in SPECS_DIRECTORY
		-x|--execspecs)
			cliSettings[EXECUTABLE_SPECS]=true
		;;
		-X|--noexecspecs)
			cliSettings[EXECUTABLE_SPECS]=false
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
if [ $# -gt 0 ]; then
	processArgs__tryStoreAllowedSetting RPMBUILD_ARGS "$*" cliSettings _globalSettingsRules
fi

# Cleanup
unset printVersion printUsage printHelp processArgs__tryStoreAllowedSetting \
	hasCommandLineErrors testValue
