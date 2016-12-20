import os
import pandas as pd
import glob
import shutil

# Base directory of asset-management
base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))

# UID Lookup tables
table_sensor = pd.read_csv(os.path.join(base_dir, 'bulk', 'sensor_bulk_load-AssetRecord.csv'))
table_platform = pd.read_csv(os.path.join(base_dir, 'bulk', 'platform_bulk_load-AssetRecord.csv'))

# Convert to dictionaries
platforms = dict(zip(table_platform['LEGACY_ASSET_UID'].values, table_platform['ASSET_UID'].values))
sensors = dict(zip(table_sensor['LEGACY_ASSET_UID'].values, table_sensor['ASSET_UID'].values))

# List all deployment csvs
deployments = glob.glob(os.path.join(base_dir, 'deployment', '*'))

# List all cal sheets
cal_dir = os.path.join(base_dir, 'calibration')
calibrations = []
for root, dirs, files in os.walk(cal_dir):
    for file in files:
        if file.endswith(('.csv', '.ext')):
            calibrations.append(os.path.join(root, file))

# Iterate through each calibration sheet name
for csv in calibrations:
    basename = os.path.basename(csv)
    ext = os.path.splitext(csv)
    if ext[1] == '.csv':
        strings = basename.replace('.csv', '').split('__')
        # Try to build the filename. If it can't be built, then it's incorrectly labeled. So skip it for now.
        try:
            filename = sensors[strings[0]] + '__' + strings[1] + '.csv'
        except KeyError:
            continue
    elif ext[1] == '.ext':
        strings = basename.replace('.ext', '').split('__')
        # Try to build the filename. If it can't be built, then it's incorrectly labeled. So skip it for now.
        try:
            filename = sensors[strings[0]] + '__' + strings[1] + '__' + strings[2] + '.ext'
        except KeyError:
            continue
    else:
        continue


    if not filename == basename:
        shutil.move(csv, os.path.join(os.path.dirname(csv), filename))

# Iterate through each deployment sheet
for deploy in deployments:
    n = False
    df = pd.read_csv(deploy)

    # Get list of unique mooring and sensor uid
    mooring_uid = df['mooring.uid'].unique().ravel()
    sensor_uid = df['sensor.uid'].unique().ravel()

    # Iterate through unique mooring_uid
    for mooring in mooring_uid:
        df_ind = df['mooring.uid'] == mooring
        try:
            if not mooring == platforms[mooring]:
                n = True
                df.loc[df_ind, 'mooring.uid'] = platforms[mooring]
        except KeyError:
            continue

    # Iterate through unique sensor_uid
    for sensor in sensor_uid:
        df_ind = df['sensor.uid'] == sensor
        try:
            if not sensor == sensors[sensor]:
                n = True
                df.loc[df_ind, 'sensor.uid'] = sensors[sensor]
        except KeyError:
            continue

    if n:
        df.to_csv(deploy, index=False)
