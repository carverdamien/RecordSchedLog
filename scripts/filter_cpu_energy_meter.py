#!/usr/bin/env python3.7
import pandas as pd
import sys

_, output_csv, input_csv = sys.argv
df = pd.read_csv(input_csv, sep=';')
max_energy = 100000
sel = df['energy']>max_energy
above = df[sel]
below = df[~sel]
print(f"max_energy={max_energy}: {len(above)} above, {len(below)} below")
above['fname'].to_csv(output_csv, index=False, header=False)
