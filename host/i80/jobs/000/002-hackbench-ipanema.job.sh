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

export PERF_STAT_OPT='-e mem_load_uops_l3_miss_retired.local_dram -e mem_load_uops_l3_miss_retired.remote_dram'
export TRACECMD_RECORD_OPT="-e sched -b $((2**20))"

NO_TURBO=0
TIMEOUT=3600
IPANEMA_MODULE=
BENCH=bench/hackbench
MONITORING_SCHEDULED=n

KERNEL_LOCALVERSION=ipanema-eurosys2020
SLEEP_STATE=n
SCALING_GOVERNOR=performance

IPANEMA_MODULES=()
REPEATS=()
MONITORINGS=()

# # trace-cmd first
# for ipa in '' cfs_wwc ule_wwc
# do
#     IPANEMA_MODULES+=("$ipa")
#     REPEATS+=(1)
#     MONITORINGS+=(monitoring/trace-cmd)
# done
# SchedLog first
# for ipa in cfs_wwc # '' cfs_wwc_flat ule_wwc ule
# do
#    IPANEMA_MODULES+=("$ipa")
#    REPEATS+=(6)
#    MONITORINGS+=(monitoring/SchedLog)
# done
# # perf_stat
# for ipa in '' cfs_wwc ule_wwc ule_wwc_rip ule_rip ule
# do
#     IPANEMA_MODULES+=("$ipa")
#     REPEATS+=(10)
#     MONITORINGS+=(monitoring/perf_stat)
# done
# nop last
for ipa in '' cfs_cwc_ipa cfs_cwc_flat_ipa ule_ipa # ule_wwc_2 #'' # cfs_wwc ule_wwc ule cfs_wwc_flat
# 	   # ule_wwc_rip ule_rip
do
     IPANEMA_MODULES+=("$ipa")
     REPEATS+=(10)
     MONITORINGS+=(monitoring/nop)
done

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
        for TASKS in 10000 # 40 8000 6000 4000 2000 1000
        do
            OUTPUT="output/"
            OUTPUT+="HOST=${HOSTNAME}/"
            OUTPUT+="BENCH=$(basename ${BENCH})/"
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
