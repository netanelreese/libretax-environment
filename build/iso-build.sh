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
source $(cd .. && pwd)/pkg/lt_env/SOURCE/lt.env

set -e

if [[ "$EUID" -ne 0 ]]; then
   print_error "This script must be run as root." >&2
   exit 1
fi

####################################################################################################
# Start Global Member Assignment
####################################################################################################

REPO_DIR="$(cd .. && pwd)"
KS_DIR="${REPO_DIR}/ks"
GRUB_FILE="${REPO_DIR}/grub/lt_grub.cfg"
KS_DEST="${BUILD_DIR}/ks"
GRUB_DEST="${BUILD_DIR}/EFI/BOOT/grub.cfg"
EXTRA_FILES="${BUILD_DIR}/extra_files.json"
PKG_DEST="${BUILD_DIR}/LibreTax"
ISO_SRC="https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-dvd1.iso"
SRC_ISO="CentOS-Stream-9-latest-x86_64-dvd1.iso"
ISO_MD5="https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-dvd1.iso.MD5SUM"
ISO_SHA1="https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-dvd1.iso.SHA1SUM"
ISO_SHA256="https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-dvd1.iso.SHA256SUM"
VOLUME_NAME="LIBRETAX-RH9"
BUILD_DIR="/tmp/LIBRETAX-BUILD-$(date +'%Y%m%d_%H%M%S')"
ARTIFACT_DIR="/tmp/LIBRETAX-ARTIFACT-$(date +'%Y%m%d_%H%M%S')"
OUTPUT_ISO="${ARTIFACT_DIR}/${VOLUME_NAME}.iso"
ISOWORKDIR="${BUILD_DIR}/workdir"
ISOMNTDIR="${BUILD_DIR}/mnt"

####################################################################################################
# Start Function Definitions
####################################################################################################

exception() {
	print_error $@
 	cleanup
  	exit 1
}

# Creates the directory used to build
prep_build_dir() {
	print_info "Creating temp build directory at ${BUILD_DIR}"
	mkdir -p "${ISOWORKDIR}" || exception "Could not create ${ISOWORKDIR}"
 	mkdir -p "${ISOMNTDIR}" || exception "Could not create ${ISOMNTDIR}"
	print_success "Build Directory Created: ${BUILD_DIR}"
}

# Pulls latest x64 iso from cent mirror
pull_latest_iso() {
	print_info "Pulling Latest Cent Stream 9 ISO"
	curl "${ISO_SRC}" -o "${BUILD_DIR}/${SRC_ISO}" || exception "Could not pull latest CentOS iso"
 	print_info "Pulling Latest Cent Stream 9 checksums (MD5, SHA1, SHA256)"
 	curl "${ISO_MD5}" -o "${BUILD_DIR}/${SRC_ISO}.MD5SUM" || exception "Could not pull latest CentOS iso MD5 checksum"
	curl "${ISO_SHA1}" -o "${BUILD_DIR}/${SRC_ISO}.SHA1SUM" || exception "Could not pull latest CentOS iso SHA1 checksum"
 	curl "${ISO_SHA256}" -o "${BUILD_DIR}/${SRC_ISO}.SHA256SUM" || exception "Could not pull latest CentOS iso SHA256 checksum"

 	# Verify Checksums
  	print_info "Verifying Checksums"
  	pushd "${BUILD_DIR}"
	md5sum -c "${SRC_ISO}".MD5SUM || exception "MD5 CHECKSUM DOES NOT MATCH"
 	sha1sum -c "${SRC_ISO}".SHA1SUM || exception "SHA1 CHECKSUM DOES NOT MATCH"
  	sha256sum -c "${SRC_ISO}".SHA256SUM || exception "SHA256 CHECKSUM DOES NOT MATCH"
   	print_success "Checksums Verified!"
   	popd
}

prep_build() {
	print_info "Mounting ${SRC_ISO} to ${ISOMNTDIR}" 
 	mount "${BUILD_DIR}/${SRC_ISO}" "${ISOMNTDIR}" || exception "Failed to mount source iso"
  	print_info "Copying contents of ${SRC_ISO} to ${ISOWORKDIR}"
   	cp -rf "${ISOMNTDIR}/*" "${ISOWORKDIR}" || exception "Failed to copy iso contents"

  	print_info "Creating kickstart and custom package dirs in working directory"
	mkdir -p "${KS_DEST}" || exception "Could not create ${KS_DEST}"
	mkdir -p "${PKG_DEST}" || exception "Could not create ${PKG_DEST}"

 	print_info "Copying ${GRUB_FILE} to ${GRUB_DEST}"
 	cp -f "${GRUB_FILE}" "${GRUB_DEST}" || exception "Could not copy ${GRUB_FILE}"

  	print_info "Copying kickstarts to ${KS_DEST}"
   	cp -f "${KS_DIR}/*-ks.cfg" "${KS_DEST}" || exception "Could not copy host kickstarts"
    	cp -rf "${KS_DIR}/common" "${KS_DEST}" || exception "Could not copy common kickstarts"
     
     	print_warn "Packages not implemented yet"
	print_warn "This is where the rpm-build script would be called"
 	print_warn "This is where the package copying would be called"

	create_ef
	print_success "LibreTax ISO ready to create!"
}

