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
	local configKey=${1:?"ERROR:  A configuration key must be specified as the first positional argument to ${FUNCNAME[0]}."}
	local configValue=$(alltrim "$2")
	local storeResult

	# Bail out when the user fails to supply a config map.
	if [ $# -lt 3 ]; then
		errorOut 42 "Bug!  No configMap passed to ${FUNCNAME[0]} for ${configKey} from the command-line."
		return 1
	fi

	storeAllowedSetting "$configKey" "$configValue" $3 $4
	storeResult=$?

	case $storeResult in
		0)	# Successful storage
			logDebug "Accepted configuration from the command-line:  ${configKey} = ${configValue}"
		;;

		1)	# No configMap
			errorOut 42 "Bug!  The configuration map could not be dereferenced in ${FUNCNAME[0]}."
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
	echo "${_myFileName} [OPTIONS] [-- RPMBUILD_ARGS]"
}

# Used short-args:  aAbBcCdefFghikKlLmMopPrstTuUvwxXyYzZ (DEGHIjJnNOqQRSVW)
function printHelp {
	local helpSubject=${1^^}

	case $helpSubject in
		CONFIGS)
			cat <<EOCONFIGHELP
${_myName} employs configuration files for both its global settings
and for optional external configuration for each RPM specification file.  These
are not static files.  The configuration file format defines keys, values, and
comments as follows:
   1. Whitespace before the key, on either side of the assignment operator,
      after the value, and on otherwise empty lines is ignored.
   2. Keys and values may be separated by either = or : assignment operators.
      So, these lines are equivalent:
      KEY = VALUE
      KEY: VALUE
   3. Values may be bare (non-demarcated) or demarcated with either ' or "
      symbols, however comments may be added only after demarcated values lest #
      would otherwise never be allowed as part of a value.
   4. Values may be dedented or non-dedented HEREDOCs.  A non-dedented HEREDOC is
      identified as all the content between <<HERETAG and HERETAG, where HERETAG
      is any arbitrary sequence of capitalized letters and underscore characters.
      A dedented HEREDOC is indicated by prefixing the arbitrary HERETAG with a -
      symbol.  Whereas a non-dedented HEREDOC value preserves all whitespace
      between the HERETAGs, a dedented HEREDOC strips the leading whitespace from
      every line, up to the number of whitespace characters present on the first
      line, up to the first non-whitespace character.
   5. Unterminated HEREDOCs will generate a fatal error.
   6. Outside of HEREDOCs, # marks the start of a comment.  Entire lines may be
      commented.  Comments may appear at the end of any line except when it is a
      key=value line with no demarcation of the value.  HEREDOC values are
      treated verbatim, so # is not ignored.  Examples:
      KEY = VALUE   # THIS COMMENT BECOMES PART OF THE NON-DEMARCATED VALUE!
      KEY = 'Value' # This comment is ignored
      KEY = "Value" # This comment is also ignored
   7. Outside of HEREDOCs, blank lines are ignored.  HEREDOC values are treated
      verbatim, so blank lines become part of the value.
   8. Values can be read from external files by using the form:
      KEY = <@ /path/to/file-containing-the-value
   9. Values can be read from executable statements by using the form:
      KEY = <$ some-executable-command-sequence-that-writes-to-STDOUT
  10. All key names are cast to upper-case, so the following are equivalent:
      key = value
      KEY = value
      Key = value
  11. Key names must begin with an alphabetic character but may otherwise
      consist of any alphanumeric characters and the _ symbol.

External configuration files for spec files are found by matching the spec
filename against a conf file by the same name in the same directory.
EOCONFIGHELP
		;;

        SPECS)
			cat <<EOSPECHELP
