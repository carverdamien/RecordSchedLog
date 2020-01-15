#!/usr/bin/env python3
import os, tarfile, re
import pandas as pd
import numpy as np
from matplotlib import pyplot as plt
import seaborn as sns

walk_path = './output/HOST=i80/BENCH=schbench'
tar_list = [
    os.path.join(dirpath, filename)
    for dirpath, dirnames, filenames in os.walk(walk_path)
    for filename in filenames
    if os.path.splitext(filename)[1] == '.tar'
]

# print(tar_list)

FNAME = """.*/HOST=(?P<HOST>.+)/BENCH=(?P<BENCH>.+)/POWER=(?P<POWER>.+)/MONITORING=(?P<MONITORING>.+)/LP=(?P<LP>.+)/(?P<M>.+)-(?P<T>.+)/(?P<SCHED>.+)/(?P<N>\d+).tar"""
FNAME = re.compile(FNAME)

RUN_ERR = """\+ exec /tmp/schbench/schbench -m (?P<M>\d+) -t (?P<T>\d+)
Latency percentiles \(usec\)
	50.0th: (?P<p500>\S+)
	75.0th: (?P<p750>\S+)
	90.0th: (?P<p900>\S+)
	95.0th: (?P<p950>\S+)
	\*99.0th: (?P<p990>\S+)
	99.5th: (?P<p995>\S+)
	99.9th: (?P<p999>\S+)
	min=(?P<min>\S+), max=(?P<max>\S+)
"""
RUN_ERR = re.compile(RUN_ERR)

def f(tar_path):
    data = {'fname':tar_path}
    data.update(FNAME.match(tar_path).groupdict())
    with tarfile.open(tar_path) as tar:
        for tarinfo in tar.getmembers():
            if os.path.basename(tarinfo.name) == 'run.err':
                with tar.extractfile(tarinfo.name) as f:
                    data.update(RUN_ERR.match(f.read().decode()).groupdict())
    return data

data = [f(tar_path) for tar_path in tar_list]
# print(data)
df = pd.DataFrame(data)
latencies = ['min', 'p500', 'p750', 'p900', 'p950', 'p990', 'p995', 'p999', 'max']
for k in ['T'] + latencies:
    df[k] = df[k].astype(float)
fig, ax = plt.subplots(len(latencies), figsize=(6.4, 4.8*len(latencies)))
for i in range(len(latencies)):
    sns.lineplot(x='T', y=latencies[i], hue='SCHED', data=df, err_style="bars", ax=ax[i])
plt.savefig('hrtimer.pdf')
