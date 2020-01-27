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
    keep &= (df['MONITORING'] == 'nop') | (df['MONITORING'] == 'SchedLog') | (df['MONITORING'] == 'perf_sched_record') | (df['MONITORING'] == 'trace_sched') | (df['MONITORING'] == 'trace_sched-4')
    keep &= df['TASKS'] != '400'
    keep &= (df['KERNEL'] == '5.4-linux') | (df['KERNEL'] == '5.4-linux-eventsize-trimmed') | (df['KERNEL'] == '5.4-linux-eventallocfails') | (df['KERNEL'] == 'schedlog') | (df['KERNEL'] == 'schedlog_bigevtsize') | ((df['HOST'] == 'latitude') & (df['KERNEL'] == 'lp'))
    df = df[keep]
    df = df.drop(['POWER', 'fname'],axis=1)
    selkb = df['BENCH'] == 'kbuild-sched'
    df.loc[selkb,['perf']] = df[selkb]['usr_bin_time']
    print(df)
    x = "Bench Tasks Kernel Host"
    df[x] = df["BENCH"] + " " + df["TASKS"] + " " + df["KERNEL"] + " " + df["HOST"]
    for normalize in ['usr_bin_time', 'perf']:
        y = f"{normalize} (%)"
        df[y] = df["usr_bin_time"]
        # NORMALIZE with nop
        selm = df['MONITORING'] == 'nop'
        for _x_ in np.unique(df[x]):
            sel = df[x] == _x_
            # Mean of Monitoring == nop
            m = np.mean(df[selm & sel][y])
            df.loc[sel,[y]] = (m - df[sel][y]) / m
    y = ['usr_bin_time', 'usr_bin_time (%)', 'perf', 'perf (%)'][1]
    hue = "Monitoring"
    df[hue] = df["MONITORING"]
    hue_order = sorted(np.unique(df[hue]))
    hue_order = ['nop'] + list(filter(lambda x : x not in ['nop','SchedLog'], hue_order)) + ['SchedLog']
    #
    for b in np.unique(df['BENCH']):
        sel = df['BENCH'] == b
        data = df[sel]
        order = sorted(np.unique(data[x]))
        for y in ['usr_bin_time', 'usr_bin_time (%)']:
            figsize = (6.4*(len(order)), 4.8)
            plt.figure(figsize=figsize)
            sns.barplot(data=data, y=y, x=x, hue=hue, order=order, hue_order=hue_order)
            plt.savefig(f'plot/monitoring/{b}.{y}.barplot.pdf')
            plt.figure(figsize=figsize)
            sns.swarmplot(data=data, y=y, x=x, hue=hue, order=order, hue_order=hue_order)
            plt.savefig(f'plot/monitoring/{b}.{y}.swamplot.pdf')
if __name__ == '__main__':
	main()
