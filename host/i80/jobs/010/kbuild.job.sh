#!/bin/bash
export TIMEOUT
export IPANEMA_MODULE
export OUTPUT
export BENCH
export MONITORING
export MONITORING_SCHEDULED
export KERNEL_COMMIT
export TASKS
export TARGET

NO_TURBO=0
TIMEOUT=3600
IPANEMA_MODULE=
BENCH=bench/kbuild
MONITORING=monitoring/all
MONITORING_SCHEDULED=n
KERNEL_LOCALVERSIONS="ipanema pull-back local-freq-base" # "no-preempt-wakeup pull-back sched-freq local local-light ipanema"
KERNEL_COMMIT=54ecb8f7028c5eb3d740bb82b0f1d90f2df63c5c
SLP=(n           y)
GOV=(performance powersave)
RPT=(1           3)
for KERNEL_LOCALVERSION in ${KERNEL_LOCALVERSIONS}
do
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
	for N in $(seq ${REPEAT})
	do
	    for TASKS in 80 160 320
	    do
		for TARGET in all kernel/sched/
		do
		    OUTPUT="output/"
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
