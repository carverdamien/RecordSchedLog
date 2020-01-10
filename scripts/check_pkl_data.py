#!/usr/bin/env python3

import pandas as pd
import numpy as np
import sys

_, host, pkl_file = sys.argv

df = pd.read_pickle(pkl_file) 

# benches = np.unique(df['bench'].values)
# scheds = np.unique(df['sched'].values)
# for b in benches:
#     for s in scheds:
#         d = df[(df['bench'] == b) & (df['sched'] == s)]
#         if len(d) != 10:
#             print('{} {} has {} records instead of 10'.format(b, s, len(d)))
#         somme = d.isnull().sum().sum()
#         if somme > 0:
#             print('{} {} has {} NaN'.format(b, s, somme))

print('ATC bench check:')
benchmarks = {
    'i80': [ 'aobench-0', 'apache-0', 'apache-siege-1', 'apache-siege-2',
             'apache-siege-3', 'apache-siege-4', 'apache-siege-5',
             'build-linux-kernel-0', 'build-llvm-0', 'c-ray-0',
             'compress-7zip-0', 'deepspeech-0', 'git-0', 'go-benchmark-1',
             'go-benchmark-2', 'go-benchmark-3', 'go-benchmark-4',
             'hackbench-10000', 'kbuild-all-160', 'kbuild-all-320',
             'kbuild-all-80', 'kbuild-sched-160', 'kbuild-sched-320',
             'kbuild-sched-80', 'llvmcmake', 'mkl-dnn-7-1', 'mkl-dnn-7-2',
             'nas_bt.B-160', 'nas_bt.B-80', 'nas_cg.C-160', 'nas_cg.C-80',
             'nas_ep.C-160', 'nas_ep.C-80', 'nas_ft.C-160', 'nas_ft.C-80',
             'nas_lu.B-160',
             'nas_lu.B-80', 'nas_mg.D-160', 'nas_mg.D-80',
             'nas_sp.B-160', 'nas_sp.B-80', 'nas_ua.B-160', 'nas_ua.B-80',
             'node-octane-1', 'oltp-mysql-160', 'oltp-mysql-320',
             'oltp-mysql-80', 'openssl-0', 'perl-benchmark-1',
             'perl-benchmark-2', 'phpbench-0', 'redis-1', 'rust-prime-0',
             'schbench-6-7', 'scimark2-1', 'scimark2-2', 'scimark2-3',
             'scimark2-4', 'scimark2-5', 'scimark2-6'
    ],
    'latitude': [ 'aobench-0', 'apache-siege-1', 'apache-siege-2',
                  'apache-siege-3', 'apache-siege-4',
                  'build-linux-kernel-0', 'build-llvm-0', 'c-ray-0',
                  'compress-7zip-0', 'deepspeech-0', 'git-0', 'go-benchmark-1',
                  'go-benchmark-2', 'go-benchmark-3', 'go-benchmark-4',
                  'hackbench-1000', 'kbuild-all-16', 'kbuild-all-4',
                  'kbuild-all-8', 'kbuild-sched-16', 'kbuild-sched-4',
                  'kbuild-sched-8', 'llvmcmake', 'mkl-dnn-7-1', 'mkl-dnn-7-2',
                  'nas_bt.B-4', 'nas_bt.B-8', 'nas_cg.C-4', 'nas_cg.C-8',
                  'nas_ep.C-4', 'nas_ep.C-8', 'nas_ft.C-4', 'nas_ft.C-8',
                  'nas_lu.B-4', 'nas_lu.B-8', 'nas_sp.B-4', 'nas_sp.B-8',
                  'nas_ua.B-4', 'nas_ua.B-8',
                  'node-octane-1',
                  'openssl-0', 'perl-benchmark-1',
                  'perl-benchmark-2', 'phpbench-0', 'redis-1', 'rust-prime-0',
                  'scimark2-1', 'scimark2-2', 'scimark2-3', 'scimark2-4',
                  'scimark2-5', 'scimark2-6'
    ],
    'redha': [ 'aobench-0', 'apache-0', 'apache-siege-1', 'apache-siege-2',
               'apache-siege-3', 'apache-siege-4', 'apache-siege-5',
               'build-linux-kernel-0', 'build-llvm-0', 'c-ray-0',
               'compress-7zip-0', 'deepspeech-0', 'git-0', 'go-benchmark-1',
               'go-benchmark-2', 'go-benchmark-3', 'go-benchmark-4',
               'hackbench-1000', 'kbuild-all-12', 'kbuild-all-24',
               'kbuild-all-6', 'kbuild-sched-12', 'kbuild-sched-24',
               'kbuild-sched-6', 'llvmcmake', 'mkl-dnn-7-1', 'mkl-dnn-7-2',
               'nas_bt.B-12', 'nas_bt.B-6', 'nas_cg.C-12', 'nas_cg.C-6',
               'nas_ep.C-12', 'nas_ep.C-6', 'nas_ft.C-12', 'nas_ft.C-6',
               'nas_lu.B-12', 'nas_lu.B-6', 'nas_sp.B-12', 'nas_sp.B-6',
               'nas_ua.B-12', 'nas_ua.B-6',
               'node-octane-1',
               'openssl-0', 'perl-benchmark-1',
               'perl-benchmark-2', 'phpbench-0', 'redis-1', 'rust-prime-0',
               'schbench-6-7', 'scimark2-1', 'scimark2-2', 'scimark2-3',
               'scimark2-4', 'scimark2-5', 'scimark2-6'
    ],
}
schedulers = {
    'i80': [
        { 'sched': 'schedlog', 'gov': 'powersave-y' },
        { 'sched': 'schedlog', 'gov': 'schedutil-y' },
        { 'sched': 'fdp-50',   'gov': 'powersave-y' },
        { 'sched': 'fdp-50',   'gov': 'schedutil-y' },
        { 'sched': 'local',    'gov': 'powersave-y' },
        { 'sched': 'local',    'gov': 'schedutil-y' },
    ],
    'latitude': [
        { 'sched': 'lp-0',   'gov': 'powersave-y' },
        { 'sched': 'lp-0',   'gov': 'schedutil-y' },
        { 'sched': 'fdp-50', 'gov': 'powersave-y' },
        { 'sched': 'fdp-50', 'gov': 'schedutil-y' },
        { 'sched': 'local',  'gov': 'powersave-y' },
        { 'sched': 'local',  'gov': 'schedutil-y' },
    ],
    'redha': [
        { 'sched': '5.4',    'gov': 'powersave-y' },
        { 'sched': '5.4',    'gov': 'schedutil-y' },
        { 'sched': 'fdp-50', 'gov': 'powersave-y' },
        { 'sched': 'fdp-50', 'gov': 'schedutil-y' },
        { 'sched': 'local',  'gov': 'powersave-y' },
        { 'sched': 'local',  'gov': 'schedutil-y' },
    ],
}

for b in benchmarks[host]:
    for s in schedulers[host]:
        data = df[(df['bench'] == b) & (df['sched'] == s['sched']) & (df['power'] == s['gov'])]
        if len(data) != 10:
            print('[{}] {} {} {}: got {} runs out of 10'.format(host, b, s['sched'], s['gov'], len(data)))
