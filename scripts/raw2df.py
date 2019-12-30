#!/usr/bin/env python3

import sys
import pandas as pd
import numpy as np

# Usage
#   ./raw2df.py input.csv output.pkl.gz
_, input_file, output_file = sys.argv

in_data = pd.read_csv(input_file, delimiter=';')
for column_name in ['usr_bin_time', 'phoronix', 'energy', 'sysbench_trps']:
    in_data[column_name] = in_data[column_name].astype(float)
out_data = pd.DataFrame(columns=['bench', 'power', 'sched', 'id', 'perf', 'energy'])
tmp_list = []

# For each record in the csv file
for d in in_data.iterrows():
    lp = ''

    # Exclude non 5.4.0 kernels
    kernel = d[1]['kernel_version']
    if '5.4.0' not in kernel:
        continue

    # File name parsing
    fname = d[1]['fname'].split('/')
    for f in fname:
        if 'BENCH=' in f:
            bench = f.split('=')[1]
        elif 'POWER=' in f:
            power = f.split('=')[1]
        elif 'LP=' in f:
            lp = f.split('=')[1]
        elif 'HOST=' in f:
            host = f.split('=')[1]
        elif 'PHORONIX=' in f:
            phoronix = f.split('=')[1]
        elif 'MONITORING=' in f:
            monitor = f.split('=')[1]
        elif '.tar' in f:
            run_id = int(f.split('.')[0])
    if lp == '':
        continue
    if monitor != 'cpu-energy-meter':
        continue

    # Handle llvmcmake and phoronix specific naming
    sched = fname[-2]
    if bench not in ['llvmcmake', 'phoronix']:
        bench = '{}-{}'.format(bench, sched.split('-')[0])
        sched = '-'.join(sched.split('-')[1:])
    elif bench == 'phoronix':
        bench = phoronix

    # Parse scheduler
    if sched in [ '5.4', 'schedlog' ]:
        kernel = kernel
    elif 'delayed-placement' in sched or 'dpi' in sched or 'dp2' in sched:
        if lp == 'n':
            lp = 50
        sched = '{}-{}'.format('dpi' if 'dpi' in sched else 'dp' if 'dp' in sched else 'dp2', lp)
    elif 'local-placement' in sched or 'lp' in sched:
        sched = 'lp-{}'.format(lp)
    elif sched.endswith('local'):
        sched = 'local'
    else:
        continue

    # Parse benchmark performance and energy
    if bench.startswith(('kbuild', 'hackbench', 'llvmcmake', 'nas_')):
        perf = d[1]['usr_bin_time']
    elif bench.startswith(('aobench-0', 'build-linux-kernel-0', 'build-llvm-0', 'mkl-dnn-7-1', 'mkl-dnn-7-2',
                           'rust-prime-0', 'schbench-6-7', 'go-benchmark-1', 'go-benchmark-2', 'go-benchmark-3',
                           'go-benchmark-4', 'apache-0', 'redis-1', 'apache-siege-1', 'apache-siege-2',
                           'apache-siege-3', 'apache-siege-4', 'apache-siege-5', 'scimark2-1', 'scimark2-2',
                           'scimark2-3', 'scimark2-4', 'scimark2-5', 'scimark2-6', 'node-octane-1')):
        perf = d[1]['phoronix']
    elif bench.startswith(('oltp')):
        perf = d[1]['sysbench_trps']
    else:
        continue

    energy = d[1]['energy']

    tmp_list.append({ 'bench': bench, 'sched': sched, 'power': power, 'id': run_id, 'perf': perf, 'energy': energy })

# Add to dataframe
out_data = out_data.append(tmp_list, ignore_index = True)

# Save in pickle format
out_data.to_pickle(output_file)
