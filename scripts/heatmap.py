#!/usr/bin/env python3.7

import sys
import pandas as pd
import numpy as np
from string import Template
import matplotlib.pyplot as plt
import seaborn as sns
sns.set()

def main():
    # ./scripts/heatmap.py out.pdf in.csv energy|perf min|max|mean|median normed|raw
    _, output_file, input_file, value, agg, use_norm = sys.argv
    print(output_file, input_file, value, agg, use_norm)
    agg = {
        'min'  : np.min,
        'max'  : np.max,
        'mean' : np.mean,
        'median' : np.median,
        'std' : np.std,
    }[agg]
    raw = pd.read_csv(input_file, sep=';')
    for column_name in ['usr_bin_time', 'phoronix', 'energy', 'sysbench_trps']:
        raw[column_name] = raw[column_name].astype(float)
    print(raw)
    HOST='i80'
    POWER='powersave-y'
    MONITORING='cpu-energy-meter'
    Y = [
        {
            'index' : f"{bench}-{tasks}",
            'template' : Template(f"/mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/HOST={HOST}/BENCH={bench}/POWER={POWER}/MONITORING={MONITORING}/LP=$lp/{tasks}-$kernel/.*.tar"),
            'match' : lambda y, x    : y['template'].substitute(**x['sub']),
            'value' : lambda y, match     : agg(raw[raw['fname'].str.match(match)][{'energy':'energy','perf':'usr_bin_time'}[value]]),
            'norm'  : lambda y, v, ref : 100.0*(ref-v)/ref,
        }
        for bench in ['kbuild-all','kbuild-sched']
        for tasks in ['80','160','320']
    ] + [
        {
            'index' : f"{bench}-{tasks}",
            'template' : Template(f"/mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/HOST={HOST}/BENCH={bench}/POWER={POWER}/MONITORING={MONITORING}/LP=$lp/{tasks}-$kernel/.*.tar"),
            'match' : lambda y, x    : y['template'].substitute(**x['sub']),
            'value' : lambda y, match     : agg(raw[raw['fname'].str.match(match)][{'energy':'energy','perf':'usr_bin_time'}[value]]),
            'norm'  : lambda y, v, ref : 100.0*(ref-v)/ref,
        }
        for bench in ['hackbench']
        for tasks in ['10000']
    ] + [
        {
            'index' : f"{bench}",
            'template' : Template(f"/mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/HOST={HOST}/BENCH={bench}/POWER={POWER}/MONITORING={MONITORING}/LP=$lp/$kernel/.*.tar"),
            'match' : lambda y, x    : y['template'].substitute(**x['sub']),
            'value' : lambda y, match     : agg(raw[raw['fname'].str.match(match)][{'energy':'energy','perf':'usr_bin_time'}[value]]),
            'norm'  : lambda y, v, ref : 100.0*(ref-v)/ref,
        }
        for bench in ['llvmcmake']
    ] + [
        {
            'index' : f"{bench}-{tasks}",
            'template' : Template(f"/mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/HOST={HOST}/BENCH={bench}/POWER={POWER}/MONITORING={MONITORING}/LP=$lp/{tasks}-$kernel/.*.tar"),
            'match' : lambda y, x    : y['template'].substitute(**x['sub']),
            'value' : lambda y, match     : agg(raw[raw['fname'].str.match(match)][{'energy':'energy','perf':'usr_bin_time'}[value]]),
            'norm'  : lambda y, v, ref : 100.0*(ref-v)/ref,
        }
        for bench in ['nas_bt.B', 'nas_cg.C', 'nas_ep.C', 'nas_ft.C', 'nas_lu.B', 'nas_sp.B', 'nas_ua.B']
        for tasks in ['80','160','320']
    ] + [
        {
            'index' : f"{phoronix}",
            'template' : Template(f"/mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/HOST={HOST}/BENCH=phoronix/POWER={POWER}/MONITORING={MONITORING}/LP=$lp/PHORONIX={phoronix}/$kernel/.*.tar"),
            'match' : lambda y, x    : y['template'].substitute(**x['sub']),
            'value' : lambda y, match     : agg(raw[raw['fname'].str.match(match)][{'energy':'energy','perf':'phoronix'}[value]]),
            'norm'  : lambda y, v, ref : 100.0*(ref-v)/ref, # Lower is better
        }
        for phoronix in ['aobench-0', 'build-linux-kernel-0', 'build-llvm-0', 'mkl-dnn-7-1', 'mkl-dnn-7-2', 'rust-prime-0', 'schbench-6-7']
    ] + [
        {
            'index' : f"{phoronix}",
            'template' : Template(f"/mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/HOST={HOST}/BENCH=phoronix/POWER={POWER}/MONITORING={MONITORING}/LP=$lp/PHORONIX={phoronix}/$kernel/.*.tar"),
            'match' : lambda y, x    : y['template'].substitute(**x['sub']),
            'value' : lambda y, match     : agg(raw[raw['fname'].str.match(match)][{'energy':'energy','perf':'phoronix'}[value]]),
            'norm'  : lambda y, v, ref : (-1 if value=='perf' else 1) * 100.0*(ref-v)/ref, # higher is better
        }
        for phoronix in ['apache-0', 'redis-1', 'apache-siege-1', 'apache-siege-2', 'apache-siege-3', 'apache-siege-4', 'apache-siege-5' ]
    ]
    X = [
        {
            'index' : '4.19',
            'sub' : {'kernel':'ipanema','lp':'n'},
        },
        {
            'index' : '5.4',
            'sub' : {'kernel':'schedlog','lp':'n'},
        },
        {
            'index' : 'local',
            'sub' : {'kernel':'local','lp':'n'},
        },
        {
            'index' : 'local-light',
            'sub' : {'kernel':'local-light','lp':'n'},
        },
        {
            'index' : 'lp-0',
            'sub' : {'kernel':'lp','lp':'0'},
        },
        {
            'index' : 'lp-1',
            'sub' : {'kernel':'lp','lp':'1'},
        },
        {
            'index' : 'lp-2',
            'sub' : {'kernel':'lp','lp':'2'},
        },
    ]
    XREF = X[1]
    i=6
    print(Y[i]['match'](Y[i],X[0]))
    if use_norm=='normed':
        CELL = lambda x,y : y['norm'](y, y['value'](y, y['match'](y, x)),y['value'](y, y['match'](y, XREF)))
    elif use_norm=='raw':
        CELL = lambda x,y : y['value'](y, y['match'](y, x))
    else:
        raise Exception()
    data = [[CELL(x,y) for x in X] for y in Y]
    df = pd.DataFrame(data, columns=[x['index'] for x in X], index=[y['index'] for y in Y])
    print(df)
    vmax = df.max().max()
    vmin = -vmax
    fig = plt.figure(figsize=(2*6.4, 2*4.8))
    cmap = sns.diverging_palette(240, 10, n=9)
    ax = sns.heatmap(df, annot=True, fmt="2.1f", vmin=vmin, vmax=vmax, cmap=cmap)
    ax.set_yticklabels(ax.get_yticklabels(), rotation=0)
    fig.savefig(output_file)

if __name__ == '__main__':
    main()
