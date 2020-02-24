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
export BENCH_NAME BENCH_CLASS

export TRACECMD_RECORD_OPT='-b 128 -e sched'
export DO_NOT_UNSHARE=n
NO_TURBO=0
TIMEOUT=3600
IPANEMA_MODULE=
BENCH=bench/nas
BENCH_NAMES=(   bt cg ep ft    lu mg sp ua ) # ua sp dc # is
BENCH_CLASSES=( B  C  C  C     B  D  B  B  )  # C  A  A  # D
MONITORING_SCHEDULED=n

CMDLINE=default
SCALING_GOVERNOR=schedutil

KERNEL_LOCALVERSIONS=()
EXTRA_SYSCTL=()
MON=()
RPT=()

KERNEL_LOCALVERSIONS+=(5.4-schedlog-ftraced 5.4-schedlog-ftraced)
EXTRA_SYSCTL+=('' '')
MON+=(monitoring/nop monitoring/trace-cmd)
RPT+=(10 1)

KERNEL_LOCALVERSIONS+=(5.4-local 5.4-local)
EXTRA_SYSCTL+=('' '')
MON+=(monitoring/nop monitoring/trace-cmd)
RPT+=(10 1)

KERNEL_LOCALVERSIONS+=(5.4-move 5.4-move)
EXTRA_SYSCTL+=(
'kernel.sched_lowfreq=2000000'
'kernel.sched_lowfreq=2000000'
)
MON+=(monitoring/nop monitoring/trace-cmd)
RPT+=(10 1)

for I in ${!KERNEL_LOCALVERSIONS[@]}
do
    KERNEL_LOCALVERSION=${KERNEL_LOCALVERSIONS[$I]}
    SYSCTL=${EXTRA_SYSCTL[$I]}
    REPEAT=${RPT[$I]}
    MONITORING=${MON[$I]}
    for N in $(seq ${REPEAT})
    do
	for J in ${BENCH_NAMES[@]}
	do
	    for TASKS in 4 8 16
	    do
		BENCH_NAME=${BENCH_NAMES[$J]}
                BENCH_CLASS=${BENCH_CLASSES[$J]}
		OUTPUT="output/"
		OUTPUT+="HOST=${HOSTNAME}/"
		OUTPUT+="BENCH=$(basename ${BENCH})_{BENCH_NAME}.${BENCH_CLASS}/"
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
done
