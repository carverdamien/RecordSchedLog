#!/bin/bash
set -e -u -x
check_args() {
    DIR="$1"
    pat='host/([^/]+)/kernel/([^/]+)'
    [[ $DIR =~ $pat ]]
    HOST="${BASH_REMATCH[1]}"
    [ "${HOSTNAME}" = "${HOST}" ]
    export LOCALVERSION="-${BASH_REMATCH[2]}"
    test -d "${DIR}"
    KCONFIG_ORG="${DIR}/.config"
    test -f "${KCONFIG_ORG}"
    DIR_SRC="${DIR}/src"
    grep -q "${DIR_SRC}" .gitmodules
    ! test -f "${DIR_SRC}/vmlinux"
}
clean() {
    rm -rf "${DIR_SRC}"
}
prepare_src() {
    git submodule init "${DIR_SRC}"
    git submodule sync --recursive "${DIR_SRC}"
    git submodule update --recursive --remote "${DIR_SRC}"
    cp "${KCONFIG_ORG}" "${DIR_SRC}/.config"
}
kbuild() {
    make -C "${DIR_SRC}" -j $(($(nproc)*2))
}
install() {
    KERNELRELEASE=$(cat "${DIR_SRC}/include/config/kernel.release")
    rm -rf /boot/{config,initrd.img,System.map,vmlinuz}-${KERNELRELEASE} /lib/modules/${KERNELRELEASE}
    sudo make -C "${DIR_SRC}" INSTALL_MOD_STRIP=1 modules_install install
    (
	cd "${DIR_SRC}/tools/perf"
	make clean
	make
	sudo mkdir -p /usr/lib/linux-tools/${KERNELRELEASE}
	sudo cp perf /usr/lib/linux-tools/${KERNELRELEASE}/
    )
    SCHED_LOG_TOOL="${DIR_SRC}/tools/sched_monitor/sched_log"
    if test -f "${SCHED_LOG_TOOL}"
    then
	sudo cp "${SCHED_LOG_TOOL}" /usr/bin/
    fi
}
main() {
    check_args "${@}"
    clean
    prepare_src
    kbuild
    install
    clean
    git checkout "${DIR_SRC}"
}
main "${@}"
