import csv
import json
import logging
import os
import time
import unittest
from bisect import bisect
from collections import OrderedDict
from datetime import datetime
from glob import glob
from numbers import Number
from pprint import pformat

import javaobj
import numpy as np
import pandas as pd
import psycopg2
import requests
from dateutil import parser
from xlrd import XLRDError

from ..test_base import AssetManagementUnitTest

logging.basicConfig()
log = logging.getLogger()
log.setLevel(logging.INFO)


class AssetManagementIntegrationTest(AssetManagementUnitTest):
    def setUp(self):
        self.amhost = 'localhost'
        self.refdes = 'CE04OSPS-SF01B-2A-CTDPFA107'
        self.conn = psycopg2.connect(host='localhost', database='metadata', user='awips')
        self.maxDiff = None

    @classmethod
    def setUpClass(cls):
        """
        Read bulk load asset management data and save UID and serial numbers
        :return:
        """
        bulk_dataframes = []
        for filename in glob(cls.BULK_FILES_GLOB):
            if 'unclassified' in filename:
                continue
            df = pd.read_csv(filename, na_values='', keep_default_na=False)
            df.dropna(how='all', inplace=True)
            bulk_dataframes.append(df)

        cls.bulk_data = pd.concat(bulk_dataframes)
        cls.bulk_data.rename(columns=cls.BULK_COLS_RENAME, inplace=True)
        cls.bulk_data.dropna(how='all', inplace=True)

        cls.cruise_data = pd.read_csv(cls.CRUISE_FILE)

    def rename_bulk_entry(self, data):
        self.am_name_map = {
            'modelNumber': 'model_number',
            'purchasePrice': 'purchase_price',
            'purchaseDate': 'purchase_date',
            'serialNumber': 'serial_number',
            'firmwareVersion': 'firmware_version',
            'assetType': 'asset_type',
        }

        out = {}
        for k, v in data.iteritems():
            k = self.am_name_map.get(k, k)

            if isinstance(v, unicode):
                v = str(v)
            elif v is None:
                v = ''
            elif self.isnan(v):
                v = ''
            if k == 'asset_type' and v == 'Mooring':
                v = 'Platform'
            out[k] = v
        return out

    @staticmethod
    def get_asset_record(uid):
        return requests.get('http://localhost:12587/asset', params={'uid': uid}).json()

    @staticmethod
    def get_deployment_record(refdes, deployment):
        subsite, node, sensor = refdes.split('-', 2)
        return requests.get('http://localhost:12587/events/deployment/inv/%s/%s/%s/%s' %
                            (subsite, node, sensor, deployment)).json()

    @staticmethod
    def build_cal_value(data):
        return data['value']

    @staticmethod
    def build_cal_timestamp(data):
        return datetime.utcfromtimestamp(data['eventStartTime'] / 1000)

    def get_cal_dict(self, uid):
        asset = self.get_asset_record(uid)
        cal_dict = {}
        for calibration in asset.get('calibration', []):
            name = calibration['name']
            data = calibration['calData']
            for each in data:
                notes = each['comments']
                value = self.build_cal_value(each)
                timestamp = self.build_cal_timestamp(each)
                cal_dict.setdefault(timestamp, {})[name] = value, notes
        return cal_dict

    def assert_bulk_entry(self, row):
        # retrieve the asset
        asset = self.get_asset_record(row['uid'])
        asset_map = self.rename_bulk_entry(asset)

        keys = set(row).intersection(set(asset_map))

        asset_map = {k: v for k, v in asset_map.iteritems() if k in keys}
        row_map = {k: v for k, v in row.iteritems() if k in keys}
        self.assertDictEqual(asset_map, row_map)

    def assert_cal_entry(self, df, uid, timestamp):
        cal_dict = self.get_cal_dict(uid)
        cal_times = sorted(cal_dict)
        cal_index = bisect(cal_times, timestamp)

        self.assertNotEqual(cal_index, 0, msg='No calibration data for UID (%s) at timestamp (%s)' % (uid, timestamp))

        my_cal = cal_dict[cal_times[cal_index-1]]
        for serial, name, value, notes in df.itertuples(index=False):
            found = my_cal.get(name)
            self.assertIsNotNone(found, msg='No calibration entry found for %s for UID (%s) at timestamp (%s) %r'
                                            % (name, uid, timestamp, my_cal.keys()))
            found_value, found_notes = found

            if self.isnan(notes):
                notes = None

            if isinstance(value, basestring):
                if value.startswith('SheetRef:'):
                    # TODO - read sheetref and verify values
                    continue
                else:
                    value = json.loads(value)

            np.testing.assert_almost_equal(found_value, value)
            self.assertEqual(found_notes, notes)

    def skip_invalid_deployment(self, row):
        return self.isnan(row['mooring.uid']) or \
            self.isnan(row['sensor.uid']) or \
            self.isnan(row['startDateTime'])

    def assert_deployment_entry(self, row):
        # These invalid records are already caught by the unit tests
        # skip them here so we can test all valid records
        if self.skip_invalid_deployment(row):
            return

        row_dict = row.to_dict()
        for k, v in row_dict.iteritems():
            if self.isnan(v):
                row_dict[k] = None

        refdes = row_dict['Reference Designator']
        dnum = row_dict['deploymentNumber']

        deployment = self.get_deployment_record(refdes, dnum)
        self.assertEqual(len(deployment), 1, msg='Wrong number of deployments found %s %s %d' %
                                                 (refdes, dnum, len(deployment)))
        deployment = deployment[0]

        deploy_cruise = deployment.get('deployCruiseInfo')
        recover_cruise = deployment.get('recoverCruiseInfo')
        mooring = deployment.get('mooring')
        node = deployment.get('node')
        sensor = deployment.get('sensor')
        deploy_cruise = None if deploy_cruise is None else deploy_cruise['uniqueCruiseIdentifier']
        recover_cruise = None if recover_cruise is None else recover_cruise['uniqueCruiseIdentifier']
        mooring = None if mooring is None else mooring['uid']
        node = None if node is None else node['uid']
        sensor = None if sensor is None else sensor['uid']

        location = deployment.get('location')
        location = {} if location is None else location
        lat = location.get('latitude')
        lon = location.get('longitude')
        orbit = location.get('orbitRadius')
        depth = location.get('depth')
        water_depth = deployment.get('waterDepth')

        try:
            self.assertEqual(deploy_cruise, row_dict['CUID_Deploy'])
            self.assertEqual(deployment.get('deployedBy'), row_dict['deployedBy'])
            self.assertEqual(recover_cruise, row_dict['CUID_Recover'])
            self.assertEqual(deployment.get('recoveredBy'), row_dict['recoveredBy'])
            self.assertEqual(deployment.get('eventName'), row_dict['Reference Designator'])
            self.assertEqual(deployment.get('deploymentNumber'), row_dict['deploymentNumber'])
            self.assertEqual(deployment.get('versionNumber'), row_dict['versionNumber'])
            self.assertEqual(deployment.get('eventStartTime'), row_dict['startDateTime'])
            self.assertEqual(deployment.get('eventStopTime'), row_dict['stopDateTime'])
            self.assertEqual(mooring, row_dict['mooring.uid'])
            self.assertEqual(node, row_dict['node.uid'])
            self.assertEqual(sensor, row_dict['sensor.uid'])
            np.testing.assert_almost_equal(lat, row_dict['lat'])
            np.testing.assert_almost_equal(lon, row_dict['lon'])
            self.assertEqual(orbit, row_dict['orbit'])
            self.assertEqual(depth, row_dict['deployment_depth'])
            self.assertEqual(water_depth, row_dict['water_depth'])
        except AssertionError:
            log.error(pformat(row_dict))
            log.error(pformat(deployment))
            raise

    def test_bulk_load(self):
        df = self.bulk_data
        df = df.fillna({'mobile': 0})
        df['mobile'] = df.mobile.values.astype(bool)
        df['purchase_date'] = map(self.date_to_millis, df.purchase_date.values)
        df['purchase_price'] = map(self.maybe_float, df.purchase_price.values)
        df = df.fillna('')
        for _, row in df.iterrows():
            self.assert_bulk_entry(row.to_dict())

    def test_cal_load(self):
        for path in self.walk_cal_files():
            uid, timestamp = self.parse_cal_filename(path)
            dt = parser.parse(timestamp)
            df = self.parse_cal_file(path)
            self.assert_cal_entry(df, uid, dt)

    def test_deployment_load(self):
        for path in self.walk_deployment_files():
            df = self.parse_dep_file(path)
            for _, row in df.iterrows():
                self.assert_deployment_entry(row)

    # def assert_cal_times(self, calibrations, asset, dstart, dstop):
    #     if not calibrations:
    #         return
    #
    #     # verify that one of the calibrations is valid for this deployment
    #     cal_dict = {}
    #     for cal in calibrations:
    #         name = cal['name']
    #         # print name, len(cal['calData'])
    #         for each in cal['calData']:
    #             cstart = each['eventStartTime']
    #
    #             cal_asset = each['assetUid']
    #             self.assertEqual(asset, cal_asset)
    #             # print name, cal_asset, cstart
    #             cal_dict.setdefault(name, []).append(cstart)
    #
    #     # assert that there are an equal number of cals for each deployment
    #     lengths = {len(x) for x in cal_dict.values()}
    #     if len(lengths) != 1:
    #         print 'missing cal values? asset: %s cals: %s' % (asset, cal_dict)
    #     # self.assertEqual(len(lengths), 1, msg='missing cal values? asset: %s cals: %s' % (asset, cal_dict))
    #     import pprint
    #     pprint.pprint(cal_dict)
    #
    # def assert_events(self, events):
    #     self.assertEqual(len(events), 1)
    #     now = time.time() * 1000
    #     deployment = events[0]
    #     dstart = deployment['eventStartTime']
    #     dstop = deployment['eventStopTime']
    #     sensor = deployment['sensor']
    #     asset = sensor['uid']
    #     calibrations = sensor['calibration']
    #     if not dstop:
    #         dstop = now
    #
    #     self.assert_cal_times(calibrations, asset, dstart, dstop)
    #
    # def test_all_cals(self):
    #     import requests
    #     base_url = 'http://localhost:12587/events/deployment/inv'
    #     subsites = requests.get(base_url).json()
    #     for subsite in subsites:
    #         nodes = requests.get('%s/%s' % (base_url, subsite)).json()
    #         for node in nodes:
    #             sensors = requests.get('%s/%s/%s' % (base_url, subsite, node)).json()
    #             for sensor in sensors:
    #                 deployments = requests.get('%s/%s/%s/%s' % (base_url, subsite, node, sensor)).json()
    #                 for deployment in deployments:
    #                     events = requests.get('%s/%s/%s/%s/%d' % (base_url, subsite, node, sensor, deployment)).json()
    #                     print subsite, node, sensor, deployment
    #                     self.assert_events(events)
    #         break
    #         # print subsite, node, sensor, deployment, events
    #     assert subsites is False
    #
    # def make_array(self, dimensions, values):
    #     if dimensions == [1] and len(values) == 1:
    #         return values[0]
    #
    #     a = np.array(values)
    #     return list(np.reshape(a, dimensions))
    #
    # def assert_cal_value(self, refdes, depnum, uid, start, name, value, adj_time=False):
    #     # print repr(uid), start, repr(name), repr(value)
    #     cur = self.conn.cursor()
    #     never = False
    #
    #     if adj_time:
    #         cur.execute('''
    #         select eventstarttime/1000
    #             from xasset xa, xdeployment xd, xevent xe
    #             where xa.assetid=xd.sassetid and xd.eventid=xe.eventid and xa.uid=%s and eventstarttime >= %s
    #             order by eventstarttime limit 1''', (uid, start * 1000))
    #         row = cur.fetchone()
    #         if row:
    #             start = row[0]
    #         else:
    #             never = True
    #
    #     cur.execute(
    #         'select name, dimensions, values, eventstarttime from xcalibration xc, xcalibrationdata xcd, xevent xe where xc.calid = xcd.calid and xe.eventid = xcd.eventid and assetuid=%s and name=%s',
    #         (uid, name))
    #     rows = cur.fetchall()
    #     values = []
    #     for name, dims, vals, t in rows:
    #         try:
    #             if dims is not None and vals is not None:
    #                 dims = javaobj.loads(dims)
    #                 vals = javaobj.loads(vals)
    #                 a = self.make_array(dims, vals)
    #                 t /= 1000.0
    #                 values.append((t, a))
    #         except IOError:
    #             print name, repr(dims), repr(vals)
    #
    #     rvalues = [datetime.utcfromtimestamp(x).isoformat() for x, y in values]
    #
    #     if not values and never:
    #         rval = 'neverdeployed', refdes, depnum, name, uid, start, datetime.utcfromtimestamp(
    #             start).isoformat(), str(value)[:20], rvalues
    #         print rval
    #         return rval
    #
    #     if not values:
    #         rval = 'missing', refdes, depnum, name, uid, start, datetime.utcfromtimestamp(start).isoformat(), str(value)[:20], rvalues
    #         print rval
    #         return rval
    #
    #     values.sort()
    #     times = [v[0] for v in values]
    #     index = bisect(times, start)
    #
    #     if index <= 0:
    #         rval = 'notfound', refdes, depnum, name, uid, start, datetime.utcfromtimestamp(start).isoformat(), str(value)[:20], rvalues
    #         print rval
    #         return rval
    #
    #     t, expected = values[index - 1]
    #     try:
    #         np.testing.assert_array_almost_equal(expected, value)
    #     except AssertionError:
    #         rval = 'mismatch', refdes, depnum, name, uid, start, datetime.utcfromtimestamp(start).isoformat(), str(value)[:20], rvalues
    #         print rval
    #         return rval
    #
    # def test_new_spreadsheets(self):
    #     import pandas as pd
    #     unix_epoch = datetime(1970, 1, 1)
    #     results = []
    #     for filename in glob('/Users/petercable/src/asset-management/ARCHIVE/refactored_asset_management/Calibration/*xlsx'):
    #         print filename
    #         sheets = pd.read_excel(filename, sheetname=None)
    #         cal_sheets = [sheet for sheet in sheets if 'Cal_Info' in sheet]
    #         for sheet in cal_sheets:
    #             df = sheets[sheet]
    #             try:
    #                 df = df[
    #                     ['Sensor.uid', 'startDateTime', 'Calibration Cofficient Name', 'Calibration Cofficient Value']]
    #                 df = df.dropna(how='all')
    #                 for each in df.itertuples(index=False):
    #                     uid, start, name, value = each
    #                     if (isinstance(uid, float) and np.isnan(uid) or
    #                                 isinstance(name, float) and np.isnan(name) or
    #                                 isinstance(value, float) and np.isnan(value)):
    #                         continue
    #
    #                     if isinstance(value, basestring):
    #                         try:
    #                             value = json.loads(value)
    #                         except ValueError:
    #                             continue
    #                     start = (start - unix_epoch).total_seconds()
    #                     result = self.assert_cal_value(None, None, uid, start, name, value, adj_time=True)
    #                     if result:
    #                         results.append(result)
    #             except (XLRDError):
    #                 pass
    #
    #     print len(results)
    #     with open('new_results.csv', 'w') as fh:
    #         writer = csv.writer(fh)
    #         writer.writerows(results)
    #     assert False
    #
    # def test_old_spreadsheets(self):
    #     skip = ['CC_lat', 'CC_lon', 'CC_latitude', 'CC_longitude', 'Inductive ID', 'Induction ID', 'CC_depth']
    #     unix_epoch = datetime(1970, 1, 1)
    #     results = []
    #     count = 0
    #     for filename in glob('/Users/petercable/src/asset-management/ARCHIVE/deployment/Omaha_Cal*xlsx'):
    #         print filename
    #         sheets = pd.read_excel(filename, sheetname=None)
    #         if 'Moorings' in sheets and 'Asset_Cal_Info' in sheets:
    #             moorings = sheets['Moorings']
    #             moorings = moorings[['Mooring OOIBARCODE', 'Deployment Number', 'Anchor Launch Date', 'Anchor Launch Time']]
    #             moorings = moorings.dropna(how='any')
    #             deployments = {}
    #
    #             for row in moorings.itertuples(index=False):
    #                 barcode, number, date, rowtime = row
    #
    #                 if date == rowtime:
    #                     dt = date
    #                 else:
    #                     if isinstance(time, datetime):
    #                         rowtime = rowtime.time()
    #                     dt = datetime.combine(date.date(), rowtime)
    #
    #                 deployments[(barcode, int(number))] = dt
    #
    #             all_moorings = list({x[0] for x in deployments})
    #
    #             df = sheets['Asset_Cal_Info']
    #             try:
    #                 df = df[
    #                     ['Ref Des', 'Mooring OOIBARCODE', 'Sensor OOIBARCODE', 'Deployment Number',
    #                      'Calibration Cofficient Name', 'Calibration Cofficient Value']]
    #                 df = df.dropna(how='all')
    #                 for each in df.itertuples(index=False):
    #                     refdes, mooring_uid, uid, deployment, name, value = each
    #
    #                     if name in skip:
    #                         continue
    #
    #                     if mooring_uid is None or isinstance(mooring_uid, float) and np.isnan(mooring_uid):
    #                         if len(all_moorings) == 1:
    #                             mooring_uid = all_moorings[0]
    #
    #                     start = deployments.get((uid, deployment))
    #                     if start is None:
    #                         start = deployments.get((mooring_uid, deployment))
    #                     if start is None:
    #                         print 'deployment not found', each, deployments
    #                         continue
    #
    #                     if (isinstance(uid, float) and np.isnan(uid) or
    #                                 isinstance(name, float) and np.isnan(name) or
    #                                 isinstance(value, float) and np.isnan(value)):
    #                         continue
    #
    #                     if isinstance(value, basestring):
    #                         try:
    #                             value = json.loads(value)
    #                         except ValueError:
    #                             continue
    #                     start = (start - unix_epoch).total_seconds()
    #                     count += 1
    #                     result = self.assert_cal_value(refdes, deployment, uid, start, name, value)
    #                     if result:
    #                         results.append(result)
    #             except (XLRDError, KeyError) as e:
    #                 print e
    #
    #     print len(results)
    #     print count
    #     with open('old_results.csv', 'w') as fh:
    #         writer = csv.writer(fh)
    #         writer.writerow(('reason', 'refdes', 'deployment', 'name', 'uid', 'start', 'start_ts', 'value', 'retrieved'))
    #         writer.writerows(results)
    #
    #     assert False
