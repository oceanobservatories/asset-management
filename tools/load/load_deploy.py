#!/usr/bin/env python
import os
import sys
import pandas as pd
import numpy as np
from dateutil import parser


source_dir = sys.argv[1]
dest_dir = sys.argv[2]


for f in os.listdir(source_dir):
    df = pd.read_csv(os.path.join(source_dir, f), index_col=None)
    start = []
    stop = []

    for t in df['startDateTime']:
        try:
            start.append(parser.parse(t))
        except (AttributeError, TypeError):
            start.append(None)

    for t in df['stopDateTime']:
        try:
            stop.append(parser.parse(t))
        except (AttributeError, TypeError):
            stop.append(None)

    df['startDateTime'] = start
    df['stopDateTime'] = stop

    # drop lines beginning with #
    df = df[np.logical_not(df.CUID_Deploy.str.startswith('#'))]

    # Drop water_depth and rename deployment_depth to depth until
    # the parser in uframe is updated to reflect these changes
    df.rename(columns={'deployment_depth': 'depth'}, inplace=True)
    df.drop('water_depth', 1, inplace=True)

    sheetname = f.replace('.csv', '')
    writer = pd.ExcelWriter(os.path.join(dest_dir, sheetname + '.xlsx'),
                            engine='xlsxwriter', datetime_format='yyyy-mm-ddThh:mm:ss')
    df.to_excel(writer, sheet_name=sheetname, index=False)
