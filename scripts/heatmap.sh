#!/bin/bash
set -e -x -u

./scripts/tar2raw.sh master /mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/HOST=i80 i80.csv

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
