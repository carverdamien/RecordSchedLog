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
export SYSCTL

NO_TURBO=0
TIMEOUT=3600
IPANEMA_MODULE=
BENCH=bench/nas
# mg.D too much memory
BENCH_NAMES=(   bt cg ep ft    lu sp ua ) # mg # ua sp dc # is
BENCH_CLASSES=( B  C  C  C     B  B  B  ) # D  # C  A  A  # D
MONITORING_SCHEDULED=n
KERNEL_LOCALVERSIONS=(5.4-fdp-nom 5.4 local dpi)
LP_VALUES=(n n n n)
SLP=(y y)
GOV=(powersave schedutil)
RPT=(10 10)
MON=(monitoring/cpu-energy-meter monitoring/cpu-energy-meter)

for J in ${!KERNEL_LOCALVERSIONS[@]}
do
    KERNEL_LOCALVERSION=${KERNEL_LOCALVERSIONS[$J]}
    LP_VALUE=${LP_VALUES[$J]}
    case ${LP_VALUE} in
	n)
	    SYSCTL=''
	    ;;
	*)
	    if [ ${KERNEL_LOCALVERSION} == "delayed-placement" ] || [ ${KERNEL_LOCALVERSION} == "dpv" ] ; then
		SYSCTL="kernel.sched_delayed_placement=${LP_VALUE}"
	    else
		SYSCTL="kernel.sched_local_placement=${LP_VALUE}"
	    fi
	    ;;
    esac

    if [ ${KERNEL_LOCALVERSION} == "5.4-fdp-nom" ] ; then
	base_khz=$(echo "$(sed -nE '/model name/s/(.+) ([0-9.]+)GHz/\2/p' /proc/cpuinfo | head -n1) * 1000000" | bc)
	base_khz=${base_khz%.*}
	SYSCTL+=" kernel.sched_lowfreq=${base_khz}"
    fi

    for I in ${!SLP[@]}
    do
	SLEEP_STATE=${SLP[$I]}
	SCALING_GOVERNOR=${GOV[$I]}
	REPEAT=${RPT[$I]}
	MONITORING=${MON[$I]}
	case ${SLEEP_STATE} in
	    y)
		case ${SCALING_GOVERNOR} in
		    schedutil)
			CMDLINE=intel_sleep_state_enabled_pstate_passive
			;;
		    *)
			CMDLINE=intel_sleep_state_enabled
			;;
		esac
		;;
	    n)
		CMDLINE=intel_sleep_state_disabled
		;;
	    *)
		echo '${SLEEP_STATE} must be y|n'
		sleep inf
		exit 1
	esac
        for N in $(seq ${REPEAT})
        do
            for I in ${!BENCH_NAMES[@]}
            do
                for TASKS in 6 12
                do
                    BENCH_NAME=${BENCH_NAMES[$I]}
                    BENCH_CLASS=${BENCH_CLASSES[$I]}

                    OUTPUT="output/"
                    OUTPUT+="HOST=${HOSTNAME}/"
                    OUTPUT+="BENCH=$(basename ${BENCH})_${BENCH_NAME}.${BENCH_CLASS}/"
                    OUTPUT+="POWER=${SCALING_GOVERNOR}-${SLEEP_STATE}/"
                    OUTPUT+="MONITORING=$(basename ${MONITORING})/"
		    OUTPUT+="LP=${LP_VALUE}/"
                    OUTPUT+="${TASKS}-${KERNEL_LOCALVERSION}/${N}"
                    run_bench
                done
            done
        done
    done
done

