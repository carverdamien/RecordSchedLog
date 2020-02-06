#!/bin/bash
export TIMEOUT
export IPANEMA_MODULE
export OUTPUT
export BENCH
export MONITORING
export MONITORING_SCHEDULED
export TASKS
export SYSCTL=''

export TRACECMD_RECORD_OPT='-b 128 -e sched'
export DO_NOT_UNSHARE=n
NO_TURBO=0
TIMEOUT=3600
IPANEMA_MODULE=

MONITORING_SCHEDULED=n
CMDLINE=default

GOV=(schedutil)
RPT=(1)

KERNEL_LOCALVERSIONS=()
MON=()

KERNEL_LOCALVERSIONS+=(5.4-schedlog-ftraced 5.4-schedlog-ftraced)
MON+=(monitoring/trace-cmd monitoring/nop)

for J in ${!KERNEL_LOCALVERSIONS[@]}
do
    KERNEL_LOCALVERSION=${KERNEL_LOCALVERSIONS[$J]}
    MONITORING=${MON[$J]}
    MONITORING_FNAME="$(basename ${MONITORING})"
    for I in ${!GOV[@]}
    do
	SCALING_GOVERNOR=${GOV[$I]}
	REPEAT=${RPT[$I]}
	BENCH=bench/hackbench
	for N in $(seq ${REPEAT})
	do
	    for TASKS in 400
	    do
		OUTPUT="output/"
		OUTPUT+="HOST=${HOSTNAME}/"
		OUTPUT+="BENCH=$(basename ${BENCH})/"
		OUTPUT+="CMDLINE=${CMDLINE}/"
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
		    OUTPUT+="CMDLINE=${CMDLINE}/"
		    OUTPUT+="MONITORING=${MONITORING_FNAME}/"
		    OUTPUT+="${TASKS}-${KERNEL_LOCALVERSION}/${N}"
		    run_bench
		done
	    done
	done
    done
done

