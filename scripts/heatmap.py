#!/usr/bin/env python3

import sys, os
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
    print(raw.head())
    HOST=os.environ.get('HOST','i80')
    POWER=os.environ.get('POWER','powersave-y')
    MONITORING=os.environ.get('MONITORING','cpu-energy-meter')
    Y = [
        {
            'index' : f"mysql-kbuild-kbtime",
            'template' : Template(f"/mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/HOST={HOST}/BENCH={bench}/POWER={POWER}/MONITORING={MONITORING}/LP=$lp/{tasks}-$kernel/.*.tar"),
            'match' : lambda y, x    : y['template'].substitute(**x['sub']),
            'value' : lambda y, match     : agg(raw[raw['fname'].str.match(match)][{'energy':'energy','perf':'kbuild_usr_bin_time'}[value]]),
            'norm'  : lambda y, v, ref : 100.0*(ref-v)/ref,
        }
        for bench in {'redha':[], 'latitude':[], 'i80':['multi-app-mysql-kbuild-all']}[HOST]
        for tasks in {'redha':[], 'latitude':[], 'i80':['80']}[HOST]
    ] + [
        {
            'index' : f"mysql-kbuild-trps",
            'template' : Template(f"/mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/HOST={HOST}/BENCH={bench}/POWER={POWER}/MONITORING={MONITORING}/LP=$lp/{tasks}-$kernel/.*.tar"),
            'match' : lambda y, x    : y['template'].substitute(**x['sub']),
            'value' : lambda y, match     : agg(raw[raw['fname'].str.match(match)][{'energy':'energy','perf':'sysbench_trps'}[value]]),
            'norm'  : lambda y, v, ref : 100.0*(ref-v)/ref,
        }
        for bench in {'redha':[], 'latitude':[], 'i80':['multi-app-mysql-kbuild-all']}[HOST]
        for tasks in {'redha':[], 'latitude':[], 'i80':['80']}[HOST]
    ] + [
        {
            'index' : f"{bench}-{tasks}",
            'template' : Template(f"/mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/HOST={HOST}/BENCH={bench}/POWER={POWER}/MONITORING={MONITORING}/LP=$lp/{tasks}-$kernel/.*.tar"),
            'match' : lambda y, x    : y['template'].substitute(**x['sub']),
            'value' : lambda y, match     : agg(raw[raw['fname'].str.match(match)][{'energy':'energy','perf':'usr_bin_time'}[value]]),
            'norm'  : lambda y, v, ref : 100.0*(ref-v)/ref,
        }
        for bench in {'redha':['kbuild-all','kbuild-sched'], 'latitude':['kbuild-all','kbuild-sched'], 'i80':['kbuild-all','kbuild-sched','build-mysql-server']}[HOST]
        for tasks in {'redha':['6','12','24'], 'latitude':['4','8','16'], 'i80':['80','160','320']}[HOST]
    ] + [
        {
            'index' : f"{bench}-{tasks}",
            'template' : Template(f"/mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/HOST={HOST}/BENCH={bench}/POWER={POWER}/MONITORING={MONITORING}/LP=$lp/{tasks}-$kernel/.*.tar"),
            'match' : lambda y, x    : y['template'].substitute(**x['sub']),
            'value' : lambda y, match     : agg(raw[raw['fname'].str.match(match)][{'energy':'energy','perf':'usr_bin_time'}[value]]),
            'norm'  : lambda y, v, ref : 100.0*(ref-v)/ref,
        }
        for bench in ['hackbench']
        for tasks in {'redha':['1000'], 'latitude':['1000'],'i80':['10000']}[HOST]
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
        for bench in ['nas_bt.B', 'nas_cg.C', 'nas_ep.C', 'nas_ft.C', 'nas_lu.B', 'nas_sp.B', 'nas_ua.B', 'nas_mg.D']
        for tasks in {'redha':['6','12'], 'latitude':['4','8'], 'i80':['80','160']}[HOST]
    ] + [
        {
            'index' : f"{phoronix}",
            'template' : Template(f"/mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/HOST={HOST}/BENCH=phoronix/POWER={POWER}/MONITORING={MONITORING}/LP=$lp/PHORONIX={phoronix}/$kernel/.*.tar"),
            'match' : lambda y, x    : y['template'].substitute(**x['sub']),
            'value' : lambda y, match     : agg(raw[raw['fname'].str.match(match)][{'energy':'energy','perf':'phoronix'}[value]]),
            'norm'  : lambda y, v, ref : 100.0*(ref-v)/ref, # Lower is better
        }
        for phoronix in ['aobench-0', 'build-linux-kernel-0', 'build-llvm-0', 'mkl-dnn-7-1', 'mkl-dnn-7-2', 'rust-prime-0', 'schbench-6-7', 'go-benchmark-1', 'go-benchmark-2', 'go-benchmark-3', 'go-benchmark-4', 'cloudsuite-da-1', 'cloudsuite-ga-1', 'cloudsuite-ma-1', 'cloudsuite-ms-1', 'cloudsuite-ws-1']
    ] + [
        {
            'index' : f"{phoronix}",
            'template' : Template(f"/mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/HOST={HOST}/BENCH=phoronix/POWER={POWER}/MONITORING={MONITORING}/LP=$lp/PHORONIX={phoronix}/$kernel/.*.tar"),
            'match' : lambda y, x    : y['template'].substitute(**x['sub']),
            'value' : lambda y, match     : agg(raw[raw['fname'].str.match(match)][{'energy':'energy','perf':'phoronix'}[value]]),
            'norm'  : lambda y, v, ref : (-1 if value=='perf' else 1) * 100.0*(ref-v)/ref, # higher is better
        }
        for phoronix in ['apache-0', 'redis-1', 'apache-siege-1', 'apache-siege-2', 'apache-siege-3', 'apache-siege-4', 'apache-siege-5', 'scimark2-1', 'scimark2-2', 'scimark2-3', 'scimark2-4', 'scimark2-5', 'scimark2-6', 'node-octane-1']
    ] + [
        {
            'index' : f"oltp-{tasks}",
            'template' : Template(f"/mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/HOST={HOST}/BENCH=oltp-mysql/POWER={POWER}/MONITORING={MONITORING}/LP=$lp/{tasks}-$kernel/.*.tar"),
            'match' : lambda y, x    : y['template'].substitute(**x['sub']),
            'value' : lambda y, match     : agg(raw[raw['fname'].str.match(match)][{'energy':'energy','perf':'sysbench_trps'}[value]]),
            'norm'  : lambda y, v, ref : (-1 if value=='perf' else 1) * 100.0*(ref-v)/ref, # higher is better
        }
        for tasks in {'redha':[], 'latitude':[], 'i80':['80','160','320']}[HOST]
    ]
    X = [
        {
            'index' : '4.19',
            'sub' : {'kernel':'ipanema','lp':'n'},
        },
        {
            'index' : '5.4',
            'sub' : {'kernel':{'redha':'5.4','i80':'schedlog','latitude':'lp'}[HOST],'lp':'0' if HOST == 'latitude' else 'n'},
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
            'index' : 'local-cw',
            'sub' : {'kernel':'local-cpuofwaker','lp':'n'},
        },
        {
            'index' : 'local-light-cw',
            'sub' : {'kernel':'local-light-cpuofwaker','lp':'n'},
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
        {
            'index' : 'dp',
            'sub' : {'kernel':'delayed-placement','lp':'n'},
        },
        {
            'index' : 'dp-300',
            'sub' : {'kernel':'delayed-placement','lp':'300000'},
        },
    ]
    XREF = X[1]
    i=-1
    print(Y[i]['match'](Y[i],X[0]))
    if use_norm=='normed':
        CELL = lambda x,y : y['norm'](y, y['value'](y, y['match'](y, x)),y['value'](y, y['match'](y, XREF)))
    elif use_norm=='raw':
        CELL = lambda x,y : y['value'](y, y['match'](y, x))
    else:
        raise Exception()
    data = [[CELL(x,y) for x in X] for y in Y]
    df = pd.DataFrame(data, columns=[x['index'] for x in X], index=[y['index'] for y in Y])
    print(df.head())
    vmax = df.max().max()
    vmin = -vmax
    fig = plt.figure(figsize=(2*6.4, 3*4.8))
    cmap = sns.diverging_palette(240, 10, n=9)
    ax = sns.heatmap(df, annot=True, fmt="2.1f", vmin=vmin, vmax=vmax, cmap=cmap)
    ax.set_yticklabels(ax.get_yticklabels(), rotation=0)
    fig.savefig(output_file)
    df.to_csv(output_file+".csv", float_format="%2.1f")

if __name__ == '__main__':
    main()
