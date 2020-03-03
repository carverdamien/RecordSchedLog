#!/usr/bin/env python3.7
def main():
    walk_path = '/mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace'
    # /mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/HOST=i80/BENCH=nas_ep.C/POWER=performance-n/MONITORING=perf_stat.mem_load_uops_l3_miss_retired/TASKS=80/KERNEL=ipanema/1.tar
    path_match = '^/mnt/data/damien/git/carverdamien/SchedDisplay/examples/trace/HOST=i80/BENCH=[^/]+/POWER=performance-n/MONITORING=perf_stat.mem_load_uops_l3_miss_retired/TASKS=[^/]+/KERNEL=ipanema/.*tar$'
    # path_match = '^.*tar$'
    import os, re, json
    NAS = """.*/HOST=(?P<host>[^/]+)/BENCH=(?P<bench>nas[^/]+)/POWER=(?P<power>[^/]+)/MONITORING=(?P<monitoring>[^/]+)/TASKS=(?P<tasks>[^/]+)/KERNEL=(?P<kernel>[^/]+)/(?P<id>\d+).tar"""
    NAS = re.compile(NAS)
    def data(tar_path):
        data = {'path':tar_path}
        for match in [NAS]:
            try:
                data.update(match.match(tar_path).groupdict())
                return data
            except AttributeError as e:
                pass
        return data
    def handler_time_err(data, fname, fio):
        if os.path.basename(fname) == 'time.err':
            data['usr_bin_time'] = float(fio.read().decode().split('\n')[-2])
    MEM_LOAD_UOPS_L3_MISS_RETIRED = """\s*(?P<value>\S+)\s*mem_load_uops_l3_miss_retired.(?P<name>\S+)\s*"""
    MEM_LOAD_UOPS_L3_MISS_RETIRED = re.compile(MEM_LOAD_UOPS_L3_MISS_RETIRED)
    def handler_perf_stat_out(data, fname, fio):
        if os.path.basename(fname) == 'perf_stat.out':
            decode = fio.read().decode()
            lines = decode.split('\n')
            for l in lines:
                match = MEM_LOAD_UOPS_L3_MISS_RETIRED.match(l)
                if match:
                    value = int(re.sub(',','',match['value']))
                    name = 'mem_load_uops_l3_miss_retired.'+match['name']
                    data[name] = value
    def handler(data, fname, fio):
        for handler in [handler_time_err, handler_perf_stat_out]:
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
    print(df)
    df.to_pickle('nas_locality_with_perf_stat.pkl.gz', protocol=3)
    pass

def find(walk_path, path_match='.*'):
    import os, re
    match = re.compile(path_match)
    for dirpath, dirnames, filenames in os.walk(walk_path):
        for filename in filenames:
            to_match = os.path.join(dirpath, filename)
            if match.match(to_match):
                yield to_match

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
