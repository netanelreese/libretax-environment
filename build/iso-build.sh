#!/bin/bash
#==============================================================================
# FILE: iso-build.sh
# DESCRIPTION: Builds the LibreTax Environment iso.
# USAGE: ./iso-build.sh [optional arguments]
#
# REQUIREMENTS: 
#     * xorriso
# AUTHOR: Nathanael G. Reese, nathanael.g.reese@gmail.com
# CREATED: 2024-11-07
# MODIFIED: 2024-11-07
# VERSION: 1.0
#==============================================================================

set -e

if [[ "$EUID" -ne 0 ]]; then
   echo "This script must be run as root." >&2
   exit 1
fi

####################################################################################################
# Start Global Member Assignment
####################################################################################################

REPO_DIR="$(cd .. && pwd)"
ENV="${REPO_DIR}/pkg/lt_env/SOURCE/lt.env"
ISO_SRC="https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-dvd1.iso"
SRC_ISO="CentOS-Stream-9-latest-x86_64-dvd1.iso"
ISO_MD5="https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-boot.iso.MD5SUM"
ISO_SHA1="https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-boot.iso.SHA1SUM"
ISO_SHA256="https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-20241028.0-x86_64-dvd1.iso.SHA256SUM"
VOLUME_NAME="LIBRETAX-RH9"
BUILD_DIR="/tmp/LIBRETAX-BUILD-$(date -Iminutes)"
ARTIFACT_DIR="/tmp/LIBRETAX-ARTIFACT-$(date -Iminutes)"
OUTPUT_ISO="${ARTIFACT_DIR}/${VOLUME_NAME}.iso"
ISOWORKDIR="${BUILD_DIR}/workdir"
ISOMNTDIR="${BUILD_DIR}/mnt"

####################################################################################################
# Start Function Definitions
####################################################################################################

# Find and set the environment file in the home directory of runner.
set_env() {
	source "${ENV}"
	print_info "Setting environment file: ${ENV}"
}

# Creates the directory used to build
prep_build_dir() {
	print_info "Creating temp build directory at ${BUILD_DIR}"
	mkdir -p "${ISOWORKDIR}" || print_error "Could not create ${ISOWORKDIR}" && cleanup && exit 1;
 	mkdir -p "${ISOMNTDIR}" || print_error "Could not create ${ISOMNTDIR}" && cleanup && exit 1;
	print_success "Build Directory Created: ${BUILD_DIR}"
}

# Pulls latest x64 iso from cent mirror
pull_latest_iso() {
	curl "${ISO_SRC}" -o "${BUILD_DIR}/${SRC_ISO}" || print_error "Could not pull latest CentOS iso" && cleanup && exit 1;
 	curl "${ISO_MD5}" -o "${BUILD_DIR}/${SRC_ISO}.MD5SUM" || print_error "Could not pull latest CentOS iso MD5 checksum" && cleanup && exit 1;
	curl "${IDO_SHA1}" -o "${BUILD_DIR}/${SRC_ISO}.SHA1SUM" || print_error "Could not pull latest CentOS iso SHA1 checksum" && cleanup && exit 1;
 	curl "${ISO_SHA256}" -o "${BUILD_DIR}/${SRC_ISO}.SHA256SUM" || print_error "Could not pull latest CentOS iso SHA256 checksum" && cleanup && exit 1;

 	# Verify Checksums
  	pushd "${BUILD_DIR}"
	md5sum -c "${SRC_ISO}".MD5SUM || print_error "MD5 CHECKSUM DOES NOT MATCH" && cleanup && exit 1;
 	sha1sum -c "${SRC_ISO}".SHA1SUM || print_error "SHA1 CHECKSUM DOES NOT MATCH" && cleanup && exit 1;
  	sha256sum -c "${SRC_ISO}".SHA256SUM || print_error "SHA256 CHECKSUM DOES NOT MATCH" && cleanup && exit 1;
   	popd
}

# Create the new ISO with xorriso
build_iso() {
	mkdir -p "${ARTIFACT_DIR}"

	xorriso -as mkisofs -U -r -v -J -V ${VOLUME_NAME} -volset ${VOLUME_NAME} -A ${VOLUME_NAME} \
                -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 \
    	        -boot-info-table --eltorito-alt-boot -e images/efiboot.img -no-emul-boot \
    	        -o "${OUTPUT_ISO}" "${ISOWORKDIR}"

	if [ $? -ne 0 ]; then
	    print_error "Failed to create the ISO\n"
	    cleanup
	    exit 1
	fi
}

# Cleans up tmp build directory
cleanup() {
	if [[ -d "${ISOMNTDIR}" ]]; then
		if mountpoint -q ${ISOMNTDIR}; then
			umount ${ISOMNTDIR} || print_warn "Could not unmount ${ISOMNTDIR}"
		fi
	fi
	
     	rm -rf ${BUILD_DIR} || print_warn "Could not delete ${BUILD_DIR}"
}

####################################################################################################
# Start Script Execution
####################################################################################################
set_env
prep_build_dir
pull_latest_iso
prep_build
build_iso
cleanup

exit 0
