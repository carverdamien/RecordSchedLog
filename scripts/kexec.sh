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
record_attempt_to_reboot() {
    echo "${CMDLINE}" | sudo tee /boot/.kexec_reboot_attempt > /dev/null
}
last_attempt_to_reboot_failed() {
    ( ! [ -f /boot/.kexec_reboot_attempt ] ) || [ "${CMDLINE}" = "$(cat /boot/.kexec_reboot_attempt)" ]
}
main() {
    check_args "${@}"
    CURRENT_CMDLINE="$(cat /proc/cmdline)"
    if [ "${CMDLINE}" != "${CURRENT_CMDLINE}" ]
    then
	# Need to reboot
	if last_attempt_to_reboot_failed
	then
	    # Avoid infinite reboot attempts
	    echo 'last_attempt_to_reboot_failed'
	    sleep inf
	else
	    record_attempt_to_reboot
	    sudo kexec -l "${BOOT_IMAGE}" --command-line="${CMDLINE}" --initrd="${INITRD}"
	    sudo kexec -e
	fi
    fi
}
main "${@}"
