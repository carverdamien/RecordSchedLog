#!/usr/bin/env bash
set -u -e # -x

COLUMNS=(fname usr_bin_time phoronix energy)
FORMAT="%s;%s;%s;%s\n"

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
    echo $1
}

energy() {
    tar=$1
    TMP=$(mktemp -d /tmp/XXXXXX)
    tar xf $tar -C $TMP
    value_file=$(find $TMP -name 'cpu-energy-meter.out')
    if test -z $value_file
    then
	value=NaN
    else
	value=$(echo $(grep joules $value_file | cut -d'=' -f2 | tr '\n' '+')0 | bc -l)
    fi
    test -n $value
    rm -rf $TMP
    echo $value
}

usr_bin_time() {
    tar=$1
    TMP=$(mktemp -d /tmp/XXXXXX)
    tar xf $tar -C $TMP
    value_file=$(find $TMP -name 'time.err')
    if test -z $value_file
    then
	value=NaN
    else
	value=$(grep -v '+' $value_file)
    fi
    test -n $value
    rm -rf $TMP
    echo $value
}

phoronix() {
    tar=$1
    TMP=$(mktemp -d /tmp/XXXXXX)
    tar xf $tar -C $TMP
    value_file=$(find $TMP -name 'phoronix.json')
    if test -z $value_file
    then
	value=NaN
    else
	value=$(grep '"value"' ${value_file} | cut -d'"' -f4)
    fi
    test -n $value
    rm -rf $TMP
    echo $value
}

main "$@"
