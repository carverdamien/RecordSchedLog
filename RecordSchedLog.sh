#!/bin/bash
set -e -u -x

function run_bench {
    (
	: isdefined ${TIMEOUT} ${IPANEMA_MODULE} ${BENCH} ${MONITORING} ${MONITORING_SCHEDULED}
	: isdefined ${OUTPUT} ${KERNEL_LOCALVERSION} ${CMDLINE} ${NO_TURBO} ${SCALING_GOVERNOR}
	: isdefined ${SYSCTL}
	export TIMEOUT
	export IPANEMA_MODULE
	export OUTPUT
	export BENCH
	export MONITORING
	export MONITORING_SCHEDULED
	TAR="${OUTPUT}.tar"
	if [[ -e .touch ]]
	then
	    # like make -t
	    mkdir -p "$(dirname ${TAR})"
	    touch "${TAR}"
	fi
	if [[ -e "${TAR}" ]]
	then
	    return 0
	fi
	env -i bash -c "source /tmp/RecordSchedLog.env;
	    ./scripts/kbuild.sh host/${HOSTNAME}/kernel/${KERNEL_LOCALVERSION};
	    host/${HOSTNAME}/ktools/reboot  host/${HOSTNAME}/kernel/${KERNEL_LOCALVERSION} host/${HOSTNAME}/cmdline/${CMDLINE};"
	case ${NO_TURBO} in
	    0)
		TURBO=1
		;;
	    1)
		TURBO=0
		;;
	    *)
		echo 'NO_TURBO must be 0|1'
		exit 1
		;;
	esac
	echo ${NO_TURBO} | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null ||
	    echo ${TURBO} | sudo tee /sys/devices/system/cpu/cpufreq/boost
	echo ${SCALING_GOVERNOR} | sudo tee /sys/devices/system/cpu/cpufreq/policy*/scaling_governor > /dev/null
	case ${SYSCTL} in
	    '')
		;;
	    *)
		sudo /sbin/sysctl -w ${SYSCTL}
		;;
	esac
	sudo -E ./scripts/entrypoint
	if [[ -x ./host/${HOSTNAME}/callback_run_bench.sh ]]
	then
	    test -e .skip_callback_run_bench ||
		./host/${HOSTNAME}/callback_run_bench.sh "${TAR}" ||
		true
	fi
    )
}

function main {
    (
	flock -n 9 || exit 1
	export -p > /tmp/RecordSchedLog.env
	touch host/${HOSTNAME}/discard
	while read file_shasum file_path
	do
	    if [ "$(shasum $file_path)" = "$file_shasum  $file_path" ]
	    then
		sudo rm -f "$file_path"
	    fi
	done < host/${HOSTNAME}/discard
	export MAX_RPT
	for MAX_RPT in $(seq 10)
	do
	    find host/${HOSTNAME}/jobs -name '*.job.sh' | sort | while read job
	    do
		(source "${job}")
	    done
	done
    ) 9>/tmp/RecordSchedLog.lock
}

main
