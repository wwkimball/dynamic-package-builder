################################################################################
# Extension library for ../build-rpm-specs.sh
################################################################################
# Extension libraries must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

# Run rpmbuild against every *.spec file in the RPM specs directory after
# determining whether to build RPMs, SRPMs, or both.  When neither, issue an
# error.
packagesBuilt=false
packageFailures=false
rpmBuildMode=ba
if ${_globalSettings[BUILD_RPMS]} && ${_globalSettings[BUILD_SRPMS]}; then
	logVerbose "Building both RPMs and SRPMs"
	rpmBuildMode=ba
elif ${_globalSettings[BUILD_RPMS]} && ! ${_globalSettings[BUILD_SRPMS]}; then
	logVerbose "Building only RPMs (no SRPMs)"
	rpmBuildMode=bb
elif ! ${_globalSettings[BUILD_RPMS]} && ${_globalSettings[BUILD_SRPMS]}; then
	logVerbose "Building only SRPMs (no RPMs)"
	rpmBuildMode=bs
else
	errorOut 30 "You have specified that neither RPMs nor SRPMs be built."
fi

while IFS= read -r -d '' specFile; do
	logInfo "Building ${specFile}..."
	if rpmbuild \
		--define "_topdir ${_globalSettings[WORKSPACE]}" \
		-${rpmBuildMode} "$specFile" \
		${_globalSettings[RPMBUILD_ARGS]}
	then
		packagesBuilt=true
	else
		logWarning "${specFile} has failed to build."
		packageFailures=true
	fi
done < <(find "${_globalSettings[SPECS_DIRECTORY]}" -maxdepth 1 -type f -name '*.spec' -print0)

# Pass errors to the caller
if $packageFailures; then
	if $packagesBuilt; then
		_exitCode=101
	else
		_exitCode=100
	fi
fi
