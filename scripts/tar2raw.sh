#!/usr/bin/env bash
set -u -e # -x

COLUMNS=(fname usr_bin_time phoronix energy sysbench_trps)
FORMAT="%s;%s;%s;%s;%s\n"

lstar() { tar tf "$1"; }
gettar() { tar -O -xf "$1" "$2"; }

main() {
    input_dir=$1
    output_raw=$2

    printf "$FORMAT" "${COLUMNS[@]}"
    for tar in $(find $input_dir  -name '*.tar')
    do
	row=()
	for col in ${COLUMNS[@]}
	do
	    row+=($($col $tar < /dev/null))
	done
	printf "$FORMAT" "${row[@]}"
    done | tee $2
}

fname() {
    echo "$1"
}

energy() {
    tar=$1
    value_file=$(lstar $tar | grep -E 'cpu-energy-meter.out$')
    if test -z "$value_file"
    then
	value=NaN
    else
	value=$(echo $(grep joules <(gettar $tar $value_file) | cut -d'=' -f2 | tr '\n' '+')0 | bc -l)
    fi
    if test -z "$value"
    then
	value=NaN
    fi
    echo $value
}

usr_bin_time() {
    tar=$1
    value_file=$(lstar $tar | grep -E 'time.err$')
    if test -z "$value_file"
    then
	value=NaN
    else
	value=$(grep -v '+' <(gettar $tar $value_file))
    fi
    if test -z "$value"
    then
	value=NaN
    fi
    echo "$value"
}

phoronix() {
    tar=$1
    value_file=$(lstar $tar | grep -E 'phoronix.json$')
    if test -z $value_file
    then
	value=NaN
    else
	value=$(grep '"value"' <(gettar $tar ${value_file}) | cut -d'"' -f4)
    fi
    if test -z "$value"
    then
	value=NaN
    fi
    echo "$value"
}

sysbench_trps() {
    tar=$1
    value_file=$(lstar $tar | grep -E 'run.out$')
    if test -z "$value_file"
    then
	value=NaN
    else
	value=$(sed -n 's/ *transactions: *[0-9]* *.\([^ ]\+\) per sec../\1/p' <(gettar $tar $value_file))
    fi
    if test -z "$value"
    then
	value=NaN
    fi
    echo "$value"
}

main "$@"
