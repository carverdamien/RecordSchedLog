#!/bin/bash
host_kernel() {
    HOST_KERNEL="$1"
    pat='host/([^/]+)/kernel/([^/]+)'
    [[ $HOST_KERNEL =~ $pat ]]
    HOST="${BASH_REMATCH[1]}"
    [ "${HOSTNAME}" = "${HOST}" ]
    export LOCALVERSION="-${BASH_REMATCH[2]}"
    test -d "${HOST_KERNEL}"
    KCONFIG_ORG="${HOST_KERNEL}/.config"
    test -f "${KCONFIG_ORG}"
    HOST_KERNEL_SRC="${HOST_KERNEL}/src"
    grep -q "${HOST_KERNEL_SRC}" .gitmodules
}
list_kernel_installed() {
    vmlinuz_pat='/boot/vmlinuz-([0-9]+).([0-9]+).([0-9]+)(.+)-g(.*)'
    for vmlinuz in /boot/vmlinuz-*
    do
	[[ $vmlinuz =~ $vmlinuz_pat ]] || continue
	version="${BASH_REMATCH[1]}"
	patchlevel="${BASH_REMATCH[2]}"
	sublevel="${BASH_REMATCH[3]}"
	localversion="${BASH_REMATCH[4]}"
	commit="${BASH_REMATCH[5]}"
	kernelrelease="${version}.${patchlevel}.${sublevel}${localversion}-g${commit}"
	[[ -f "/boot/config-${kernelrelease}" ]] || continue
	[[ -f "/boot/initrd.img-${kernelrelease}" ]] || continue
	[[ -f "/boot/System.map-${kernelrelease}" ]] || continue
	[[ -f "/boot/vmlinuz-${kernelrelease}" ]] || continue
	[[ -d "/lib/modules/${kernelrelease}" ]] || continue
	echo "${kernelrelease}"
    done
}
