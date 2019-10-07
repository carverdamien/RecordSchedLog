#!/bin/bash
set -e -u -x
. .lib.sh
check_args() {
    host_kernel "$1"
    ! test -f "${HOST_KERNEL_SRC}/vmlinux"
}
clean() {
    rm -rf "${HOST_KERNEL_SRC}"
}
prepare_src() {
    git submodule init "${HOST_KERNEL_SRC}"
    # git submodule sync --recursive "${HOST_KERNEL_SRC}"
    git submodule update --recursive --remote "${HOST_KERNEL_SRC}"
    cp "${KCONFIG_ORG}" "${HOST_KERNEL_SRC}/.config"
    VERSION=$(sed -n 's/^VERSION *= *\([^ ]\+\)/\1/p' "${HOST_KERNEL_SRC}/Makefile")
    PATCHLEVEL=$(sed -n 's/^PATCHLEVEL *= *\([^ ]\+\)/\1/p' "${HOST_KERNEL_SRC}/Makefile")
    SUBLEVEL=$(sed -n 's/^SUBLEVEL *= *\([^ ]\+\)/\1/p' "${HOST_KERNEL_SRC}/Makefile")
    pat="/boot/vmlinuz-${VERSION}.${PATCHLEVEL}.${SUBLEVEL}${LOCALVERSION}-g"
    pat+='(.*)'
    COMMIT=$(git submodule status "${HOST_KERNEL_SRC}" | awk '{print $1}')
    for VMLINUZ in /boot/vmlinuz-*
    do
	[[ $VMLINUZ =~ $pat ]] || continue
	commitpat="${BASH_REMATCH[1]}"
	commitpat+='(.*)'
	[[ $COMMIT =~ $commitpat ]] || continue
	echo "$VMLINUZ matches commit $COMMIT."
	echo "Assuming ${HOST_KERNEL_SRC} is already installed."
	echo "To reinstall: rm -rf /{boot,lib/modules}/*${VERSION}.${PATCHLEVEL}.${SUBLEVEL}${LOCALVERSION}-g*"
	exit 0
    done
}
kbuild() {
    make -C "${HOST_KERNEL_SRC}" -j $(($(nproc)*2))
}
install() {
    KERNELRELEASE=$(cat "${HOST_KERNEL_SRC}/include/config/kernel.release")
    sudo rm -rf /boot/{config,initrd.img,System.map,vmlinuz}-${KERNELRELEASE} /lib/modules/${KERNELRELEASE}
    sudo make -C "${HOST_KERNEL_SRC}" INSTALL_MOD_STRIP=1 modules_install install
    (
	cd "${HOST_KERNEL_SRC}/tools/perf"
	make clean
	make
	sudo mkdir -p /usr/lib/linux-tools/${KERNELRELEASE}
	sudo cp perf /usr/lib/linux-tools/${KERNELRELEASE}/
    )
    SCHED_LOG_TOOL="${HOST_KERNEL_SRC}/tools/sched_monitor/sched_log"
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
    git checkout "${HOST_KERNEL_SRC}"
}
main "${@}"
