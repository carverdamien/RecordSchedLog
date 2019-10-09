#!/bin/bash
HOST_KERNEL_PAT='host/([^/]+)/kernel/([^/]+)'
list_kernel_installed() {
    (
	set -e -u
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
	return 0
    )
}
host_kernel_localversion() {
    (
	set -e -u
	: ${HOST_KERNEL:=$1}
	if ! [[ ${HOST_KERNEL} =~ ${HOST_KERNEL_PAT} ]]
	then
	    return 1
	fi
	host_kernel_localversion="${BASH_REMATCH[2]}"
	echo "${host_kernel_localversion}"
	return 0
    )
}
host_kernel_config() {
    (
	set -e -u
	host_kernel="${HOST_KERNEL:=$1}"
	if ! [[ $host_kernel =~ ${HOST_KERNEL_PAT} ]]
	then
	    return 1
	fi
	host_kernel_config="${HOST_KERNEL}/.config"
	test -f "${host_kernel_config}"
	echo "${host_kernel_config}"
	return 0
    )
}
host_kernel_src() {
    (
	set -e -u
	: ${HOST_KERNEL:=$1}
	if ! [[ ${HOST_KERNEL} =~ ${HOST_KERNEL_PAT} ]]
	then
	    return 1
	fi
	host_kernel_src="${HOST_KERNEL}/src"
	if ! grep -q "${host_kernel_src}" .gitmodules
	then
	    return 1
	fi
	echo "${host_kernel_src}"
	return 0
    )
}
host_kernel_commit() {
    (
	set -e -u
	: ${HOST_KERNEL:=$1}
	if ! [[ ${HOST_KERNEL} =~ ${HOST_KERNEL_PAT} ]]
	then
	    return 1
	fi
	host_kernel_src=$(host_kernel_src)
	git submodule status "${host_kernel_src}" | awk '{print $1}'
	return 0
    )
}
host_kernel() {
    (
	set -e -u
	: ${HOST_KERNEL:=$1}
	if ! test -d "${HOST_KERNEL}"
	then
	    return 1
	fi
	if ! [[ ${HOST_KERNEL} =~ ${HOST_KERNEL_PAT} ]]
	then
	    return 1
	fi
	host="${BASH_REMATCH[1]}"
	if ! [ "${HOSTNAME}" = "${host}" ]
	then
	    return 1
	fi
	echo "${HOST_KERNEL}"
	return 0
    )
}
__host_kernel_installed() {
    # List kernel installed that maches $1
    (
	set -e -u
	: ${HOST_KERNEL:=$1}
	host_kernel_localversion=$(host_kernel_localversion "${HOST_KERNEL}")
	host_kernel_commit=$(host_kernel_commit "${HOST_KERNEL}")
	kernelrelease_pat="([0-9]+).([0-9]+).([0-9]+)-(.+)-g(.*)"
	for kernelrelease in $(list_kernel_installed)
	do
	    [[ ${kernelrelease} =~ ${kernelrelease_pat} ]]
	    version="${BASH_REMATCH[1]}"
	    patchlevel="${BASH_REMATCH[2]}"
	    sublevel="${BASH_REMATCH[3]}"
	    localversion="${BASH_REMATCH[4]}"
	    commit="${BASH_REMATCH[5]}"
	    host_kernel_commit_pat="${commit}.*"
	    [[ ${localversion} = ${host_kernel_localversion} ]] || continue
	    [[ ${host_kernel_commit} =~ ${host_kernel_commit_pat} ]] || continue
	    echo "${kernelrelease}"
	done
	return 0
    )
}
host_kernel_installed() {
    (
	set -e -u
	: ${HOST_KERNEL:=$1}
	if __host_kernel_installed | wc -l | xargs test 1 -ne
	then
	    return 1
	fi
	__host_kernel_installed
	return 0
    )
}
