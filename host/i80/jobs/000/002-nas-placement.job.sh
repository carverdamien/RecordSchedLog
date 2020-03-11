#!/bin/bash
export TIMEOUT
export IPANEMA_MODULE
export OUTPUT
export BENCH
export BENCH_NAME
export BENCH_CLASS
export OMP_PLACES
export OMP_PROC_BIND=true
export OMP_DISPLAY_ENV=true
export MONITORING
export MONITORING_SCHEDULED
export MONITORING_START_DELAY
export MONITORING_STOP_DELAY
export TASKS
export SYSCTL=''

export PERF_STAT_OPT='-e mem_load_uops_l3_miss_retired.local_dram -e mem_load_uops_l3_miss_retired.remote_dram'
export TRACECMD_RECORD_OPT="-e sched -b $((2**20))"

NO_TURBO=0
TIMEOUT=3600
IPANEMA_MODULE=
BENCH=bench/nas

BENCH_NAMES=(cg)
BENCH_CLASSES=(C)
BENCH_TASKS=(160)
BENCH_PLACEMENT=(host/${HOSTNAME}/omp_places/160places_on_node1)

MONITORING_SCHEDULED=n

KERNEL_LOCALVERSION=ipanema
SLEEP_STATE=n
SCALING_GOVERNOR=performance

IPANEMA_MODULES=()
REPEATS=()
MONITORINGS=()

# trace-cmd first
# for ipa in ''
# do
#     IPANEMA_MODULES+=("$ipa")
#     REPEATS+=(1)
#     MONITORINGS+=(monitoring/trace-cmd)
# done
# SchedLog first
for ipa in ''
do
    IPANEMA_MODULES+=("$ipa")
    REPEATS+=(1)
    MONITORINGS+=(monitoring/SchedLog)
done
# perf_stat
# for ipa in ''
# do
#     IPANEMA_MODULES+=("$ipa")
#     REPEATS+=($MAX_RPT)
#     MONITORINGS+=(monitoring/perf_stat)
# done
# nop last
# for ipa in ''
# do
#     IPANEMA_MODULES+=("$ipa")
#     REPEATS+=($MAX_RPT)
#     MONITORINGS+=(monitoring/nop)
# done

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
            BENCH_NAME=${BENCH_NAMES[$I]}
            BENCH_CLASS=${BENCH_CLASSES[$I]}
	    TASKS=${BENCH_TASKS[$I]}
	    OMP_PLACES=$(cat ${BENCH_PLACEMENT[$I]})
            OUTPUT="output/"
            OUTPUT+="HOST=${HOSTNAME}/"
            OUTPUT+="BENCH=$(basename ${BENCH})_${BENCH_NAME}.${BENCH_CLASS}/"
            OUTPUT+="POWER=${SCALING_GOVERNOR}-${SLEEP_STATE}/"
            OUTPUT+="MONITORING=$(basename ${MONITORING})/"
            OUTPUT+="TASKS=${TASKS}/"
	    OUTPUT+="KERNEL=${KERNEL_LOCALVERSION}/"
	    OUTPUT+="IPANEMA_MODULE=${IPANEMA_MODULE}/"
	    OUTPUT+="OMP_PLACES=$(basename ${BENCH_PLACEMENT[$I]})/"
	    OUTPUT+="${N}"
            run_bench
        done
    done
done
