#!/bin/bash
export TIMEOUT
export IPANEMA_MODULE
export OUTPUT
export BENCH
export BENCH_NAME
export BENCH_CLASS
export MONITORING
export MONITORING_SCHEDULED
export MONITORING_START_DELAY
export MONITORING_STOP_DELAY
export TASKS
export SYSCTL=''

export TRACECMD_RECORD_OPT="-e sched -b $((2**20))"

NO_TURBO=0
TIMEOUT=3600
IPANEMA_MODULE=
BENCH=bench/nas
BENCH_NAMES=(   bt cg ep ft    lu mg sp ua is dc) # ua sp dc # is
BENCH_CLASSES=( B  C  C  C     B  D  B  B  A  A)  # C  A  A  # D
MONITORING_SCHEDULED=n

KERNEL_LOCALVERSION=ipanema
SLEEP_STATE=n
SCALING_GOVERNOR=performance

IPANEMA_MODULES=('' '')
REPEATS=(1 10)
MONITORINGS=(monitoring/trace-cmd monitoring/nop)

for J in ${!IPANEMA_MODULES[@]}
do
    IPANEMA_MODULE=${IPANEMA_MODULES[$J]}
    REPEAT=${REPEATS[$J]}
    MONITORING=${MONITORINGS[$J]}
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
        for I in ${!BENCH_NAMES[@]}
        do
            for TASKS in 160 80 # 320
            do
                BENCH_NAME=${BENCH_NAMES[$I]}
                BENCH_CLASS=${BENCH_CLASSES[$I]}

                OUTPUT="output/"
                OUTPUT+="HOST=${HOSTNAME}/"
                OUTPUT+="BENCH=$(basename ${BENCH})_${BENCH_NAME}.${BENCH_CLASS}/"
                OUTPUT+="POWER=${SCALING_GOVERNOR}-${SLEEP_STATE}/"
                OUTPUT+="MONITORING=$(basename ${MONITORING})/"
                OUTPUT+="TASKS=${TASKS}/"
		OUTPUT+="KERNEL=${KERNEL_LOCALVERSION}/"
		OUTPUT+="IPANEMA_MODULE=${IPANEMA_MODULE}/"
		OUTPUT+="${N}"
                run_bench
            done
        done
    done
done
