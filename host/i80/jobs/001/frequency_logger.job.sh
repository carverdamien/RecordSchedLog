#!/bin/bash
export TIMEOUT
export IPANEMA_MODULE
export OUTPUT
export BENCH
export MONITORING
export MONITORING_SCHEDULED
export TASKS
export TARGET
export SYSCTL=''

NO_TURBO=0
TIMEOUT=3600
IPANEMA_MODULE=
BENCH=bench/frequency_logger
MONITORING_SCHEDULED=n
KERNEL_LOCALVERSIONS=(local-cpuofwaker) # local-light-cpuofwaker lp lp lp schedlog local local-light ipanema delayed-placement)
LP_VALUES=(n) # n 1 2 0 n n n n n)
SLP=(y n)
GOV=(powersave performance)
RPT=(2 2)
MON=(monitoring/nop monitoring/nop monitoring/nop)

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
	    OUTPUT="output/"
	    OUTPUT+="HOST=${HOSTNAME}/"
	    OUTPUT+="BENCH=$(basename ${BENCH})/"
	    OUTPUT+="POWER=${SCALING_GOVERNOR}-${SLEEP_STATE}/"
	    OUTPUT+="MONITORING=$(basename ${MONITORING})/"
	    OUTPUT+="LP=${LP_VALUE}/"
	    OUTPUT+="${KERNEL_LOCALVERSION}/${N}"
	    run_bench
	done
    done
done
