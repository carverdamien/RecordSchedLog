#!/usr/bin/env python3

import pandas as pd
import numpy as np
import sys

_, pkl_file = sys.argv

df = pd.read_pickle(pkl_file) 

benches = np.unique(df['bench'].values)
scheds = np.unique(df['sched'].values)
for b in benches:
    for s in scheds:
        d = df[(df['bench'] == b) & (df['sched'] == s)]
        if len(d) != 10:
            print('{} {} has {} records instead of 10'.format(b, s, len(d)))
        somme = d.isnull().sum().sum()
        if somme > 0:
            print('{} {} has {} NaN'.format(b, s, somme))
