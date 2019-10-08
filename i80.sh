#!/bin/bash
set -e -u -x

function run_bench {
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
    echo ${NO_TURBO} | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null
    echo ${SCALING_GOVERNOR} | sudo tee /sys/devices/system/cpu/cpufreq/policy*/scaling_governor > /dev/null
    ./scripts/entrypoint
    if [[ -x ./host/${HOSTNAME}/callback_run_bench.sh ]]
    then
	echo ./host/${HOSTNAME}/callback_run_bench.sh "${TAR}" || true
    fi
}

export TIMEOUT
export IPANEMA_MODULE
export OUTPUT
export BENCH
export MONITORING
export MONITORING_SCHEDULED
export PHORONIX

TIMEOUT=3600
IPANEMA_MODULE=
BENCH=bench/phoronix
PHORONIX=aobench
MONITORING=monitoring/all
MONITORING_SCHEDULED=n
SCALING_GOVERNOR=performance
SLEEP_STATE=y
KERNEL_LOCALVERSION=schedlog
N=1

OUTPUT="output/"
OUTPUT+="BENCH=$(basename ${BENCH})/"
OUTPUT+="POWER=${SCALING_GOVERNOR}-${SLEEP_STATE}/"
OUTPUT+="MONITORING=$(basename ${MONITORING})/"
OUTPUT+="PHORONIX=${PHORONIX}/"
OUTPUT+="${KERNEL_LOCALVERSION}/${N}"

run_bench
