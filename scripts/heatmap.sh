#!/bin/bash
# Runs on i44 (cron every minutes)
main() {
    exec 1>/home/damien/git/carverdamien/RecordSchedLog/scripts/heatmap.stdout
    exec 2>/home/damien/git/carverdamien/RecordSchedLog/scripts/heatmap.stderr
    cd /home/damien/git/carverdamien/RecordSchedLog
    
    set -e -x -u
    date
    
    ./scripts/tar2raw.sh master /mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/HOST=i80 i80.csv
    ./scripts/filter_cpu_energy_meter.py filter_cpu_energy_meter.csv i80.csv
    sed 's/.mnt.data.damien.git.carverdamien.SchedDisplay.examples.trace/output/' filter_cpu_energy_meter.csv | xargs shasum > host/i80/discard
    rm -f $(cat filter_cpu_energy_meter.csv)

    export MONITORING
    for MONITORING in all cpu-energy-meter
    do
	for value in perf energy
	do
	    for agg in min max mean median std
	    do
		for n in normed raw
		do
		    pdf="heatmaps/MONITORING=$MONITORING/$n.$value.$agg.pdf"
		    mkdir -p $(dirname $pdf)
		    ./scripts/heatmap.py $pdf i80.csv $value $agg $n
		done
	    done
	done
    done
}

(
    flock -n 9 || exit 1
    main
) 9>/tmp/heatmap.lock
