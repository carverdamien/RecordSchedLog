#!/bin/bash
set -e -u
. .lib.sh
check_args() {
    : ${HOST_KERNEL:=$1}
    host_kernel > /dev/null
    if host_kernel_installed > /dev/null
    then
	echo "${HOST_KERNEL} already installed"
	echo "To reinstall: rm -rf /{boot,lib/modules}/*$(host_kernel_installed)*"
	exit 0
    fi
    HOST_KERNEL_SRC=$(host_kernel_src)
    HOST_KERNEL_CONFIG=$(host_kernel_config)
    KERNEL_LOCALVERSION=$(host_kernel_localversion)
    ! test -f "${HOST_KERNEL_SRC}/vmlinux"
}
clean() {
    rm -rf "${HOST_KERNEL_SRC}"
}
prepare_src() {
    git submodule init "${HOST_KERNEL_SRC}"
    # git submodule sync --recursive "${HOST_KERNEL_SRC}"
    git submodule update --recursive --remote "${HOST_KERNEL_SRC}"
    cp "${HOST_KERNEL_CONFIG}" "${HOST_KERNEL_SRC}/.config"
}
kbuild() {
    (
	export LOCALVERSION="-${KERNEL_LOCALVERSION}"
	make -C "${HOST_KERNEL_SRC}" -j $(($(nproc)*2))
    )
}
install() {
    (
	kernelrelease=$(cat "${HOST_KERNEL_SRC}/include/config/kernel.release")
	sudo rm -rf /boot/{config,initrd.img,System.map,vmlinuz}-${kernelrelease} /lib/modules/${kernelrelease}
	sudo make -C "${HOST_KERNEL_SRC}" INSTALL_MOD_STRIP=1 modules_install install
	(
	    cd "${HOST_KERNEL_SRC}/tools/perf"
	    make clean
	    make
	    sudo mkdir -p /usr/lib/linux-tools/${kernelrelease}
	    sudo cp perf /usr/lib/linux-tools/${kernelrelease}/
	)
	sched_log_tool="${HOST_KERNEL_SRC}/tools/sched_monitor/sched_log"
	if test -f "${sched_log_tool}"
	then
	    sudo cp "${sched_log_tool}" /usr/bin/
	fi
    )
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
