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

PERF_STAT_OPT='-e mem_load_uops_l3_miss_retired.local_dram -e mem_load_uops_l3_miss_retired.remote_dram'
NO_TURBO=0
TIMEOUT=3600
IPANEMA_MODULE=
BENCH=bench/nas
BENCH_NAMES=(   bt cg ep ft    lu mg sp ua ) # ua sp dc # is
BENCH_CLASSES=( B  C  C  C     B  D  B  B  )  # C  A  A  # D
MONITORING_SCHEDULED=n
KERNEL_LOCALVERSIONS=(ipanema)

SLEEP_STATE=n
SCALING_GOVERNOR=performance
REPEAT=10
MONITORING=monitoring/perf_stat

for J in ${!KERNEL_LOCALVERSIONS[@]}
do
    KERNEL_LOCALVERSION=${KERNEL_LOCALVERSIONS[$J]}
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
                OUTPUT+="MONITORING=perf_stat.mem_load_uops_l3_miss_retired/"
                OUTPUT+="TASKS=${TASKS}/"
		OUTPUT+="KERNEL=${KERNEL_LOCALVERSION}/${N}"
                run_bench
            done
        done
    done
done
