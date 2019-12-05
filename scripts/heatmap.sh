#!/bin/bash
# Runs on i44 (cron every minutes)
exec 1>/home/damien/git/carverdamien/RecordSchedLog/scripts/heatmap.stdout
exec 2>/home/damien/git/carverdamien/RecordSchedLog/scripts/heatmap.stderr
cd /home/damien/git/carverdamien/RecordSchedLog

set -e -x -u
date

./scripts/tar2raw.sh master /mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/HOST=i80 i80.csv
./scripts/filter_cpu_energy_meter.py filter_cpu_energy_meter.csv i80.csv
sed 's/.mnt.data.damien.git.carverdamien.SchedDisplay.examples.trace/output/' filter_cpu_energy_meter.csv | xargs shasum > host/i80/discard

for value in perf energy
do
    for agg in min max mean median std
    do
	for n in normed raw
	do
	    ./scripts/heatmap.py "heatmaps/$n.$value.$agg.pdf" i80.csv $value $agg $n
	done
    done
done
