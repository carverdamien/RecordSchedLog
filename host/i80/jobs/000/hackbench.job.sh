#!/bin/bash
export TIMEOUT
export IPANEMA_MODULE
export OUTPUT
export BENCH
export MONITORING
export MONITORING_SCHEDULED
export TASKS

NO_TURBO=0
TIMEOUT=3600
IPANEMA_MODULE=
BENCH=bench/hackbench
MONITORING=monitoring/all
MONITORING_SCHEDULED=n
KERNEL_LOCALVERSIONS="ipanema" # "schedule no-preempt-wakeup ipanema pull-back sched-freq local local-light"
SLP=(y         n          )
GOV=(powersave performance)
RPT=(1         6          )
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
	    for TASKS in 10000 # 8000 6000 4000 2000 1000 40
	    do
		OUTPUT="output/"
		OUTPUT+="BENCH=$(basename ${BENCH})_2/"
		OUTPUT+="POWER=${SCALING_GOVERNOR}-${SLEEP_STATE}/"
		OUTPUT+="MONITORING=$(basename ${MONITORING})/"
		OUTPUT+="${TASKS}-${KERNEL_LOCALVERSION}/${N}"
		run_bench
	    done
	done
    done
done
