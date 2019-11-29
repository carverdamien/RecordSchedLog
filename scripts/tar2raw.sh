#!/usr/bin/env bash
set -u -e # -x

COLUMNS=(fname usr_bin_time phoronix energy sysbench_trps kernel_version sysctl_sched_local_placement)
FORMAT="%s;%s;%s;%s;%s;%s;%s\n"

lstar() { tar tf "$1"; }
gettar() { tar -O -xf "$1" "$2"; }

main() {
    case "$1" in
	'master')
	    shift
	    master "$1" | tee "$2"
	    ;;
	*)
	    sequential "$1" | tee "$2"
	    ;;
    esac
}

sequential() {
    input_dir="$1"

    printf "$FORMAT" "${COLUMNS[@]}"
    find "$input_dir"  -name '*.tar' | slave
}

master() {
    input_dir="$1"

    printf "$FORMAT" "${COLUMNS[@]}"

    nproc=$(nproc)
    njob=$(find "$input_dir"  -name '*.tar' | wc -l)
    batch=$((njob/nproc+1))
    CHILDREN=""
    for i in $(seq $nproc)
    do
	CHILDREN+="<(find '$input_dir'  -name '*.tar' | tail -n +$(( (i-1)*(batch)+1 )) | head -n $batch | slave | sponge) "
    done
    eval cat $CHILDREN
}

slave() {
    while read tar
    do
	row=()
	for col in ${COLUMNS[@]}
	do
	    row+=($($col "$tar" < /dev/null))
	done
	printf "$FORMAT" "${row[@]}"
    done
}

fname() {
    echo "$1"
}

energy() {
    tar="$1"
    value_file=$(lstar "$tar" | grep -E 'cpu-energy-meter.out$')
    if test -z "$value_file"
    then
	value=NaN
    else
	value=$(echo $(grep joules <(gettar "$tar" "$value_file") | cut -d'=' -f2 | tr '\n' '+')0 | bc -l)
    fi
    if test -z "$value"
    then
	value=NaN
    fi
    echo $value
}

usr_bin_time() {
    tar="$1"
    value_file=$(lstar "$tar" | grep -E 'time.err$')
    if test -z "$value_file"
    then
	value=NaN
    else
	value=$(grep -v '+' <(gettar "$tar" "$value_file"))
    fi
    if test -z "$value"
    then
	value=NaN
    fi
    echo "$value"
}

phoronix() {
    tar="$1"
    value_file=$(lstar "$tar" | grep -E 'phoronix.json$')
    if test -z "$value_file"
    then
	value=NaN
    else
	value=$(grep '"value"' <(gettar "$tar" "$value_file") | cut -d'"' -f4)
    fi
    if test -z "$value"
    then
	value=NaN
    fi
    echo "$value"
}

kernel_version() {
    tar="$1"
    value_file=$(lstar "$tar" | grep -E 'report.main.json$')
    if test -z "$value_file"
    then
	value=NaN
    else
	value=$(jq '.kernel.version' <(gettar "$tar" "$value_file"))
    fi
    if test -z "$value"
    then
	value=NaN
    fi
    echo "$value"
}

sysbench_trps() {
    tar="$1"
    value_file=$(lstar "$tar" | grep -E 'run.out$')
    if test -z "$value_file"
    then
	value=NaN
    else
	value=$(sed -n 's/ *transactions: *[0-9]* *.\([^ ]\+\) per sec../\1/p' <(gettar "$tar" "$value_file"))
    fi
    if test -z "$value"
    then
	value=NaN
    fi
    echo "$value"
}

sysctl_sched_local_placement() {
    tar="$1"
    value_file=$(lstar "$tar" | grep -E 'sysctl.prepare$')
    if test -z "$value_file"
    then
	value=NaN
    else
	value=$(sed -n 's/kernel.sched_local_placement = \([0-9]*\)/\1/p' <(gettar "$tar" "$value_file"))
    fi
    if test -z "$value"
    then
	value=NaN
    fi
    echo "$value"
}			      

main "$@"
