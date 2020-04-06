(
    sudo cp "${HOST_KERNEL_SRC}/tools/sched_monitor/sched_monitor" /usr/bin/
    rm -rf "${HOST_KERNEL}/compiler"
    git submodule init "${HOST_KERNEL}/compiler"
    git submodule update --recursive --remote "${HOST_KERNEL}/compiler"
    make -C "${HOST_KERNEL}/compiler" policies-prod
    export KERNEL=${PWD}/${HOST_KERNEL_SRC}
    export KERNELRELEASE=$(cat "${HOST_KERNEL_SRC}/include/config/kernel.release")
    (
	cd "${HOST_KERNEL}/compiler/c-code"
	make
	sudo KERNELRELEASE=${KERNELRELEASE} make install
    )
)
