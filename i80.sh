#!/bin/bash
set -e -u -x

export TIMEOUT
export IPANEMA_MODULE
export OUTPUT
export BENCH
export MONITORING
export MONITORING_SCHEDULED
export PHORONIX

function run_bench {
    : input ${OUTPUT} ${KERNEL_LOCALVERSION} ${SLEEP_STATE} ${NO_TURBO} ${SCALING_GOVERNOR}
    TAR="${OUTPUT}.tar"
    if [[ -e "${TAR}" ]]
    then
	return 0
    fi
    ./scripts/kbuild.sh host/${HOSTNAME}/kernel/${KERNEL_LOCALVERSION}
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
    ./scripts/kexec.sh  host/${HOSTNAME}/kernel/${KERNEL_LOCALVERSION} host/${HOSTNAME}/cmdline/${CMDLINE}
    echo ${NO_TURBO} | tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null
    echo ${SCALING_GOVERNOR} | tee /sys/devices/system/cpu/cpufreq/policy*/scaling_governor > /dev/null
    ./scripts/entrypoint
    if [[ -x ./host/${HOSTNAME}/callback_run_bench.sh ]]
    then
	./host/${HOSTNAME}/callback_run_bench.sh "${TAR}" || true
    fi
}

NO_TURBO=0
TIMEOUT=3600
IPANEMA_MODULE=
BENCH=bench/phoronix
PHORONIX=aobench
MONITORING=monitoring/all
MONITORING_SCHEDULED=n
KERNEL_LOCALVERSION=schedlog

SLP=(y         n          )
GOV=(powersave performance)
RPT=(1         1          )

for I in ${!SLP[@]}
do
    SLEEP_STATE=${SLP[$I]}
    SCALING_GOVERNOR=${GOV[$I]}
    REPEAT=${RPT[$I]}
    for N in $(seq ${REPEAT})
    do
	OUTPUT="output/"
	OUTPUT+="BENCH=$(basename ${BENCH})/"
	OUTPUT+="POWER=${SCALING_GOVERNOR}-${SLEEP_STATE}/"
	OUTPUT+="MONITORING=$(basename ${MONITORING})/"
	OUTPUT+="PHORONIX=${PHORONIX}/"
	OUTPUT+="${KERNEL_LOCALVERSION}/${N}"
	run_bench
    done
done
