#!/usr/bin/env python

# CTD Calibration Parser
# Create the necessary CI calibration ingest information from an CTD
# calibration file

from __future__ import absolute_import
import csv
import datetime
import os
import shutil
import sys
import time
import xml.etree.ElementTree as et
from common_code.cal_parser_template import Calibration


class CTDCalibration(Calibration):
    # Class that stores calibration values for CTDs.
    # \param self
    def __init__(self):
        self.coefficient_name_map = {
            'TA0': 'CC_a0',
            'TA1': 'CC_a1',
            'TA2': 'CC_a2',
            'TA3': 'CC_a3',
            'CPCOR': 'CC_cpcor',
            'CTCOR': 'CC_ctcor',
            'CG': 'CC_g',
            'CH': 'CC_h',
            'CI': 'CC_i',
            'CJ': 'CC_j',
            'G': 'CC_g',
            'H': 'CC_h',
            'I': 'CC_i',
            'J': 'CC_j',
            'PA0': 'CC_pa0',
            'PA1': 'CC_pa1',
            'PA2': 'CC_pa2',
            'PTEMPA0': 'CC_ptempa0',
            'PTEMPA1': 'CC_ptempa1',
            'PTEMPA2': 'CC_ptempa2',
            'PTCA0': 'CC_ptca0',
            'PTCA1': 'CC_ptca1',
            'PTCA2': 'CC_ptca2',
            'PTCB0': 'CC_ptcb0',
            'PTCB1': 'CC_ptcb1',
            'PTCB2': 'CC_ptcb2',
            # additional types for series O
            'C1': 'CC_C1',
            'C2': 'CC_C2',
            'C3': 'CC_C3',
            'D1': 'CC_D1',
            'D2': 'CC_D2',
            'T1': 'CC_T1',
            'T2': 'CC_T2',
            'T3': 'CC_T3',
            'T4': 'CC_T4',
            'T5': 'CC_T5',
        }
        self.o_series_coefficients_map = {
            'C1': 'CC_C1',
            'C2': 'CC_C2',
            'C3': 'CC_C3',
            'D1': 'CC_D1',
            'D2': 'CC_D2',
            'T1': 'CC_T1',
            'T2': 'CC_T2',
            'T3': 'CC_T3',
            'T4': 'CC_T4',
            'T5': 'CC_T5',
        }
        self.o2_coefficients_map = {
            'A': 'CC_residual_temperature_correction_factor_a',
            'B': 'CC_residual_temperature_correction_factor_b',
            'C': 'CC_residual_temperature_correction_factor_c',
            'E': 'CC_residual_temperature_correction_factor_e',
            'SOC': 'CC_oxygen_signal_slope',
            'OFFSET': 'CC_frequency_offset'
        }
        # dictionary with calibration coefficient names and values
        self.coefficients = {}
        self.asset_tracking_number = None
        self.serial = '16-'
        self.date = None
        self.type = 'CTD'

    def _read_xml(self, filename):
        if not filename.endswith('.xmlcon'):
            return False

        with open(filename) as fh:
            tree = et.parse(filename)
            root = tree.getroot()
            t_flag = False
            o2_sensor_flag = False
            for child in tree.iter():
                key = child.tag.upper()
                if key == 'OXYGENSENSOR':
                    o2_sensor_flag = True

                if key == '':
                    continue

                if child.tag == 'TemperatureSensor':
                    t_flag = True

                if t_flag and child.tag == 'Sensor':
                    t_flag = False

                elif t_flag:
                    key = 'T' + child.tag

                if child.tag == 'SerialNumber' and child.text is not None \
                                and self.serial == '16-':
                    self.serial = '16-' + child.text

                if child.tag == 'CalibrationDate' and child.text is not None \
                                and self.date is None:
                    self.date = datetime.datetime.strptime(
                        child.text, '%d-%b-%y').strftime('%Y%m%d')

                name = self.coefficient_name_map.get(key)
                o2_name = self.o2_coefficients_map.get(key)
                if name is None and o2_name is None:
                    continue
                elif name is not None:
                    self.coefficients[name] = child.text
                elif o2_sensor_flag:
                    self.coefficients[o2_name] = child.text
        return True

    def read_cal(self, filename):
        # Reads the calibration files and extracts out the necessary
        # calibration values needed for CI.
        if self._read_xml(filename):
            return
        with open(filename) as fh:
            c = fh.read(1)
            for line in fh:
                parts = line.split('=')
                if len(parts) != 2:
                    continue  # skip anything that is not key value paired

                key = parts[0]
                value = parts[1].strip()

                if key == 'INSTRUMENT_TYPE' and value == 'SEACATPLUS':
                    self.serial = '16-'

                if key == 'SERIALNO':
                    self.serial += value

                if key == 'CCALDATE':
                    self.date = datetime.datetime.strptime(value, '%d-%b-%y')\
                        .strftime('%Y%m%d')

                name = self.coefficient_name_map.get(key)
                if not name:
                    continue

                self.coefficients[name] = value

    def write_cal_info(self):
        inst_type = None
        if not self.assetID_lookup():
            return
        if self.asset_tracking_number.find('66662') != -1:
            inst_type = 'CTDPFA'
        elif self.asset_tracking_number.find('67627') != -1:
            inst_type = 'CTDPFB'
        elif self.asset_tracking_number.find('67977') != -1:
            inst_type = 'CTDPFL'
            return
        elif self.asset_tracking_number.find('69827') != -1:
            inst_type = 'CTDBPN'
        elif self.asset_tracking_number.find('69821') != -1:
            inst_type = 'CTDBPN'
        elif self.asset_tracking_number.find('69828') != -1:
            inst_type = 'CTDBPO'
        # Writes the calibration information to a comma-separated value file
        if not inst_type.startswith('CTDBP'):
            for key in self.o_series_coefficients_map.keys():
                try:
                    del self.coefficients[self.o_series_coefficients_map.get(
                        key)]
                except KeyError:
                    continue
        complete_path = os.path.join(self.type, 'cal_sheets', inst_type)
        complete_path = os.path.join(
            os.path.realpath('../..'), 'calibration', inst_type)
        file_name = self.asset_tracking_number + '__' + self.date
        with open(os.path.join(complete_path, '%s.csv' % file_name), 'w') as info:
            writer = csv.writer(info)
            writer.writerow(['serial', 'name', 'value', 'notes'])
            for each in sorted(self.coefficients.items()):
                row = [self.serial] + list(each)
                row.append('')
                writer.writerow(row)
            if inst_type.startswith('CTDPF'):
                writer.writerow([self.serial, 'CC_offset', 0, ''])


def main():
    for path, directories, files in os.walk('CTD/manufacturer'):
        for file in files:
            # Skip hidden files
            if file[0] == '.':
                continue
            cal = CTDCalibration()
            cal.read_cal(os.path.join(path, file))
            cal.write_cal_info()
            cal.move_to_archive(cal.type, file)


if __name__ == '__main__':
    start_time = time.time()
    main()
    print('CTD: %s seconds' % (time.time() - start_time))
