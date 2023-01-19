import json
import os

import numpy as np
import pandas
import logging

from dateutil import parser
from nose.plugins.attrib import attr

from test.test_base import AssetManagementUnitTest, FileNameException

logging.basicConfig()
log = logging.getLogger()
log.setLevel(logging.INFO)


class NotFound(Exception):
    pass


@attr('UNIT')
class CalibrationFilesUnitTest(AssetManagementUnitTest):
    def setUp(self):
        """
        Read bulk load asset management data and save UID and serial numbers
        :return:
        """
        super(CalibrationFilesUnitTest, self).setUp()
        self.ids = {}  # dictionary of all the UIDs and corresponding serial numbers
        for _, record in self.bulk_data.iterrows():
            uid = str(record.uid)
            sn = str(record.serial_number)
            self.ids[uid] = sn

    @staticmethod
    def get_sheetref(filepath, value):
        name = value.replace('SheetRef:', '')
        sheetref_name = filepath.replace('.csv', '__%s.ext' % name)
        if not os.path.exists(sheetref_name):
            raise NotFound

        return pandas.read_csv(sheetref_name, header=None).as_matrix()

    def get_cal_values(self, filepath):
        df = self.parse_cal_file(filepath)
        for row in df.itertuples(index=False):
            if 'Sheet' in row.value:
                yield row.name, self.get_sheetref(filepath, row.name)
            else:
                yield row.name, np.array(json.loads(row.value))


    def check_filename(self, filename):
        errors = []

        try:
            uid, timestamp = self.parse_cal_filename(filename)
        except FileNameException:
            return ['Invalid calibration filename (%s)' % filename]

        if uid not in self.ids:
            errors.append('UID (%s) does not exist' % filename)

        try:
            dt = parser.parse(timestamp)
            if not timestamp == dt.date().isoformat().replace('-', ''):
                errors.append('Invalid timestamp (%s)' % filename)
        except ValueError:
            errors.append('Invalid timestamp (%s)' % filename)

        return errors

    def check_serial(self, filename):
        errors = []
        try:
            uid, _ = self.parse_cal_filename(filename)
        except FileNameException:
            return ['Unable to parse file (%s)' % filename]

        df = self.parse_cal_file(filename)
        serials = df.serial.values.astype('str')
        serials_set = set(serials)
        if len(serials_set) != 1:
            errors.append('Multiple serial numbers found (%s)' % filename)

        expected_serial = self.ids.get(uid)

        for serial in serials_set:
            if serial != expected_serial:
                errors.append('Serial does not match bulk load CAL(%r) != BULK(%r) (%s)' %
                              (serial, expected_serial, filename))

        return errors

    @staticmethod
    def check_sheetref(filename, value):
        try:
            CalibrationFilesUnitTest.get_sheetref(filename, value)
            return []
        except NotFound:
            return ['Cannot find sheetref (%s) (%s)' % (filename, value)]

    def check_values(self, filename):
        errors = []
        try:
            uid, _ = self.parse_cal_filename(filename)
        except FileNameException:
            return ['Unable to parse file (%s)' % filename]

        df = self.parse_cal_file(filename)
        values = df.value.values.astype('str')

        for value in values:
            if value.startswith('SheetRef:'):
                errors.extend(self.check_sheetref(filename, value))

            else:
                try:
                    json.loads(value)
                except ValueError:
                    errors.append('Invalid JSON value (%s) (%r)' % (filename, value))

        return errors

    def assert_errors(self, errors):
        for error in errors:
            log.error(error)
        self.assertEqual(errors, [])

    def test_cal_columns(self):
        errors = []
        required = {'notes', 'value', 'name', 'serial'}

        for filepath in self.walk_cal_files():
            diff = required.difference(self.parse_cal_file(filepath).columns)

            if diff:
                errors.append('Cal: {} does not contain required column(s) {}.'.format(filepath, diff))

        self.assert_errors(errors)

    def test_filename(self):
        errors = []
        for filepath in self.walk_cal_files():
            errors.extend(self.check_filename(filepath))

        self.assert_errors(errors)

    def test_serial(self):
        errors = []
        for filepath in self.walk_cal_files():
            errors.extend(self.check_serial(filepath))

        self.assert_errors(errors)

    def test_values(self):
        errors = []
        for filepath in self.walk_cal_files():
            errors.extend(self.check_values(filepath))

        self.assert_errors(errors)

    def test_class_variables(self):
        # the following are allowed to vary within the instrument class
        # due to DOFST constants being included on cabled CTDPFA
        # and DOSTAD inconsistenly defining CC_ct_depth, which will be removed
        # in favor of deployed instrument depth
        # and METBKA that contains cal csvs for METLGRs and METCTD
        allowed_diff = {
            'CTDPFA': {
                'CC_residual_temperature_correction_factor_b',
                'CC_residual_temperature_correction_factor_c',
                'CC_residual_temperature_correction_factor_a',
                'CC_residual_temperature_correction_factor_e',
                'CC_oxygen_signal_slope',
                'CC_frequency_offset',
                'CC_voltage_offset',
            },
            'DOSTAD': {
                'CC_ct_depth'
            },
            'METBKA': {
                'CC_a0',
                'CC_a1',
                'CC_a2',
                'CC_a3',
                'CC_g',
                'CC_h',
                'CC_i',
                'CC_j',
                'CC_ctcor',
                'CC_cpcor',
                'CC_wbotc',
                'CC_depth_of_conductivity_and_temperature_measurements_m',
                'CC_height_of_air_humidity_measurement_m',
                'CC_height_of_air_temperature_measurement_m',
                'CC_height_of_windspeed_sensor_above_sealevel_m',
                'CC_jcool',
                'CC_jwarm',
                'CC_zinvpbl',
                'CC_use_velpt'
            }
        }

        klass_dict = {}
        for filepath in self.walk_cal_files():
            inst_klass = os.path.basename(os.path.dirname(filepath))
            names = self.parse_cal_file(filepath).name.values
            klass_dict.setdefault(inst_klass, []).append((filepath, names))

        errors = []
        for klass in klass_dict:
            name_set = None
            for filepath, names in klass_dict[klass]:
                if name_set is None:
                    name_set = set(names)
                else:
                    diff = name_set.symmetric_difference(names)
                    diff = diff.difference(allowed_diff.get(klass, set()))
                    if diff:
                        errors.append('Inconsistent set of parameters for instrument class %s %s %s' %
                                      (klass, diff, filepath))

        self.assert_errors(errors)

    def test_optaa_shapes(self):
        # Because OPTAA cal data is so large it's easy to miss a mismatch
        # in data shapes. Test for this
        errors = []
        optaa_files = (filepath for filepath in self.walk_cal_files() if 'OPTAA' in filepath)
        for filepath in optaa_files:
            data = {k: v for k, v in self.get_cal_values(filepath)}
            if any((data['CC_acwo'].shape != data['CC_ccwo'].shape,
                    data['CC_acwo'].shape != data['CC_ccwo'].shape,
                    data['CC_acwo'].shape != data['CC_awlngth'].shape,
                    data['CC_acwo'].shape != data['CC_cwlngth'].shape,
                    data['CC_acwo'].shape + data['CC_tbins'].shape != data['CC_tcarray'].shape,
                    data['CC_acwo'].shape + data['CC_tbins'].shape != data['CC_taarray'].shape)):
                errors.append('Inconsistent shapes for %s %r' % (filepath, { k: data[k].shape for k in data}))
        self.assert_errors(errors)
