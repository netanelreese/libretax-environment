%define use_date %( date "+%%Y%%m%%d" )_COMMIT_SHA

Name:       lt_env
Version:    0.1
Release:    %{use_date}
Summary:    LibreTax Suite Environment Script
License:    GNU GPL-3.0
Source0:    lt.env
BuildArch:  noarch
BuildRoot: %{_builddir}/%{name}-root
BuildRequires: systemd-rpm-macros

%description
LibreTax Suite Environment Script

%install
install -d %{buildroot}/etc/libretax/env
install -m 0644 %{_sourcedir}/lt.env %{buildroot}/etc/libretax/env/lt.env

%files
/etc/libretax/env

%changelog
* Wed Nov 6th 2024 Nathanael G. Reese <nathanael.g.reese@gmail.com> - 0.1
- Initial LibreTax environment file rpm
