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
out_data = pd.DataFrame(columns=['bench', 'power', 'sched', 'id', 'perf', 'energy', 'path'])
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
        phoronix = False
    elif bench == 'phoronix':
        bench = phoronix
        phoronix = True
    else:
        phoronix = False

    # Parse scheduler
    if sched in [ '5.4', 'schedlog', '5.4-hrtimers']:
        pass
    elif sched in [ 'delayed-placement', 'dp' ]:
        sched = 'dp-{}'.format(50 if lp == 'n' else lp)
    elif sched in [ 'delayed-placement-2', 'dp2' ]:
        sched = 'dp2-{}'.format(50 if lp == 'n' else lp)
    elif sched in [ 'delayed-placement-3', 'dp3' ]:
        sched = 'dp3-{}'.format(50 if lp == 'n' else lp)
    elif sched in [ 'delayed-placement-idle', 'dpi' ]:
        sched = 'dpi-{}'.format(50 if lp == 'n' else lp)
    elif sched in [ 'delayed-placement-idle-2', 'dpi2' ]:
        sched = 'dpi2-{}'.format(50 if lp == 'n' else lp)
    elif sched in [ '5.4-fdp' ]:
        sched = 'fdp-{}'.format(50 if lp == 'n' else lp)
    elif sched in [ 'local-placement', 'lp' ]:
        sched = 'lp-{}'.format(lp)
    elif sched == 'local':
        sched = 'local'
    else:
        continue

    # Parse benchmark performance and energy
    if bench.startswith(('kbuild', 'hackbench', 'llvmcmake', 'nas_')):
        perf = d[1]['usr_bin_time']
    elif phoronix:
        perf = d[1]['phoronix']
    elif bench.startswith(('oltp')):
        perf = d[1]['sysbench_trps']
    else:
        continue

    energy = d[1]['energy']

    tmp_list.append({ 'bench': bench, 'sched': sched, 'power': power, 'id': run_id, 'perf': perf, 'energy': energy, 'path': d[1]['fname'] })

# Add to dataframe
out_data = out_data.append(tmp_list, ignore_index = True)

# Save in pickle format
out_data.to_pickle(output_file)
