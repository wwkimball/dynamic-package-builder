# Build variables
%define installTo ${:INSTALL_TO}

${@standard.headers}
Source0:     ${:PACKAGE_SOURCE}
${@${:PACKAGE_NAME}.headers}

%description
${:PACKAGE_DESCRIPTION}

%prep
%setup -q

%install
mkdir -p %{buildroot}%{installTo}
cp testorz.sh %{buildroot}%{installTo}

%files
%defattr(0755, ${:CONFIG_FILE_OWNER}, ${:CONFIG_FILE_GROUP}, 0755)
%{installTo}/testorz.sh

%changelog
* ${:PACKAGE_BUILT_TIME} ${:PACKAGE_AUTHOR_NAME} <${:PACKAGE_AUTHOR_EMAIL}> %{version}-%{release}
Packaged automatically by ${:PACKAGE_BUILDER}.
