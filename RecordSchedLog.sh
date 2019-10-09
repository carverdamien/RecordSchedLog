#!/bin/bash
set -e -u -x

function run_bench {
    (
	: isdefined ${TIMEOUT} ${IPANEMA_MODULE} ${BENCH} ${MONITORING} ${MONITORING_SCHEDULED}
	: isdefined ${OUTPUT} ${KERNEL_LOCALVERSION} ${CMDLINE} ${NO_TURBO} ${SCALING_GOVERNOR}
	export TIMEOUT
	export IPANEMA_MODULE
	export OUTPUT
	export BENCH
	export MONITORING
	export MONITORING_SCHEDULED
	TAR="${OUTPUT}.tar"
	if [[ -e "${TAR}" ]]
	then
	    return 0
	fi
	./scripts/kbuild.sh host/${HOSTNAME}/kernel/${KERNEL_LOCALVERSION}
	./scripts/kexec.sh  host/${HOSTNAME}/kernel/${KERNEL_LOCALVERSION} host/${HOSTNAME}/cmdline/${CMDLINE}
	echo ${NO_TURBO} | tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null
	echo ${SCALING_GOVERNOR} | tee /sys/devices/system/cpu/cpufreq/policy*/scaling_governor > /dev/null
	./scripts/entrypoint
	if [[ -x ./host/${HOSTNAME}/callback_run_bench.sh ]]
	then
	    ./host/${HOSTNAME}/callback_run_bench.sh "${TAR}" || true
	fi
    )
}

function main {
    (
	flock -n 9 || exit 1
	find host/${HOSTNAME} -name '*.job.sh' | sort | while read job
	do
	    (source "${job}")
	done
    ) 9>/tmp/RecordSchedLog.lock
}

main
