#!/bin/bash
set -e -u -x
. .lib.sh
check_args() {
    : ${HOST_KERNEL:=$1}
    : ${HOST_APPEND:=$2}
    host_kernel > /dev/null
    if ! host_kernel_installed > /dev/null
    then
	echo "${HOST_KERNEL} not installed"
	echo "run ./kbuild.sh ${HOST_KERNEL}"
	exit 1
    fi
    KERNELRELEASE=$(host_kernel_installed)
    APPEND=$(cat "${HOST_APPEND}")
    BOOT_IMAGE="/boot/vmlinuz-${KERNELRELEASE}"
    INITRD="/boot/initrd.img-${KERNELRELEASE}"
    test -f "${BOOT_IMAGE}"
    test -f "${INITRD}"
    CMDLINE="BOOT_IMAGE=${BOOT_IMAGE} ${APPEND}"
}
main() {
    check_args "${@}"
    echo sudo kexec -l "${BOOT_IMAGE}" --command-line="${CMDLINE}" --initrd="${INITRD}"
    echo sudo kexec -e
}
main "${@}"