RPM specification files are so heavily documented elsewhere that their details
and idiosynchracies will not be discussed here.  Rather, this documentation
covers the extensions that are afforded by ${_myName}.  These are expressed
as shell-style variable substitutions.  However, to avoid conflict with
variables that are meant to be left untouched in your scriptlets, some
additional symbols are employed.  The supported extensions include:
  1. \${:VAR_NAME} is a simple variable substitution.  Available variables come
     from the global settings as well as any keys found within configuration
     files by the same name and in the same directory as the spec file itself
     with a conf file extension (so, product-name.spec can have a configuration
     file named product-name.conf).  See --help CONFIGS for more detail on how
     to create these variables.
  2. \${:VAR_NAME:=default} and \${:VAR_NAME:-default} are identical to
     \${:VAR_NAME} except that 'default' becomes the value when VAR_NAME is
     undefined or empty.
  3. \${@FILE_CONCAT} copies the content of FILE_CONCAT verbatim into the spec
     file.

The {} pair is not optional.  Failure to use them will result in your
substitution attempt being ignored.







TODO:  Document protection against interminable recursion







Variable name substitution and file concatenation occur repeatedly over the
spec file until there are no such operations remaining or a recursion limit set
via ______ as been reached (caused by repeatedly triggering the same variable
substitution or file concatenation too many times).  So, variables injected
by a concatenation are substituted on the subsequent pass, which can result in
more concatenations, and so on.  You may use variable substitution to
dynamically identify concatenation file-names.

In addition to whatever variables you may define within the optional
configuration file for your RPM specification, the following variables are also
available, which you can override:
  * PACKAGE_NAME
  * PACKAGE_ARCH
  * PACKAGE_BUILDER
  * PACKAGE_BUILT_TIME
  * PACKAGE_RELEASE_NUMBER
EOSPECHELP
		;;

		*)	# General
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