create_ef() {
	tmp_ef="./extra_files_tmp.json"
 	tmp_ef=$(realpath ${tmp_ef})
 	print_info "Creating extra_files.json"

 	# Copy license and EULA from the existing file.
  	head -n 19 ${EXTRA_FILES} >> ${tmp_ef} || exception "Could not create temp json with header"

 	pushd "${BUILD_DIR}"
   	# make entries for kickstarts
    	for ks in $(find ks/ -name "*.cfg"); do
		local md5=$(md5sum ${ks} | awk '{print $1}')
  		local sha1=$(sha1sum ${ks} | awk '{print $1}')
    		local sha256=$(sha256sum ${ks} | awk '{print $1}')
      		local path="${ks}"
		local size=$(ls -lp "${ks}" | grep -v '/$' | awk '{print $5}' | tr -d '[:space:]')
		print_info "Kickstart ${ks}: Size: ${size}, SHA256: ${sha256}, SHA1: ${sha1}, MD5: ${md5}"
cat << EOF >> ${tmp_ef}
        },
        {
            "checksums": {
                "md5": "${md5}",
	  	"sha1": "${sha1}",
     		"sha256": "${sha256}"
	     },
             "file": "${path}",
	     "size": ${size}
EOF
     	done

 	# Do Custom Packages
      	for pkg in $(ls -p ${PKG_DEST} | grep -v '/$'); do
		local md5=$(md5sum ${PKG_DEST}/${pkg} | awk '{print $1}')
  		local sha1=$(sha1sum ${PKG_DEST}/${pkg} | awk '{print $1}')
    		local sha256=$(sha256sum ${PKG_DEST}/${pkg} | awk '{print $1}')
      		local path="pkg/${pkg}"
		local size=$(ls -lp pkg/"${pkg}" | grep -v '/$' | awk '{print $5}' | tr -d '[:space:]')
                print_info "Package ${pkg}: Size: ${size}, SHA256: ${sha256}, SHA1: ${sha1}, MD5: ${md5}"
cat << EOF >> "${tmp_ef}" 
        },
        {
            "checksums": {
                "md5": "${md5}",
	  	"sha1": "${sha1}",
     		"sha256": "${sha256}"
	     },
             "file": "${path}",
	     "size": ${size}
EOF
	done

# End of the json.
	tail -n 6 ${EXTRA_FILES} >> ${tmp_ef}
	
	cat ${tmp_ef}

 	mv -f ${tmp_ef} ${EXTRA_FILES}

	cat ${EXTRA_FILES}

 	popd
  	print_success "Creation of extra_file.json successful!"
}

# Create the new ISO with xorriso
build_iso() {
	mkdir -p "${ARTIFACT_DIR}"

	xorriso -as mkisofs -U -r -v -J -V ${VOLUME_NAME} -volset ${VOLUME_NAME} -A ${VOLUME_NAME} \
                -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 \
    	        -boot-info-table --eltorito-alt-boot -e images/efiboot.img -no-emul-boot \
    	        -o "${OUTPUT_ISO}" "${ISOWORKDIR}"

	if [ $? -ne 0 ]; then
	    exception "Failed to create ${OUTPUT_ISO}"
	fi

 	print_success "LibreTax ISO Successfully Created!"
  	print_success "Located at: ${OUTPUT_ISO}"
}

# Cleans up tmp build directory
cleanup() {
	if [[ -d "${ISOMNTDIR}" ]]; then
		if mountpoint -q ${ISOMNTDIR}; then
			umount ${ISOMNTDIR} || print_warn "Could not unmount ${ISOMNTDIR}"
		fi
	fi
	
	rm -rf ${BUILD_DIR} || print_warn "Could not delete ${BUILD_DIR}"
	print_success "Temporary Build Dir Cleaned!"
}

####################################################################################################
# Start Script Execution
####################################################################################################
echo -e "${BIGREEN}Starting LibreTax ISO Build...${NC}"
prep_build_dir
pull_latest_iso
prep_build
build_iso
cleanup

exit 0
