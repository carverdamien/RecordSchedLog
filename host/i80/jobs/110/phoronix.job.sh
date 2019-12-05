#!/bin/bash
export TIMEOUT
export IPANEMA_MODULE
export OUTPUT
export BENCH
export MONITORING
export MONITORING_SCHEDULED
export SYSCTL=''
export PHORONIX PHORONIX_TEST_ARGUMENTS

NO_TURBO=0
TIMEOUT=3600
IPANEMA_MODULE=
BENCH=bench/phoronix
PHORONIXES=(redis mkl-dnn mkl-dnn schbench apache-siege rust-prime apache-siege apache-siege apache-siege apache-siege aobench apache build-llvm build-linux-kernel scimark2 scimark2 scimark2 scimark2 scimark2 scimark2 go-benchmark go-benchmark go-benchmark go-benchmark)
PARGUMENTS=(    1   '7-1'   '7-2'    '6-7'            5          0            4            3            2            1       0      0          0                  0        1        2        3        4        5        6            1            2            3            4)
MONITORING_SCHEDULED=n
KERNEL_LOCALVERSIONS=(lp lp lp schedlog local local-light ipanema delayed-placement)
LP_VALUES=(1 2 0 n n n n n)
SLP=(y y)
GOV=(powersave powersave)
RPT=(1 10)
MON=(monitoring/all monitoring/cpu-energy-meter)

for J in ${!KERNEL_LOCALVERSIONS[@]}
do
    KERNEL_LOCALVERSION=${KERNEL_LOCALVERSIONS[$J]}
    LP_VALUE=${LP_VALUES[$J]}
    case ${LP_VALUE} in
	n)
	    SYSCTL=''
	    ;;
	*)
	    SYSCTL="kernel.sched_local_placement=${LP_VALUE}"
	    ;;
    esac
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
	MONITORING=${MON[$I]}
	for N in $(seq ${REPEAT})
	do
	    for K in ${!PHORONIXES[@]}
	    do
		PHORONIX=${PHORONIXES[$K]}
		PHORONIX_TEST_ARGUMENTS=${PARGUMENTS[$K]}
		OUTPUT="output/"
		OUTPUT+="HOST=${HOSTNAME}/"
		OUTPUT+="BENCH=$(basename ${BENCH})/"
		OUTPUT+="POWER=${SCALING_GOVERNOR}-${SLEEP_STATE}/"
		OUTPUT+="MONITORING=$(basename ${MONITORING})/"
		OUTPUT+="LP=${LP_VALUE}/"
		OUTPUT+="PHORONIX=${PHORONIX}-${PHORONIX_TEST_ARGUMENTS}/"
		OUTPUT+="${KERNEL_LOCALVERSION}/${N}"
		run_bench
	    done
	done
    done
done
