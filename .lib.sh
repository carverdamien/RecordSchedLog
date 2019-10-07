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
