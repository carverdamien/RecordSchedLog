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

export TRACECMD_RECORD_OPT='-b 128 -e sched'
export DO_NOT_UNSHARE=n
NO_TURBO=0
TIMEOUT=3600
IPANEMA_MODULE=
BENCH=bench/hackbench
MONITORING_SCHEDULED=n

CMDLINE=default
SCALING_GOVERNOR=schedutil

: ${MAX_RPT:=1}
KERNEL_LOCALVERSIONS=()
EXTRA_SYSCTL=()
MON=()
RPT=()

KERNEL_LOCALVERSIONS+=(5.4-schedlog-ftraced 5.4-schedlog-ftraced 5.4-schedlog-ftraced)
EXTRA_SYSCTL+=('' '' '')
MON+=(monitoring/turbostat monitoring/trace-cmd monitoring/nop)
RPT+=(${MAX_RPT} 1 ${MAX_RPT})

KERNEL_LOCALVERSIONS+=(5.4-local 5.4-local 5.4-local)
EXTRA_SYSCTL+=('' '' '')
MON+=(monitoring/turbostat monitoring/trace-cmd monitoring/nop)
RPT+=(${MAX_RPT} 1 ${MAX_RPT})

KERNEL_LOCALVERSIONS+=(5.4-move 5.4-move 5.4-move)
EXTRA_SYSCTL+=(
'kernel.sched_lowfreq=2000000'
'kernel.sched_lowfreq=2000000'
'kernel.sched_lowfreq=2000000'
)
MON+=(monitoring/turbostat monitoring/trace-cmd monitoring/nop)
RPT+=(${MAX_RPT} 1 ${MAX_RPT})

for I in ${!KERNEL_LOCALVERSIONS[@]}
do
    KERNEL_LOCALVERSION=${KERNEL_LOCALVERSIONS[$I]}
    SYSCTL=${EXTRA_SYSCTL[$I]}
    REPEAT=${RPT[$I]}
    MONITORING=${MON[$I]}
    for N in $(seq ${REPEAT})
    do
	for TASKS in 400 1000 2000
	do
	    OUTPUT="output/"
	    OUTPUT+="HOST=${HOSTNAME}/"
	    OUTPUT+="BENCH=$(basename ${BENCH})/"
	    OUTPUT+="CMDLINE=${CMDLINE}/"
	    OUTPUT+="GOVERNOR=${SCALING_GOVERNOR}/"
	    OUTPUT+="MONITORING=$(basename ${MONITORING})/"
	    OUTPUT+="TASKS=${TASKS}/"
	    OUTPUT+="KERNEL=${KERNEL_LOCALVERSION}/"
	    for sysctl in ${SYSCTL}
	    do
		OUTPUT+="${sysctl}/"
	    done
	    OUTPUT+="${N}"
	    run_bench
	done
    done
done
