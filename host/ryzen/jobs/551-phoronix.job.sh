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
export PHORONIX PHORONIX_TEST_ARGUMENTS

export TRACECMD_RECORD_OPT='-b 128 -e sched'
export DO_NOT_UNSHARE=n
NO_TURBO=0
TIMEOUT=3600
IPANEMA_MODULE=
BENCH=bench/phoronix
MONITORING_SCHEDULED=n
PHORONIXES=()
PARGUMENTS=()

PHORONIXES+=(apache-siege apache-siege apache-siege apache-siege apache-siege)
PARGUMENTS+=(           5            4            3            2            1)

PHORONIXES+=(scimark2 scimark2 scimark2 scimark2 scimark2 scimark2)
PARGUMENTS+=(       1        2        3        4        5        6)

PHORONIXES+=(go-benchmark go-benchmark go-benchmark go-benchmark)
PARGUMENTS+=(           1            2            3            4)

PHORONIXES+=(redis rust-prime aobench apache node-octane)
PARGUMENTS+=(    1          0       0      0           1)

PHORONIXES+=(mkl-dnn mkl-dnn)
PARGUMENTS+=(  '7-1'   '7-2')

PHORONIXES+=(schbench)
PARGUMENTS+=(   '6-7')

# PHORONIXES+=(build-linux-kernel build-llvm)
# PARGUMENTS+=(                 0          0)

# PHORONIXES+=(cloudsuite-da cloudsuite-ga cloudsuite-ma cloudsuite-ms cloudsuite-ws)
# PARGUMENTS+=(            1             1             1             1             1)

PHORONIXES+=(c-ray compress-7zip deepspeech git openssl perl-benchmark perl-benchmark phpbench)
PARGUMENTS+=(    0             0          0   0       0              1              2        0)

CMDLINE=default
SCALING_GOVERNOR=schedutil

MAX_RPT=1
KERNEL_LOCALVERSIONS=()
EXTRA_SYSCTL=()
MON=()
RPT=()

KERNEL_LOCALVERSIONS+=(5.4-schedlog-ftraced 5.4-schedlog-ftraced)
EXTRA_SYSCTL+=('' '')
MON+=(monitoring/nop monitoring/trace-cmd)
RPT+=(${MAX_RPT} 1)

KERNEL_LOCALVERSIONS+=(5.4-local 5.4-local)
EXTRA_SYSCTL+=('' '')
MON+=(monitoring/nop monitoring/trace-cmd)
RPT+=(${MAX_RPT} 1)

KERNEL_LOCALVERSIONS+=(5.4-move 5.4-move)
EXTRA_SYSCTL+=(
'kernel.sched_lowfreq=2000000'
'kernel.sched_lowfreq=2000000'
)
MON+=(monitoring/nop monitoring/trace-cmd)
RPT+=(${MAX_RPT} 1)

for I in ${!KERNEL_LOCALVERSIONS[@]}
do
    KERNEL_LOCALVERSION=${KERNEL_LOCALVERSIONS[$I]}
    SYSCTL=${EXTRA_SYSCTL[$I]}
    REPEAT=${RPT[$I]}
    MONITORING=${MON[$I]}
    for N in $(seq ${REPEAT})
    do
	for J in ${!PHORONIXES[@]}
	do
	    PHORONIX=${PHORONIXES[$J]}
	    PHORONIX_TEST_ARGUMENTS=${PARGUMENTS[$J]}
	    OUTPUT="output/"
	    OUTPUT+="HOST=${HOSTNAME}/"
	    OUTPUT+="BENCH=$(basename ${BENCH})/"
	    OUTPUT+="CMDLINE=${CMDLINE}/"
	    OUTPUT+="GOVERNOR=${SCALING_GOVERNOR}/"
	    OUTPUT+="MONITORING=$(basename ${MONITORING})/"
	    OUTPUT+="PHORONIX=${PHORONIX}-${PHORONIX_TEST_ARGUMENTS}/"
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
