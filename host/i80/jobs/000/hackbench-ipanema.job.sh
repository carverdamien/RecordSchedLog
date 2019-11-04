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
IPANEMA_MODULES="cfs_wwc ule_wwc ule cfs_wwc_flat" # "cfs_unblock_wwc" #"cfs_wwc cfs_wwc_preempt_on_wakeup ule_wwc cfs_unblock_wwc cfs_ticklike_wwc"
BENCH=bench/hackbench
MONITORING=monitoring/all
MONITORING_SCHEDULED=n
KERNEL_LOCALVERSIONS="ipanema" # "schedule"
SLP=(n          ) # y        )
GOV=(performance) # powersave)
RPT=(6          ) # 1        )
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
	    for IPANEMA_MODULE in ${IPANEMA_MODULES}
	    do
		for TASKS in 10000 # 8000 6000 4000 2000 1000 40
		do
		    OUTPUT="output/"
		    OUTPUT+="BENCH=$(basename ${BENCH})_2/"
		    OUTPUT+="POWER=${SCALING_GOVERNOR}-${SLEEP_STATE}/"
		    OUTPUT+="MONITORING=$(basename ${MONITORING})/"
		    OUTPUT+="IPANEMA=$(basename ${IPANEMA_MODULE})/"
		    OUTPUT+="${TASKS}-${KERNEL_LOCALVERSION}/${N}"
		    run_bench
		done
	    done
	done
    done
done
