#!/usr/bin/env bash
###############################################################################
# Run tests against dynamic-package-builder.
###############################################################################
_testDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export WORKSPACE=${WORKSPACE:-${_testDir}/workspace}
cd "$_testDir"

# Some clone operations mysteriously fail to properly set execute bits
find .. -type f -name '*.sh' -exec chmod +x {} \;

# Cleanup from previous on-the-fly tests
rm -rf SOURCES RPMS SRPMS *-src

# Create sample source files
rm -rf testorz-src
mkdir testorz-src
cat >testorz-src/testorz.sh <<-"EOTESTFILE"
	#!/usr/bin/env bash
	###############################################################################
	# Sample shell script for the testorz RPM.
	###############################################################################
	_myVersion=1.0.0
	readonly _myVersion
	echo "$0 version ${_myVersion} success!"
EOTESTFILE

rm -rf cats-are-crazy-src
mkdir cats-are-crazy-src
cat >cats-are-crazy-src/cats-are-crazy.sh <<-"EOTESTCAC"
	#!/usr/bin/env bash
	###############################################################################
	# Sample shell script for the cats-are-crazy RPM.
	###############################################################################
	_myVersion=0.1.0
	readonly _myVersion
	echo "$(basename $0 .sh) version ${_myVersion} success; and yes, they ARE!"
EOTESTCAC

# Build an RPM for the sample source file
../build-rpm-specs.sh \
	--purgeoldtemps --tempworkspace --keepfailedtemp \
	--purgerpms     --buildrpms     --flattenrpmdir  \
	--purgesrpms    --nobuildsrpms \
	--noexecspecs \
	--debug

# Cleanup
rm -rf SOURCES SRPMS *-src workspace
