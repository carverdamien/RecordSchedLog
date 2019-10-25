#!/usr/bin/env bash

[ $# -ne 1 ] && { echo "Usage: $0 dir"; exit 1; }

path=$1

bench=$(basename $path | cut -d'=' -f2)

dirs=$(find $path -name '*.tar' | rev | cut -d'/' -f2 | rev | sort -u)

for d in $dirs ; do
    p=$(find $path -name $d)
    runtime="=AVERAGE("
    energy="=AVERAGE("
    for t in $(find $p -name '*.tar') ; do
	rm -rf /tmp/redha/*
	mkdir -p /tmp/redha
	tar xf $t -C /tmp/redha
	
	time_file=$(find /tmp/redha/ -name 'time.err')
	runtime="${runtime}$(grep -v '+' $time_file),"

	energy_file=$(find /tmp/redha/ -name 'cpu-energy-meter.out')
	energy="${energy}$(echo $(grep joules $energy_file | cut -d'=' -f2 | tr '\n' '+')0 | bc -l),"
    done
    runtime=${runtime%%,}
    runtime="${runtime})"
    energy=${energy%%,}
    energy="${energy})"

    echo $bench $d
    echo "Performance: ${runtime}"
    echo "Energy: ${energy}"
    echo
    
done
