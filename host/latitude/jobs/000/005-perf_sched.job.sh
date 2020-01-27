#!/bin/bash
export TIMEOUT
export IPANEMA_MODULE
export OUTPUT
export BENCH
export MONITORING
export MONITORING_SCHEDULED
export TASKS
export SYSCTL=''

export TRACING_BUFFER_SIZE_KB=4
export DO_NOT_UNSHARE=y
export PERF_RECORD_OPT=''
NO_TURBO=0
TIMEOUT=3600
IPANEMA_MODULE=
BENCH=bench/hackbench
MONITORING_SCHEDULED=n
SLP=(y)
GOV=(powersave)
RPT=(10)

# KERNEL_LOCALVERSIONS=(5.4-linux 5.4-linux)
# MON=(monitoring/nop monitoring/perf_sched_record)

# KERNEL_LOCALVERSIONS+=(schedlog schedlog schedlog)
KERNEL_LOCALVERSIONS+=(lp lp lp lp)
SYSCTL="kernel.sched_local_placement=0"
MON+=(monitoring/nop monitoring/perf_sched_record monitoring/SchedLog monitoring/trace_sched)

# KERNEL_LOCALVERSIONS+=(schedlog_bigevtsize schedlog_bigevtsize schedlog_bigevtsize)
# MON+=(monitoring/nop monitoring/perf_sched_record monitoring/SchedLog)

for J in ${!KERNEL_LOCALVERSIONS[@]}
do
    KERNEL_LOCALVERSION=${KERNEL_LOCALVERSIONS[$J]}
    MONITORING=${MON[$J]}
    case ${MONITORING} in
	monitoring/trace_sched)
	    case ${TRACING_BUFFER_SIZE_KB} in
		1048576)
		    MONITORING_FNAME="$(basename ${MONITORING})"
		    ;;
		*)
		    MONITORING_FNAME="$(basename ${MONITORING})-${TRACING_BUFFER_SIZE_KB}"
		    ;;
	    esac
	    ;;
	*)
	    MONITORING_FNAME="$(basename ${MONITORING})"
	    ;;
    esac
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
	    for TASKS in 1000
	    do
		OUTPUT="output/"
		OUTPUT+="HOST=${HOSTNAME}/"
		OUTPUT+="BENCH=$(basename ${BENCH})/"
		OUTPUT+="POWER=${SCALING_GOVERNOR}-${SLEEP_STATE}/"
		OUTPUT+="MONITORING=${MONITORING_FNAME}/"
		OUTPUT+="${TASKS}-${KERNEL_LOCALVERSION}/${N}"
		run_bench
	    done
	done
	BENCH=bench/kbuild
	for N in $(seq ${REPEAT})
	do
	    for TARGET in kernel/sched/ # all
	    do
		for TASKS in 16
		do
		    OUTPUT="output/"
		    OUTPUT+="HOST=${HOSTNAME}/"
		    OUTPUT+="BENCH=$(basename ${BENCH})-$(basename ${TARGET})/"
		    OUTPUT+="POWER=${SCALING_GOVERNOR}-${SLEEP_STATE}/"
		    OUTPUT+="MONITORING=${MONITORING_FNAME}/"
		    OUTPUT+="${TASKS}-${KERNEL_LOCALVERSION}/${N}"
		    run_bench
		done
	    done
	done
    done
done
