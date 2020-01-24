#!/usr/bin/env python3
import os, tarfile, re
import pandas as pd
import numpy as np
from matplotlib import pyplot as plt
import seaborn as sns

FNAME = """.*/HOST=(?P<HOST>.+)/BENCH=(?P<BENCH>.+)/POWER=(?P<POWER>.+)/MONITORING=(?P<MONITORING>.+)/(?P<TASKS>\d+)-(?P<KERNEL>.+)/(?P<N>\d+).tar"""
FNAME = re.compile(FNAME)

TIME_ERR = """\+\+ set -e -u
\+\+ prog=bench/hackbench/run
\+\+ shift
\+\+ exec /usr/bin/time -f %e bench/hackbench/run -- bench/hackbench/run
(?P<usr_bin_time>.+)
"""
TIME_ERR = re.compile(TIME_ERR)

RUN_OUT = """Running in process mode with \d+ groups using \d+ file descriptors each \(== \d+ tasks\)
Each sender will pass \d+ messages of \d+ bytes
Time: (?P<perf>.+)
"""
RUN_OUT = re.compile(RUN_OUT)

def tar_path_2_data(tar_path):
    data = {'fname':tar_path}
    # print(data)
    data.update(FNAME.match(tar_path).groupdict())
    with tarfile.open(tar_path) as tar:
        for tarinfo in tar.getmembers():
            # print(tarinfo.name)
            if os.path.basename(tarinfo.name) == 'time.err':
                with tar.extractfile(tarinfo.name) as f:
                    f = f.read().decode()
                    data.update({'usr_bin_time':float(list(filter(lambda x : len(x)>0, f.split('\n')))[-1])})
                    # data.update(TIME_ERR.match(f).groupdict())
            if os.path.basename(tarinfo.name) == 'run.out':
                with tar.extractfile(tarinfo.name) as f:
                    f = f.read().decode()
                    # print(f'f={f}')
                    try:
                        data.update(RUN_OUT.match(f).groupdict())
                    except Exception as e:
                        print(e)
	    # if os.path.basename(tarinfo.name) == 'sched_log_traced_events.start':
	    #     with tar.extractfile(tarinfo.name) as f:
	    #         last = f.read().decode().split('\n')[-2]
	    #         num, name = last.split(' ')
	    #         if num == '20':
	    #     	assert name == 'DELAYED_PLACEMENT'
	    # if os.path.basename(tarinfo.name) == 'run.err':
	    #     with tar.extractfile(tarinfo.name) as f:
	    #         f = f.read().decode()
	    #         # print(f'f={f}')
	    #         data.update(RUN_ERR.match(f).groupdict())
	    # if os.path.basename(tarinfo.name) == 'event.npz':
	    #     with tar.extractfile(tarinfo.name) as f:
	    #         event = np.load(f)['event']
	    #         data['hrtimer'] = np.sum(event==20)
    # sys.exit(1)
    return data

def main():
    tar_list = []
    # ./HOST=i80/BENCH=hackbench/POWER=powersave-y/MONITORING={nop,perf_sched_record,SchedLog}/400-{5.4-linux,schedlog}/{1..10}.tar
    walk_path = './output/HOST=i80/BENCH=hackbench/POWER=powersave-y/'
    tar_list += [
        os.path.join(dirpath, filename)
        for dirpath, dirnames, filenames in os.walk(walk_path)
        for filename in filenames
        if os.path.splitext(filename)[1] == '.tar'
    ]
    walk_path = './output/HOST=i80/BENCH=kbuild-sched/POWER=powersave-y/'
    tar_list = [
        os.path.join(dirpath, filename)
        for walk_path in [
                './output/HOST=i80/BENCH=hackbench/POWER=powersave-y/',
                './output/HOST=i80/BENCH=kbuild-sched/POWER=powersave-y/',
                './output/HOST=latitude/BENCH=hackbench/POWER=powersave-y/',
                './output/HOST=latitude/BENCH=kbuild-sched/POWER=powersave-y/',
        ]
        for dirpath, dirnames, filenames in os.walk(walk_path)
        for filename in filenames
        if os.path.splitext(filename)[1] == '.tar'
    ]
    # print(tar_list)
    data = [tar_path_2_data(tar_path) for tar_path in tar_list]
    # print(data)
    df = pd.DataFrame(data)
    print(df)
    for f in filter(lambda x: x in df.columns, ['perf','usr_bin_time']):
        df[f] = df[f].astype(float)
    keep = np.ones(len(df), dtype=bool)
    # keep &= df['HOST'] == 'i80'
    keep &= (df['BENCH'] == 'hackbench') | (df['BENCH'] == 'kbuild-sched')
    keep &= df['POWER'] == 'powersave-y'
    keep &= (df['MONITORING'] == 'nop') | (df['MONITORING'] == 'SchedLog') | (df['MONITORING'] == 'perf_sched_record')
    keep &= df['TASKS'] != '400'
    keep &= (df['KERNEL'] == '5.4-linux') | (df['KERNEL'] == '5.4-linux-eventsize-trimmed') | (df['KERNEL'] == 'schedlog') | (df['KERNEL'] == 'schedlog_bigevtsize') | ((df['HOST'] == 'latitude') & (df['KERNEL'] == 'lp'))
    df = df[keep]
    df = df.drop(['POWER', 'fname'],axis=1)
    selkb = df['BENCH'] == 'kbuild-sched'
    df.loc[selkb,['perf']] = df[selkb]['usr_bin_time']
    print(df)
    order = None
    # x = "Tasks Monitoring"
    # df[x] = df["TASKS"]  + " " + df["MONITORING"]
    # order = sorted(np.unique(df[x]))
    x = "Bench Tasks Kernel Host"
    df[x] = df["BENCH"] + " " + df["TASKS"] + " " + df["KERNEL"] + " " + df["HOST"]
    order = sorted(np.unique(df[x]))
    print(order)
    # normalized = False
    normalized = True
    if normalized:
        # y = "perf (%)"
        # df[y] = df["perf"]
        y = "usr_bin_time (%)"
        df[y] = df["usr_bin_time"]
        # NORMALIZE
        selm = df['MONITORING'] == 'nop'
        for b in np.unique(df['BENCH']):
            selb = df['BENCH'] == b
            for t in np.unique(df[selb]['TASKS']):
                sel = selb & (df['TASKS'] == t)
                # m = np.mean(df[sel][y])
                m = np.mean(df[selm & sel][y])
                df.loc[sel,[y]] = (m - df[sel][y]) / m
    else:
        # y = "Hackbench Time"
        # df[y] = df["perf"]
        y = "usr_bin_time"
        df[y] = df["usr_bin_time"]
    # hue = "Kernel"
    # df[hue] = df["KERNEL"]
    hue = "Monitoring"
    df[hue] = df["MONITORING"]
    figsize = (6.4*(len(order)), 4.8)
    plt.figure(figsize=figsize)
    sns.barplot(data=df, y=y, x=x, hue=hue, order=order)
    plt.savefig('perf_sched_record.barplot.pdf')
    plt.figure(figsize=figsize)
    sns.swarmplot(data=df, y=y, x=x, hue=hue, order=order)
    plt.savefig('perf_sched_record.swarmplot.pdf')
if __name__ == '__main__':
	main()
