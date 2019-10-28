#!/bin/bash
export TIMEOUT
export IPANEMA_MODULE
export OUTPUT
export BENCH
export MONITORING
export MONITORING_SCHEDULED
export PHORONIX PHORONIX_TEST_ARGUMENTS

NO_TURBO=0
TIMEOUT=3600
IPANEMA_MODULE=
IPANEMA_MODULES="cfs_wwc ule_wwc"
BENCH=bench/phoronix
PHORONIXES=(redis mkl-dnn mkl-dnn schbench apache-siege rust-prime apache-siege apache-siege apache-siege apache-siege aobench apache build-llvm build-linux-kernel)
PARGUMENTS=(    1   '7-1'   '7-2'    '6-7'            5          0            4            3            2            1       0      0          0                  0)
MONITORING=monitoring/all
MONITORING_SCHEDULED=n
KERNEL_LOCALVERSIONS="ipanema"
SLP=(n           y        )
GOV=(performance powersave)
RPT=(1           1        )

for I in ${!SLP[@]}
do
    SLEEP_STATE=${SLP[$I]}
    case ${SLEEP_STATE} in
	y)
	    CMDLINE=intel_sleep_state_enabled
	    ;;
	n)
	    CMDLINE=intel_sleep_state_disabled
	    ;;
	*)
	    echo '${SLEEP_STATE} must be y|n'
	    sleep inf
	    exit 1
    esac
    SCALING_GOVERNOR=${GOV[$I]}
    REPEAT=${RPT[$I]}
    for N in $(seq ${REPEAT})
    do
	for J in ${!PHORONIXES[@]}
	do
	    for KERNEL_LOCALVERSION in ${KERNEL_LOCALVERSIONS}
	    do
		for IPANEMA_MODULE in ${IPANEMA_MODULES}
		do
		    PHORONIX=${PHORONIXES[$J]}
		    PHORONIX_TEST_ARGUMENTS=${PARGUMENTS[$J]}
		    OUTPUT="output/"
		    OUTPUT+="BENCH=$(basename ${BENCH})/"
		    OUTPUT+="POWER=${SCALING_GOVERNOR}-${SLEEP_STATE}/"
		    OUTPUT+="MONITORING=$(basename ${MONITORING})/"
		    OUTPUT+="IPANEMA=$(basename ${IPANEMA_MODULE})/"
		    OUTPUT+="PHORONIX=${PHORONIX}-${PHORONIX_TEST_ARGUMENTS}/"
		    OUTPUT+="${KERNEL_LOCALVERSION}/${N}"
		    run_bench
		done
	    done
	done
    done
done