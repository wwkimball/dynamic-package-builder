################################################################################
# Extension library for ../build-rpm-specs.sh
################################################################################
# Extension libraries must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

if [ 0 -lt $tallyRPMs ] && [ "$actualRPMDir" != "$desiredRPMDir" ]; then
	logInfo "Copying generated RPMs from ${actualRPMDir} to ${desiredRPMDir}"
	if ! mkdir -p "$desiredRPMDir" \
		|| ! cp -Rf "$actualRPMDir"/* "$desiredRPMDir"/
	then
		logWarning "Unable to copy RPMs from ${actualRPMDir} to ${desiredRPMDir}"
	fi
fi
if [ 0 -lt $tallySRPMs ] && [ "$actualSRPMDir" != "$desiredSRPMDir" ]; then
	logInfo "Copying generated SRPMs from ${actualSRPMDir} to ${desiredSRPMDir}"
	if ! mkdir -p "$desiredSRPMDir" \
		|| ! cp -Rf "$actualSRPMDir"/* "$desiredSRPMDir"/
	then
		logWarning "Unable to copy SRPMs from ${actualSRPMDir} to ${desiredSRPMDir}"
	fi
fi

# If requested, FLATTEN_S?RPM_DIRECTORIES
if ${_globalSettings[FLATTEN_RPMS_DIRECTORY]}; then
	logInfo "Flattening ${desiredRPMDir}"
	find "$desiredRPMDir" -type f -name '*.rpm' -print0 | xargs -0 mv "$desiredRPMDir"
	find "$desiredRPMDir" -type d -delete
fi
if ${_globalSettings[FLATTEN_SRPMS_DIRECTORY]}; then
	logInfo "Flattening ${desiredSRPMDir}"
	find "$desiredSRPMDir" -type f -name '*.rpm' -print0 | xargs -0 mv "$desiredSRPMDir"
	find "$desiredSRPMDir" -type d -delete
fi
