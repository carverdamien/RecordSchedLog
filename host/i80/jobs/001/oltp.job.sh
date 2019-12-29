#!/bin/bash
export TIMEOUT
export IPANEMA_MODULE
export OUTPUT
export BENCH
export MONITORING
export MONITORING_SCHEDULED
export MONITORING_START_DELAY
export MONITORING_STOP_DELAY
export TASKS
export SYSCTL=''

NO_TURBO=0
TIMEOUT=3600
IPANEMA_MODULE=
BENCH=bench/oltp-mysql
MONITORING_SCHEDULED=y
MONITORING_START_DELAY=60
MONITORING_STOP_DELAY=10
KERNEL_LOCALVERSIONS=(lp lp lp schedlog local delayed-placement dpi dp2)
LP_VALUES=(1 2 0 n n n n n)
SLP=(y)
GOV=(powersave)
RPT=(10)
MON=(monitoring/cpu-energy-meter)

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
            for TASKS in 80 160 320 512 1024
            do
                OUTPUT="output/"
		OUTPUT+="HOST=${HOSTNAME}/"
		OUTPUT+="BENCH=$(basename ${BENCH})/"
		OUTPUT+="POWER=${SCALING_GOVERNOR}-${SLEEP_STATE}/"
		OUTPUT+="MONITORING=$(basename ${MONITORING})/"
		OUTPUT+="LP=${LP_VALUE}/"
		OUTPUT+="${TASKS}-${KERNEL_LOCALVERSION}/${N}"
	        run_bench
            done
        done
    done
done
