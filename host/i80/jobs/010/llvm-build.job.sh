#!/bin/bash
export TIMEOUT
export IPANEMA_MODULE
export OUTPUT
export BENCH
export MONITORING
export MONITORING_SCHEDULED

NO_TURBO=0
TIMEOUT=3600
IPANEMA_MODULE=
BENCH=bench/llvmcmake
MONITORING=monitoring/all
MONITORING_SCHEDULED=n
KERNEL_LOCALVERSIONS="pull-back sched-freq local local-light ipanema"

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
	    OUTPUT="output/"
	    OUTPUT+="BENCH=$(basename ${BENCH})/"
	    OUTPUT+="POWER=${SCALING_GOVERNOR}-${SLEEP_STATE}/"
	    OUTPUT+="MONITORING=$(basename ${MONITORING})/"
	    OUTPUT+="${KERNEL_LOCALVERSION}/${N}"
	    run_bench
	done
    done
done
