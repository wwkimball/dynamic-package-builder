################################################################################
# Extension library for ../build-rpm-specs.sh
################################################################################
# Extension libraries must not be directly executed
if [ -z "${BASH_SOURCE[1]}" ]; then
	echo "ERROR:  You may not call $0 directly." >&2
	exit 1
fi

# The LICENSE file must be intact
licenseFile="${_myDir}"/LICENSE
if [ ! -f "$licenseFile" -o ! -s "$licenseFile" ]; then
	errorOut 123 "Your use of ${_myName} is unlicensed."
fi

# Prohibit running as root
if [ 0 -eq $(id -u) ]; then
	errorOut 126 "You must not run ${_myFileName} as root!"
fi

# Bash 4.3+ is required
if [[ $BASH_VERSION =~ ^([0-9]+\.[0-9]+).+$ ]]; then
	bashMajMin=${BASH_REMATCH[1]}
	bashMinVer='4.3'
	if [ 0 -ne $(bc <<< "${bashMinVer} > ${bashMajMin}") ]; then
		errorOut 127 "bash version ${bashMinVer} or higher is required.  You have ${BASH_VERSION}.\n$(bash --version)"
	fi
else
	errorOut 128 "Unable to identify the installed version of bash."
fi

# rpmbuild must be installed
if ! which rpmbuild &>/dev/null; then
	errorOut 125 "The rpmbuild program must be installed and accessible on the PATH."
fi

# realpath must be installed
if ! which realpath &>/dev/null; then
	errorOut 124 "The realpath program must be installed and accessible on the PATH."
fi

unset bashMajMin bashMinVer
