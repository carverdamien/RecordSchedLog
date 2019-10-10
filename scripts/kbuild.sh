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
    ! test -f "${HOST_KERNEL_SRC}/vmlinux" || (
	echo "There is a ${HOST_KERNEL_SRC}/vmlinux"
	echo "rm -rf ${HOST_KERNEL_SRC}"
	exit 1
    )
}
clean() {
    rm -rf "${HOST_KERNEL_SRC}"
}
prepare_src() {
    git submodule init "${HOST_KERNEL_SRC}"
    git submodule sync --recursive "${HOST_KERNEL_SRC}"
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
	if test -f "${HOST_KERNEL}/kbuild-post-install-hook.sh"
	then
	    source "${HOST_KERNEL}/kbuild-post-install-hook.sh"
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