OPTIONS:
  -h [SUBJECT], --help [SUBJECT]
    Print this general help or more specific documentation on any of these
    SUBJECT categories, then quits:
      * CONFIGS
      * SPECS

  -i, --version
    Prints version and license information, then quits.

  -b, --buildrpms, BUILD_RPMS=true
  -B, --nobuildrpms, BUILD_RPMS=false
    Enable or disable building RPM files.  There is little value in building
    nothing, so this option might be used when BUILD_SRPMS is enabled.  Default:
    true

  -u, --buildsrpms, BUILD_SRPMS=true
  -U, --nobuildsrpms, BUILD_SRPMS=false
    Enable or disable building SRPM (Source RPM) files.  Default: true

  -x, --execspecs, EXECUTABLE_SPECS=true
  -X, --noexecspecs, EXECUTABLE_SPECS=false
    Enable or disable running executables in the SPECS_DIRECTORY, presumably to
    dynamically generate *.spec files.  Default: false

  -y, --flattenrpmdir, FLATTEN_RPMS_DIRECTORY=true
  -Y, --noflattenrpmdir, FLATTEN_RPMS_DIRECTORY=false
    Enable or disable flattening the RPMS output directory.  The rpmbuild
    program normally creates a deep directory structure that sorts built RPMs by
    platform and architecture.  Enabling this option moves the output files to
    the top-level directory.  Default: false

  -z, --flattensrpmdir, FLATTEN_SRPMS_DIRECTORY=true
  -Z, --noflattensrpmdir, FLATTEN_SRPMS_DIRECTORY=false
    Enable or disable flattening the SRPMS output directory.  The rpmbuild
    program normally creates a deep directory structure that sorts built SRPMs
    by platform and architecture.  Enabling this option moves the output files
    to the top-level directory.  Default: false

  -g FILE_OR_PATH, --globalconfig=FILE_OR_PATH, GLOBAL_CONFIG_SOURCE
    Directory or file from which all of these global settings can be configured
    using the same key names as the environment variables.  When a directory is
    supplied, all *.conf files in that directory (not subdirectories) will be
    consumed.  Default: ./rpm-helpers.conf

  -a, --keepfailedtemp, KEEP_FAILED_TEMP_WORKSPACE=true
  -A, --nokeepfailedtemp, KEEP_FAILED_TEMP_WORKSPACE=false
    When USE_TEMP_WORKSPACE is enabled, also enable this option to preserve the
    temporary workspace whenever any RPM build fails.  Otherwise, the temporary
    workspace is always destroyed.  This can be helpful for troubleshooting your
    RPM builds but should not be left enabled beyond active debugging.  Default:
    false

  -d, --debug, OUTPUT_DEBUG
    Maximize the console output level to include debugging messages.  This is
    very noisy.

  -v, --verbose, OUTPUT_VERBOSE
    Increase the console output level to include verbose informative messages.

  -o COMMAND, --postcmd=COMMAND, POSTBUILD_COMMAND
    Command to run after all RPM building activities have concluded successfully
    but before cleanup.

  -p, --postpartial, POSTBUILD_ON_PARTIAL=true
  -P, --nopostpartial, POSTBUILD_ON_PARTIAL=false
    Run POSTBUILD_COMMAND when at least one RPM or SRPM is successfully
    generated, even if all others were aborted by errors.  Default: false

  -f, --postfail, POSTBUILD_ON_FAIL=true
  -F, --nopostfail, POSTBUILD_ON_FAIL=false
    Run POSTBUILD_COMMAND even when all RPM build attempts fail, resulting in no
    RPMs and SRPMs.  Default: false

  -e COMMAND, --precmd=COMMAND, PREBUILD_COMMAND
    Command to run before RPM building occurs (and before EXECUTABLE_SPECS is
    enacted).

  -k, --purgerpms, PURGE_RPMS_ON_START=true
  -K, --nopurgerpms, PURGE_RPMS_ON_START=false
    Destroy all *.rpm files found in RPMS_DIRECTORY and at start.  This is
    useful for builds that publish the files to an external repository so that
    old packages aren't left on the local file-system.  Default:  false

  -c, --purgespecs, PURGE_SPECS_ON_START=true
  -C, --nopurgespecs, PURGE_SPECS_ON_START=false
    Destroy all *.spec files found in SPECS_DIRECTORY at start.  This is useful
    for projects that dynamically create all *.spec files at run-time.  Default:
    false

  -l, --purgesrpms, PURGE_SRPMS_ON_START=true
  -L, --nopurgesrpms, PURGE_SRPMS_ON_START=false
    Destroy all *.srpm files found in SRPMS_DIRECTORY at start.  This is useful
    for builds that publish the files to an external repository so that old
    packages aren't left on the local file-system.  Default:  false

  -m, --purgeoldtemps, PURGE_TEMP_WORKSPACES_ON_START=true
  -M, --nopurgeoldtemps, PURGE_TEMP_WORKSPACES_ON_START=false
    Destroy any ligering temporary workspaces found in WORKSPACE while setting
    up for the next run.  Default: false

  -n DIRECTORY, --rpmdir=DIRECTORY, RPMS_DIRECTORY
    Final directory for all generated RPM files to be placed into, including
    the nested directory structure that is created by the rpmbuild program.  To
    flatten this directory structure (so that the files are placed directly into
    the DIRECTORY you specify instead of a sub-directory within), you will need
    to enable FLATTEN_RPMS_DIRECTORY.  Default:  ./RPMS

  -s DIRECTORY, --sources=DIRECTORY, SOURCES_DIRECTORY
    Location of your source file(s) for the RPM.  If not ${WORKSPACE}/SOURCES,
    then USE_TEMP_WORKSPACE must be true and will be made so, if necessary.
    Default:  ./SOURCES

  -r DIRECTORY, --rpmspecs=DIRECTORY, SPECS_DIRECTORY
    Location of your RPM specification files.  If not \${WORKSPACE}/SPECS, then
    USE_TEMP_WORKSPACE must be true and will be made so, if necessary.  Default:
    ./SPECS

  -j DIRECTORY, --srpmdir=DIRECTORY, SRPMS_DIRECTORY
    Final directory for all generated SRPM files to be placed into, including
    the nested directory structure that is created by the rpmbuild program.  To
    flatten this directory structure (so that the files are placed directly into
    the DIRECTORY you specify instead of a sub-directory within), you will need
    to enable FLATTEN_SRPMS_DIRECTORY.  Default:  ./SRPMS

  -t, --tempworkspace, USE_TEMP_WORKSPACE=true
  -T, --notempworkspace, USE_TEMP_WORKSPACE=false
    Create a unique temporary workspace to which all SPECS and SOURCES are
    copied before RPM building begins.  This is forced only when necessary and
    not specifically disabled.  It is not enabled by default because copying
    SPECS and SOURCES can be either unnecessarily wasteful or simply a bad idea,
    like when SOURCES are very large or EXECUTABLE_SPECS is enabled and the
    executables require a specific relative directory structure.  Default: false

  -w DIRECTORY, --workspace=DIRECTORY, WORKSPACE
    The root of the directory tree from where RPM source files are pulled and
    -- unless USE_TEMP_WORKSPACE is enabled -- where RPM build activities will
    be conducted.  Default: .

  -- RPMBUILD_ARGS
    Any additional command-line arguments to pass directly to the rpmbuild
    program.  A -- must be used to separate argument sets between
    ${_myName} and rpmbuild on the command-line.
