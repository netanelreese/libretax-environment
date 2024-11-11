#!/bin/bash
#==============================================================================
# FILE: rpm-build.sh
# DESCRIPTION: Builds the LibreTax Environment rpms.
# USAGE: ./rpm-build.sh [optional arguments]
#
# REQUIREMENTS: 
#     * 
# AUTHOR: Nathanael G. Reese, nathanael.g.reese@gmail.com
# CREATED: 2024-11-10
# MODIFIED: 2024-11-10
# VERSION: 1.0
#==============================================================================

source "$(cd .. && pwd)"/pkg/lt_env/SOURCE/lt.env

set -e

if [[ "$EUID" -ne 0 ]]; then
   print_error "This script must be run as root." >&2
   exit 1
fi

####################################################################################################
# Start Global Member Assignment
####################################################################################################

REPO_DIR="$(cd .. && pwd)"
RPM_DIR="${REPO_DIR}/rpms"
RPM_TMP="/tmp/LIBRETAX-RPM-$(date +'%Y%m%d_%H%M%S')"

####################################################################################################
# Start Function Definitions
####################################################################################################

exception() {
	print_error "$@"
 	cleanup
  	exit 1
}

prep_rpm_tree() {
    mkdir -p "${RPM_TMP}" || exception "Could not create ${RPM_TMP}"
    rpmdev-setuptree
    pushd "${RPM_DIR}"
    find . -name SOURCE -exec cp -r {} "${RPM_TMP}" \;
    find . -name SPECS -exec cp -r {} "${RPM_TMP}" \;
    popd
}

build_rpms() {
    pushd "${RPM_TMP}"
    rpmbuild -bb SPECS/*.spec
    popd
}

# Cleans up tmp build directory
cleanup() {
	rm -rf "${RPM_TMP}" || print_warn "Could not delete ${BUILD_DIR}"
	print_success "Temporary Build Dir Cleaned!"
}
####################################################################################################
# Start Script Execution
####################################################################################################

prep_rpm_tree
build_rpms
cleanup

exit 0