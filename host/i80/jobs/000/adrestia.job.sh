#!/bin/bash
export TIMEOUT
export IPANEMA_MODULE
export OUTPUT
export BENCH
export MONITORING
export MONITORING_SCHEDULED
export ARRIVAL_RATE_US
export NR_LOOPS
export TASKS
export TEST

NO_TURBO=0
TIMEOUT=3600
IPANEMA_MODULE=
BENCH=bench/adrestia
MONITORING=monitoring/all
MONITORING_SCHEDULED=n
KERNEL_LOCALVERSIONS="ipanema no-preempt-wakeup" #"pull-back sched-freq local local-light ipanema"
SLP=(y         n          )
GOV=(powersave performance)
RPT=(1         1          )
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
	    for ARRIVAL_RATE_US in 1 5 10 20 30 40
	    do
		for NR_LOOPS in 10000
		do
		    for TASKS in 40 80 160 # 8000 6000 4000 2000 1000 40
		    do
			for TEST in wakeup-single wakeup-periodic
			do
			    OUTPUT="output/"
			    OUTPUT+="BENCH=$(basename ${BENCH})/"
			    OUTPUT+="POWER=${SCALING_GOVERNOR}-${SLEEP_STATE}/"
			    OUTPUT+="MONITORING=$(basename ${MONITORING})/"
			    OUTPUT+="${ARRIVAL_RATE_US}_${NR_LOOPS}_${TASKS}_${TEST}_${KERNEL_LOCALVERSION}/${N}"
			    run_bench
			done
		    done
		done
	    done
	done
    done
done