EOHELP
		;;
	esac

	echo
	printVersion
	echo
	cat "${_myDir}"/LICENSE
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
			printHelp $2
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

		-b|--buildrpms)
			cliSettings[BUILD_RPMS]=true
		;;
		-B|--nobuildrpms)
			cliSettings[BUILD_RPMS]=false
		;;

		-u|--buildsrpms)
			cliSettings[BUILD_SRPMS]=true
		;;
		-U|--nobuildsrpms)
			cliSettings[BUILD_SRPMS]=false
		;;

		-y|--flattenrpmdir)
			cliSettings[FLATTEN_RPMS_DIRECTORY]=true
		;;
		-Y|--noflattenrpmdir)
			cliSettings[FLATTEN_RPMS_DIRECTORY]=false
		;;

		-z|--flattensrpmdir)
			cliSettings[FLATTEN_SRPMS_DIRECTORY]=true
		;;
		-Z|--noflattensrpmdir)
			cliSettings[FLATTEN_SRPMS_DIRECTORY]=false
		;;

		-a|--keepfailedtemp)
			cliSettings[KEEP_FAILED_TEMP_WORKSPACE]=true
		;;
		-A|--nokeepfailedtemp)
			cliSettings[KEEP_FAILED_TEMP_WORKSPACE]=false
		;;

		-l|--purgesrpms)
			cliSettings[PURGE_SRPMS_ON_START]=true
		;;
		-L|--nopurgesrpms)
			cliSettings[PURGE_SRPMS_ON_START]=false
		;;

		-n|--rpmdir)
			if [ -z "$2" ]; then
				logError "-n|--rpmdir requires a value."
				hasCommandLineErrors=true
			else
				processArgs__tryStoreAllowedSetting \
					RPMS_DIRECTORY "$2" \
					cliSettings _globalSettingsRules
				shift
			fi
		;;
		--rpmdir=*)
			testValue="${1#*=}"
			if [ -z "$testValue" ]; then
				logError "--rpmdir= requires a value."
				hasCommandLineErrors=true
			else
				processArgs__tryStoreAllowedSetting \
					RPMS_DIRECTORY "$testValue" \
					cliSettings _globalSettingsRules
			fi
		;;

		-j|--srpmdir)
			if [ -z "$2" ]; then
				logError "-j|--srpmdir requires a value."
				hasCommandLineErrors=true
			else
				processArgs__tryStoreAllowedSetting \
					SRPMS_DIRECTORY "$2" \
					cliSettings _globalSettingsRules
				shift
			fi
		;;
		--srpmdir=*)
			testValue="${1#*=}"
			if [ -z "$testValue" ]; then
				logError "--srpmdir= requires a value."
				hasCommandLineErrors=true
			else
				processArgs__tryStoreAllowedSetting \
					SRPMS_DIRECTORY "$testValue" \
					cliSettings _globalSettingsRules
			fi
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
