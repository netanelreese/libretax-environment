#!/bin/bash

set -e

VOLUME_NAME="LIBRETAX-RH9"
OUTPUT_ISO="./${VOLUME_NAME}.iso"
ISOWORKDIR="./workdir"

# Create the new ISO with xorriso
build_iso() {    
	xorriso -as mkisofs -U -r -v -J -V ${VOLUME_NAME} -volset ${VOLUME_NAME} -A ${VOLUME_NAME} \
                -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 \
    	        -boot-info-table --eltorito-alt-boot -e images/efiboot.img -no-emul-boot \
    	        -o "$OUTPUT_ISO" "${ISOWORKDIR}"

if [ $? -ne 0 ]; then
    print_error "Failed to create the ISO\n"
    sudo umount "$MOUNT_DIR"
    exit 1
fi
}

exit 0
