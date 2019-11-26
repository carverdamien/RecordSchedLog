#!/usr/bin/env python3.7

import sys
import pandas as pd
import numpy as np
from string import Template
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
            'index' : f"kbuild-{target}-{tasks}",
            'template' : Template(f"/mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/BENCH=kbuild-{target}/POWER=powersave-y/MONITORING=all/{tasks}-$kernel/.*tar"),
            'match' : lambda y, kernel    : y['template'].substitute(kernel=kernel),
            'perf'  : lambda y, match     : np.mean(raw[raw['fname'].str.match(match)]['usr_bin_time']),
            'norm'  : lambda y, perf, ref : 100.0*(ref-perf)/ref,
        }
        for target in ['all','sched']
        for tasks in ['80','160','320']
    ]
    X = ['ipanema', 'local', 'local-light', 'pull-back', 'sched-freq']
    XREF = X[0]
    CELL = lambda x,y : y['norm'](y, y['perf'](y, y['match'](y, x)),y['perf'](y, y['match'](y, XREF)))
    data = [[CELL(x,y) for x in X] for y in Y]
    df = pd.DataFrame(data, columns=X, index=[y['index'] for y in Y])
    print(df)
    vmax = df.max().max()
    vmin = -vmax
    fig = plt.figure(figsize=(2*6.4, 1*4.8))
    cmap = sns.diverging_palette(240, 10, n=9)
    ax = sns.heatmap(df, annot=True, fmt="2.1f", vmin=vmin, vmax=vmax, cmap=cmap)
    ax.set_yticklabels(ax.get_yticklabels(), rotation=0)
    # fig.tight_layout()
    fig.savefig(output_file)

if __name__ == '__main__':
    main()
