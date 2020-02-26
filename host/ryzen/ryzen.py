#!/usr/bin/env python3.7

def main():
    walk_path = '/home/damien/git/carverdamien/trace-cmd/TraceDisplay/examples/trace'
    # walk_path = '/home/damien/git/carverdamien/trace-cmd/TraceDisplay/examples/trace/HOST=ryzen/BENCH=kbuild-all'
    path_match = '^.*tar$'
    import os, re, json
    KBUILD = """.*/HOST=(?P<host>[^/]+)/BENCH=(?P<bench>kbuild[^/]+)/CMDLINE=(?P<cmdline>[^/]+)/GOVERNOR=(?P<governor>[^/]+)/MONITORING=(?P<monitoring>[^/]+)/TASKS=(?P<tasks>[^/]+)/KERNEL=(?P<kernel>[^/]+)/?(?P<sysctl>[^/]*)/(?P<id>\d+).tar"""
    KBUILD = re.compile(KBUILD)
    HACKBENCH = """.*/HOST=(?P<host>[^/]+)/BENCH=(?P<bench>hackbench)/CMDLINE=(?P<cmdline>[^/]+)/GOVERNOR=(?P<governor>[^/]+)/MONITORING=(?P<monitoring>[^/]+)/TASKS=(?P<tasks>[^/]+)/KERNEL=(?P<kernel>[^/]+)/?(?P<sysctl>[^/]*)/(?P<id>\d+).tar"""
    HACKBENCH = re.compile(HACKBENCH)
    PHORONIX = """.*/HOST=(?P<host>[^/]+)/BENCH=(?P<bench>phoronix)/CMDLINE=(?P<cmdline>[^/]+)/GOVERNOR=(?P<governor>[^/]+)/MONITORING=(?P<monitoring>[^/]+)/PHORONIX=(?P<phoronix>[^/]+)/KERNEL=(?P<kernel>[^/]+)/?(?P<sysctl>[^/]*)/(?P<id>\d+).tar"""
    PHORONIX = re.compile(PHORONIX)
    NAS = """.*/HOST=(?P<host>[^/]+)/BENCH=(?P<bench>nas[^/]+)/CMDLINE=(?P<cmdline>[^/]+)/GOVERNOR=(?P<governor>[^/]+)/MONITORING=(?P<monitoring>[^/]+)/TASKS=(?P<tasks>[^/]+)/KERNEL=(?P<kernel>[^/]+)/?(?P<sysctl>[^/]*)/(?P<id>\d+).tar"""
    NAS = re.compile(NAS)
    LLVMCMAKE = """.*/HOST=(?P<host>[^/]+)/BENCH=(?P<bench>llvmcmake)/CMDLINE=(?P<cmdline>[^/]+)/GOVERNOR=(?P<governor>[^/]+)/MONITORING=(?P<monitoring>[^/]+)/KERNEL=(?P<kernel>[^/]+)/?(?P<sysctl>[^/]*)/(?P<id>\d+).tar"""
    LLVMCMAKE = re.compile(LLVMCMAKE)
    def data(tar_path):
        data = {'path':tar_path}
        for match in [KBUILD, HACKBENCH, PHORONIX, NAS, LLVMCMAKE]:
            try:
                data.update(match.match(tar_path).groupdict())
                return data
            except AttributeError as e:
                pass
        return data
    def handler_time_err(data, fname, fio):
        if os.path.basename(fname) == 'time.err':
            data['usr_bin_time'] = float(fio.read().decode().split('\n')[-2])
    def handler_phoronix_json(data, fname, fio):
        if os.path.basename(fname) == 'phoronix.json':
            try:
                data['phoronix_value'] = float(json.loads(fio.read())['results'][0]['results']['schedrecord']['value'])
            except Exception as e:
                print(e)
                pass
    def handler_turbostat_out(data, fname, fio):
        if os.path.basename(fname) == 'turbostat.out':
            HEADER = """^(?P<key>[^:]+): *(?P<value>.*)$"""
            HEADER = re.compile(HEADER)
            lines = iter(fio.read().decode().split('\n'))
            version = next(lines)
            # print(version)
            n = next(lines)
            d = HEADER.match(n)
            while d:
                # print(d.groupdict())
                n = next(lines)
                d = HEADER.match(n)
            TIME_IN_SEC = """^(?P<time_in_sec>[^ ]+) sec$"""
            TIME_IN_SEC = re.compile(TIME_IN_SEC)
            time_in_sec = float(TIME_IN_SEC.match(n).groupdict()['time_in_sec'])
            # print(time_in_sec)
            n = next(lines)
            # print(n)
            COLUMNS = """\S+"""
            COLUMNS = re.compile(COLUMNS)
            columns = COLUMNS.findall(n)
            # print(columns)
            n = next(lines)
            total = COLUMNS.findall(n)
            # print(total)
            row = []
            n = next(lines)
            d = COLUMNS.findall(n)
            while d:
                # print(d)
                row.append(d)
                n = next(lines)
                d = COLUMNS.findall(n)
            # print(row)
            for i in range(len(columns)):
                col = columns[i]
                val = total[i]
                if val == '-':
                    continue
                data[col] = float(val)
            data['energy'] = (data['CorWatt'] + data['PkgWatt']) * time_in_sec
    def handler(data, fname, fio):
        for handler in [handler_turbostat_out, handler_phoronix_json, handler_time_err]:
            handler(data, fname, fio)
        pass
    data = [
        tar_extract(tar_path, handler=handler,
                    data=data(tar_path))
        for tar_path in find(walk_path, path_match)
    ]
    import pandas as pd
    # import numpy as np
    pd.options.display.max_rows = 999
    pd.options.display.max_columns = 999
    pd.options.display.max_colwidth = 999999
    pd.options.display.width = 9999
    df = pd.DataFrame(data)
    # print(df)
    df = df[df['monitoring'] == 'turbostat']
    # df['path'] = df['path']
    # df['energy'] = float('Nan')
    df['power'] = 'schedutil-y'
    sel_phoronix = ~df['phoronix'].isnull()
    df['bench'][sel_phoronix] = df['phoronix'][sel_phoronix]
    sel_tasks = ~df['tasks'].isnull()
    sel = (~sel_phoronix)&sel_tasks
    df['bench'][sel] = df['bench'][sel] + '-' + df['tasks'][sel]
    df['sched'] = df['kernel']
    df['perf'] = df['usr_bin_time']
    df['perf'][~sel_phoronix] = df['usr_bin_time'][~sel_phoronix]
    df['perf'][sel_phoronix] = df['phoronix_value'][sel_phoronix]
    mandatory_columns = ['bench', 'power', 'sched', 'id', 'perf', 'path']
    keep_columns = mandatory_columns + ['energy']
    drop_columns = list(filter(lambda x: x not in keep_columns, df.columns))
    df.drop(columns=drop_columns, inplace=True)
    df.dropna(subset=mandatory_columns, inplace=True)
    print(df)
    df.to_pickle('ryzen.pkl.gz', protocol=3)
    pass

def find(walk_path, path_match='.*'):
    import os, re
    match = re.compile(path_match)
    for dirpath, dirnames, filenames in os.walk(walk_path):
        for filename in filenames:
            if match.match(filename):
                yield os.path.join(dirpath, filename)

def tar_extract(tar_path, handler=lambda data,fname,fio:None, data={}):
    import tarfile
    with tarfile.open(tar_path) as tar:
        for tarinfo in tar.getmembers():
            handler(data,
                    tarinfo.name,
                    tar.extractfile(tarinfo),
            )
    return data

if __name__ == '__main__':
    main()
