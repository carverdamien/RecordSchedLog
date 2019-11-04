#!/bin/bash
export TIMEOUT
export IPANEMA_MODULE
export OUTPUT
export BENCH
export BENCH_NAME
export BENCH_CLASS
export MONITORING
export MONITORING_SCHEDULED
export MONITORING_START_DELAY
export MONITORING_STOP_DELAY
export TASKS

NO_TURBO=0
TIMEOUT=3600
IPANEMA_MODULE=
BENCH=bench/nas
BENCH_NAMES=(   bt cg ep ft    lu mg sp sp ua ua ) # dc # is
BENCH_CLASSES=( B  C  C  C     B  D  A  B  B  C )  # A  # D
MONITORING=monitoring/all
MONITORING_SCHEDULED=n
MONITORING_START_DELAY=60
MONITORING_STOP_DELAY=10
KERNEL_LOCALVERSIONS="ipanema" # "pull-back ipanema schedlog sched-freq local local-light"
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
            for I in ${!BENCH_NAMES[@]}
            do
                for TASKS in 160 # 80
                do
                    BENCH_NAME=${BENCH_NAMES[$I]}
                    BENCH_CLASS=${BENCH_CLASSES[$I]}

                    OUTPUT="output/"
                    OUTPUT+="BENCH=$(basename ${BENCH})_${BENCH_NAME}.${BENCH_CLASS}_2/"
                    OUTPUT+="POWER=${SCALING_GOVERNOR}-${SLEEP_STATE}/"
                    OUTPUT+="MONITORING=$(basename ${MONITORING})/"
                    OUTPUT+="${TASKS}-${KERNEL_LOCALVERSION}/${N}"

                    run_bench
                done
            done
        done
    done
done

