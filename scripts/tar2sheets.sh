#!/usr/bin/env bash

function parse_phoronix() {
    path="$1"
    phoro_benches=$(find $path  -name '*.tar' | rev | cut -d'/' -f3 | rev | sort -u)

    for pb in $phoro_benches ; do
	for t in $(find $path -path */$pb/*/*.tar | rev | cut -d'/' -f2 | rev | uniq) ; do
	    perf="=AVERAGE("
	    energy="=AVERAGE("
	    for s in $(find $path -path */$pb/$t/*.tar) ; do
		rm -rf /tmp/redha/*
		mkdir -p /tmp/redha
		tar xf $s -C /tmp/redha

		phoronix_file=$(find /tmp/redha/ -name 'phoronix.json')
		perf="${perf}$(grep '"value"' ${phoronix_file} | cut -d'"' -f4),"

		energy_file=$(find /tmp/redha/ -name 'cpu-energy-meter.out')
		energy="${energy}$(echo $(grep joules $energy_file | cut -d'=' -f2 | tr '\n' '+')0 | bc -l),"
	    done
	    perf=${perf%%,}
	    perf="${perf})"
	    energy=${energy%%,}
	    energy="${energy})"

	    echo $bench $pb $t
	    echo "Performance: ${perf}"
	    echo "Energy: ${energy}"
	    echo
	done
    done
}

# Parse our benchmarks (kbuild-all, kbuild-sched, hackbench, llvmcmake)
function parse_ours() {
    path="$1"
    dirs=$(find $path -name '*.tar' | rev | cut -d'/' -f2 | rev | sort -u)

    for d in $dirs ; do
	p=$(find $path -name $d)
	
	perf="=AVERAGE("
	energy="=AVERAGE("
	for t in $(find $p -name '*.tar') ; do
	    rm -rf /tmp/redha/*
	    mkdir -p /tmp/redha
	    tar xf $t -C /tmp/redha

	    time_file=$(find /tmp/redha/ -name 'time.err')
	    perf="${perf}$(grep -v '+' $time_file),"

	    energy_file=$(find /tmp/redha/ -name 'cpu-energy-meter.out')
	    energy="${energy}$(echo $(grep joules $energy_file | cut -d'=' -f2 | tr '\n' '+')0 | bc -l),"
	done
	perf=${perf%%,}
	perf="${perf})"
	energy=${energy%%,}
	energy="${energy})"

	echo $bench $d
	echo "Performance: ${perf}"
	echo "Energy: ${energy}"
	echo
    done
}

[ $# -ne 1 ] && { echo "Usage: $0 dir"; exit 1; }

path="$1"
bench=$(basename $path | cut -d'=' -f2)

[ "${bench}" == "phoronix" ] &&
    parse_phoronix $path ||
	parse_ours $path

