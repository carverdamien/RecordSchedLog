#!/bin/bash
# Runs on i44 (cron every minutes)
main() {
    exec 1>/home/damien/git/carverdamien/RecordSchedLog/scripts/heatmap.stdout
    exec 2>/home/damien/git/carverdamien/RecordSchedLog/scripts/heatmap.stderr
    cd /home/damien/git/carverdamien/RecordSchedLog
    
    set -e -x -u
    date
    export MONITORING HOST POWER
    for HOST in i80 latitude redha
    do
	./scripts/tar2raw.sh master /mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/HOST=$HOST $HOST.csv
	./scripts/raw2df.py $HOST.csv $HOST.pkl.gz
	./scripts/barplot.py $HOST $HOST.pkl.gz $HOST.pdf
	# ./scripts/filter_cpu_energy_meter.py filter_cpu_energy_meter.csv data.csv
	# sed 's/.mnt.data.damien.git.carverdamien.SchedDisplay.examples.trace/output/' filter_cpu_energy_meter.csv | xargs shasum > host/i80/discard
	# rm -f $(cat filter_cpu_energy_meter.csv)
	for POWER in powersave-y schedutil-y
	do
	    for MONITORING in all cpu-energy-meter
	    do
		for value in perf energy
		do
		    for agg in min max mean median std
		    do
			for n in normed raw
			do
			    pdf="heatmaps/HOST=$HOST/POWER=${POWER}/MONITORING=$MONITORING/$n.$value.$agg.pdf"
			    mkdir -p $(dirname $pdf)
			    ./scripts/heatmap.py $pdf $HOST.csv $value $agg $n
			# barpdf="barplots/HOST=$HOST/POWER=${POWER}/MONITORING=$MONITORING/$n.$value.$agg"
			# mkdir -p $(dirname ${barpdf})
			# ./scripts/barplot.py ${pdf}.csv ${barpdf}.pdf ${barpdf}-no-ticks.pdf
			done
		    done
		done
	    done
	done
    done
}

(
    flock -n 9 || exit 1
    main
) 9>/tmp/heatmap.lock
