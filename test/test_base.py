import fnmatch
import glob
import logging
import os
import unittest
from numbers import Number

import numpy as np
import pandas as pd
from datetime import datetime
from dateutil import parser
from nose.plugins.attrib import attr

logging.basicConfig()
log = logging.getLogger()
log.setLevel(logging.INFO)


class FileNameException(Exception):
    pass


@attr('UNIT')
class AssetManagementUnitTest(unittest.TestCase):
    TEST_ROOT = os.path.dirname(__file__)
    AM_ROOT = os.path.abspath(os.path.join(TEST_ROOT, '..'))
    BULK_ROOT = os.path.join(AM_ROOT, 'bulk')
    CAL_ROOT = os.path.join(AM_ROOT, 'calibration')
    CRUISE_ROOT = os.path.join(AM_ROOT, 'cruise')
    DEP_ROOT = os.path.join(AM_ROOT, 'deployment')
    VOCAB_ROOT = os.path.join(AM_ROOT, 'vocab')
    BULK_FILES_GLOB = os.path.join(BULK_ROOT, '*bulk_load-AssetRecord.csv')
    CRUISE_FILE = os.path.join(CRUISE_ROOT, 'CruiseInformation.csv')
    VOCAB_FILE = os.path.join(VOCAB_ROOT, 'vocab.csv')

    BULK_COLS_RENAME = {
        'ASSET_UID': 'uid',
        'TYPE': 'asset_type',
        'Mobile': 'mobile',
        'DESCRIPTION OF EQUIPMENT': 'description',
        'Manufacturer': 'manufacturer',
        'Model': 'model_number',
        "Manufacturer's Serial No./Other Identifier": 'serial_number',
        'Firmware Version': 'firmware_version',
        'ACQUISITION DATE': 'purchase_date',
        'ORIGINAL COST': 'purchase_price',
    }

    @classmethod
    def setUpClass(cls):
        """
        Read bulk load asset management data and save UID and serial numbers
        :return:
        """
        bulk_dataframes = []
        for filename in glob.glob(cls.BULK_FILES_GLOB):
            df = pd.read_csv(filename, na_values='', keep_default_na=False)
            df.dropna(how='all', inplace=True)
            bulk_dataframes.append(df)

        cls.bulk_data = pd.concat(bulk_dataframes)
        cls.bulk_data.rename(columns=cls.BULK_COLS_RENAME, inplace=True)
        cls.bulk_data.dropna(how='all', inplace=True)

        cls.cruise_data = pd.read_csv(cls.CRUISE_FILE)
        cls.reference_designators = set(pd.read_csv(cls.VOCAB_FILE).Reference_Designator)

    @staticmethod
    def valid_float(value):
        return isinstance(value, Number) and not np.isnan(value)

    @staticmethod
    def valid_time_format(timestamp):
        return timestamp == parser.parse(timestamp).isoformat()

    @staticmethod
    def isnan(val):
        return isinstance(val, Number) and np.isnan(val)

    @staticmethod
    def date_to_millis(date):
        try:
            if isinstance(date, float):
                date = str(int(date))
            dt = parser.parse(date)
            secs = (dt - datetime(1970, 1, 1)).total_seconds()
            return int(secs * 1000)

        except ValueError:
            return None

    @staticmethod
    def maybe_float(data):
        try:
            return float(data)
        except ValueError:
            return data

    @staticmethod
    def parse_cal_file(filepath):
        return pd.read_csv(filepath)

    @staticmethod
    def parse_dep_file(filepath):
        df = pd.read_csv(filepath)

        # drop lines beginning with #
        df = df[np.logical_not(df.CUID_Deploy.str.startswith('#'))]

        df['startDateTime'] = map(AssetManagementUnitTest.date_to_millis, df.startDateTime.values)
        df['stopDateTime'] = map(AssetManagementUnitTest.date_to_millis, df.stopDateTime.values)
        return df

    @staticmethod
    def _walk_files(root):
        for path, dirs, files in os.walk(root):
            for name in fnmatch.filter(files, '*.csv'):
                yield os.path.join(path, name)

    def walk_cal_files(self):
        return self._walk_files(self.CAL_ROOT)

    def walk_deployment_files(self):
        return self._walk_files(self.DEP_ROOT)

    @staticmethod
    def parse_cal_filename(filename):
        try:
            return os.path.basename(filename).replace('.csv', '').split("__")
        except Exception as e:
            log.exception('Exception parsing calibration filename')
            raise FileNameException(e.message)