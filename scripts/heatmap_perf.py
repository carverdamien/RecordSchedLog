#!/usr/bin/env python3.7

import sys
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
sns.set()

def main():
    _, output_file, input_file = sys.argv
    print(output_file, input_file)
    raw = pd.read_csv(input_file, sep=';')
    print(raw)
    Y = [
        {
            'index' : 'kbuild-all-80',
            'match' : lambda kernel    : f"/mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/BENCH=kbuild-all/POWER=powersave-y/MONITORING=all/80-{kernel}/.*tar",
            'perf'  : lambda match     : np.mean(raw[raw['fname'].str.match(match)]['usr_bin_time']),
            'norm'  : lambda perf, ref : 100.0*(ref-perf)/ref,
        },
        {
            'index' : 'kbuild-sched-80',
            'match' : lambda kernel    : f"/mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/BENCH=kbuild-sched/POWER=powersave-y/MONITORING=all/80-{kernel}/.*tar",
            'perf'  : lambda match     : np.mean(raw[raw['fname'].str.match(match)]['usr_bin_time']),
            'norm'  : lambda perf, ref : 100.0*(ref-perf)/ref,
        },
                {
            'index' : 'kbuild-all-160',
            'match' : lambda kernel    : f"/mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/BENCH=kbuild-all/POWER=powersave-y/MONITORING=all/160-{kernel}/.*tar",
            'perf'  : lambda match     : np.mean(raw[raw['fname'].str.match(match)]['usr_bin_time']),
            'norm'  : lambda perf, ref : 100.0*(ref-perf)/ref,
        },
        {
            'index' : 'kbuild-sched-160',
            'match' : lambda kernel    : f"/mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/BENCH=kbuild-sched/POWER=powersave-y/MONITORING=all/160-{kernel}/.*tar",
            'perf'  : lambda match     : np.mean(raw[raw['fname'].str.match(match)]['usr_bin_time']),
            'norm'  : lambda perf, ref : 100.0*(ref-perf)/ref,
        }
    ]
    X = ['ipanema', 'local', 'local-light', 'pull-back', 'sched-freq']
    XREF = X[0]
    CELL = lambda x,y : y['norm'](y['perf'](y['match'](x)),y['perf'](y['match'](XREF)))
    data = [[CELL(x,y) for x in X] for y in Y]
    df = pd.DataFrame(data, columns=X, index=[y['index'] for y in Y])
    print(df)
    vmax = df.max().max()
    vmin = -vmax
    fig = plt.figure()#figsize=(6.4, 4.8))
    cmap = sns.diverging_palette(240, 10, n=9)
    ax = sns.heatmap(df, annot=True, fmt="2.1f", vmin=vmin, vmax=vmax, cmap=cmap)
    # fig.tight_layout()
    fig.savefig(output_file)

if __name__ == '__main__':
    main()
