#!/bin/bash
set -e -x -u

./scripts/tar2raw.sh master /mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/HOST=i80 i80.csv

for value in perf energy
do
    for agg in min max mean median
    do
	./scripts/heatmap.py "heatmaps/$value.$agg.pdf" i80.csv $value $agg
    done
done
