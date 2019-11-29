#!/bin/bash
set -e -x -u

./scripts/tar2raw.sh master /mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/HOST=i80 i80.csv

for column_name in usr_bin_time energy
do
    for agg in min max mean median
    do
	./scripts/heatmap.py "heatmaps/$column_name.$agg.pdf" i80.csv $column_name $agg
    done
done
