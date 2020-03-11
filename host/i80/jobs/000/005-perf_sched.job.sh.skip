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

export TRACING_BUFFER_SIZE_KB
export PERF_RECORD_OPT='-m 1G -a'
export TRACECMD_RECORD_OPT="-e sched -b $((2**20))"
export DO_NOT_UNSHARE=y
NO_TURBO=0
TIMEOUT=3600
IPANEMA_MODULE=
BENCH=bench/hackbench
MONITORING_SCHEDULED=n
SLP=(y)
GOV=(powersave)
RPT=(1)

KERNEL_LOCALVERSIONS=()
MON=()

KERNEL_LOCALVERSIONS+=(5.4-linux)
MON+=(monitoring/schedviz)

KERNEL_LOCALVERSIONS+=(5.4-schedlog-ftraced 5.4-schedlog-ftraced)
MON+=(monitoring/trace-cmd monitoring/nop)

KERNEL_LOCALVERSIONS+=(5.4-schedlog-ftraced 5.4-schedlog-ftraced 5.4-schedlog-ftraced)
MON+=(monitoring/trace_sched monitoring/nop monitoring/perf_sched_record)

KERNEL_LOCALVERSIONS+=(5.4-linux-ringbuffersize-512 5.4-linux-ringbuffersize-512 5.4-linux-ringbuffersize-512)
MON+=(monitoring/trace_sched monitoring/nop monitoring/perf_sched_record)

KERNEL_LOCALVERSIONS+=(5.4-linux 5.4-linux 5.4-linux)
MON+=(monitoring/nop monitoring/perf_sched_record monitoring/trace_sched)

KERNEL_LOCALVERSIONS+=(schedlog schedlog schedlog schedlog)
MON+=(monitoring/nop monitoring/perf_sched_record monitoring/SchedLog monitoring/trace_sched)

KERNEL_LOCALVERSIONS+=(schedlog_bigevtsize schedlog_bigevtsize schedlog_bigevtsize schedlog_bigevtsize)
MON+=(monitoring/nop monitoring/perf_sched_record monitoring/SchedLog monitoring/trace_sched)

KERNEL_LOCALVERSIONS+=(5.4-linux-eventsize-trimmed 5.4-linux-eventsize-trimmed 5.4-linux-eventsize-trimmed)
MON+=(monitoring/nop monitoring/perf_sched_record monitoring/trace_sched)

KERNEL_LOCALVERSIONS+=(5.4-linux-eventallocfails 5.4-linux-eventallocfails 5.4-linux-eventallocfails)
MON+=(monitoring/perf_sched_record monitoring/nop monitoring/trace_sched)

for J in ${!KERNEL_LOCALVERSIONS[@]}
do
for TRACING_BUFFER_SIZE_KB in 512 4
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
	    for TASKS in  10000 # 8000 6000 4000 2000 1000 40
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
		for TASKS in 320
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
done
