#!/bin/bash
export TIMEOUT
export IPANEMA_MODULE
export OUTPUT
export BENCH
export MONITORING
export MONITORING_SCHEDULED
export TASKS
export SYSCTL=''

export DO_NOT_UNSHARE=y
NO_TURBO=0
TIMEOUT=3600
IPANEMA_MODULE=
BENCH=bench/hackbench
MONITORING_SCHEDULED=n
SLP=(y)
GOV=(powersave)
RPT=(10)

KERNEL_LOCALVERSIONS=(5.4-linux 5.4-linux)
MON=(monitoring/nop monitoring/perf_sched_record)

KERNEL_LOCALVERSIONS+=(schedlog schedlog schedlog)
MON+=(monitoring/nop monitoring/perf_sched_record monitoring/SchedLog)

KERNEL_LOCALVERSIONS+=(schedlog_bigevtsize schedlog_bigevtsize schedlog_bigevtsize)
MON+=(monitoring/nop monitoring/perf_sched_record monitoring/SchedLog)

for J in ${!KERNEL_LOCALVERSIONS[@]}
do
    KERNEL_LOCALVERSION=${KERNEL_LOCALVERSIONS[$J]}
    MONITORING=${MON[$J]}
    for I in ${!SLP[@]}
    do
	SLEEP_STATE=${SLP[$I]}
	SCALING_GOVERNOR=${GOV[$I]}
	REPEAT=${RPT[$I]}
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
	BENCH=bench/hackbench
	for N in $(seq ${REPEAT})
	do
	    for TASKS in  10000 # 8000 6000 4000 2000 1000 40
	    do
		OUTPUT="output/"
		OUTPUT+="HOST=${HOSTNAME}/"
		OUTPUT+="BENCH=$(basename ${BENCH})/"
		OUTPUT+="POWER=${SCALING_GOVERNOR}-${SLEEP_STATE}/"
		OUTPUT+="MONITORING=$(basename ${MONITORING})/"
		OUTPUT+="${TASKS}-${KERNEL_LOCALVERSION}/${N}"
		run_bench
	    done
	done
	BENCH=bench/kbuild
	for N in $(seq ${REPEAT})
	do
	    for TARGET in kernel/sched/ # all
	    do
		for TASKS in 320
		do
		    OUTPUT="output/"
		    OUTPUT+="HOST=${HOSTNAME}/"
		    OUTPUT+="BENCH=$(basename ${BENCH})-$(basename ${TARGET})/"
		    OUTPUT+="POWER=${SCALING_GOVERNOR}-${SLEEP_STATE}/"
		    OUTPUT+="MONITORING=$(basename ${MONITORING})/"
		    OUTPUT+="${TASKS}-${KERNEL_LOCALVERSION}/${N}"
		    run_bench
		done
	    done
	done
    done
done
