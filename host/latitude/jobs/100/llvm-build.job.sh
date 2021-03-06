#!/bin/bash
export TIMEOUT
export IPANEMA_MODULE
export OUTPUT
export BENCH
export MONITORING
export MONITORING_SCHEDULED
export SYSCTL=''

NO_TURBO=0
TIMEOUT=3600
IPANEMA_MODULE=
BENCH=bench/llvmcmake
MONITORING_SCHEDULED=n
KERNEL_LOCALVERSIONS=(5.4-fdp lp delayed-placement-idle local)
LP_VALUES=(n 0 n n)
SLP=(y y)
GOV=(powersave schedutil)
RPT=(10 10)
MON=(monitoring/cpu-energy-meter monitoring/cpu-energy-meter)

for J in ${!KERNEL_LOCALVERSIONS[@]}
do
    KERNEL_LOCALVERSION=${KERNEL_LOCALVERSIONS[$J]}
    LP_VALUE=${LP_VALUES[$J]}
    case ${LP_VALUE} in
	n)
	    SYSCTL=''
	    ;;
	*)
	    if [ ${KERNEL_LOCALVERSION} == "delayed-placement" ] ; then
		SYSCTL="kernel.sched_delayed_placement=${LP_VALUE}"
	    else
		SYSCTL="kernel.sched_local_placement=${LP_VALUE}"
	    fi
	    ;;
    esac
    for I in ${!SLP[@]}
    do
	SLEEP_STATE=${SLP[$I]}
	SCALING_GOVERNOR=${GOV[$I]}
	REPEAT=${RPT[$I]}
	MONITORING=${MON[$I]}
	case ${SLEEP_STATE} in
	    y)
		case ${SCALING_GOVERNOR} in
		    schedutil)
			CMDLINE=intel_sleep_state_enabled_pstate_passive
			;;
		    *)
			CMDLINE=intel_sleep_state_enabled
			;;
		esac
		;;
	    n)
		CMDLINE=intel_sleep_state_disabled
		;;
	    *)
		echo '${SLEEP_STATE} must be y|n'
		sleep inf
		exit 1
	esac
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
