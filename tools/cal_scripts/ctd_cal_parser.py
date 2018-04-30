#!/usr/bin/env python

# CTD Calibration Parser
# Create the necessary CI calibration ingest information from an CTD calibration file

from __future__ import absolute_import
import csv
import datetime
import os
import sys
import time
import xml.etree.ElementTree as et
from common_code.cal_parser_template import Calibration, get_uid_serial_mapping

class CTDCalibration(Calibration):
    ## Class that stores calibration values for CTDs.
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
        # dictionary with calibration coefficient names and values
        self.coefficients = {}
        self.asset_tracking_number = None
        self.serial = '52-'
        self.date = None
        self.type = 'CTD'

    def read_xml(self, filename):
        # TODO: Finish up xml reading
        with open(filename) as fh:
            tree = et.parse(filename)
            root = tree.getroot()
            t_flag = False
            for child in tree.iter():
                key = child.tag.upper()
                if key == '':
                    continue

                if child.tag == "TemperatureSensor":
                    t_flag = True

                if t_flag and child.tag == 'Sensor':
                    t_flag = False

                elif t_flag:
                    key = 'T' + child.tag

                if child.tag == "SerialNumber" and child.text != None:
                    self.serial = '16-' + child.text

                if child.tag == "CalibrationDate" and child.text != None and self.date == None:
                    self.date = datetime.datetime.strptime(child.text, "%d-%b-%y").strftime("%Y%m%d")

                name = self.coefficient_name_map.get(key)
                if name is None:
                    continue
                self.coefficients[name] = child.text

    def read_cal(self, filename):
        ## Reads the calibration files and extracts out the necessary calibration values needed for CI.
        with open(filename) as fh:
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
                    self.date = datetime.datetime.strptime(value, "%d-%b-%y").strftime("%Y%m%d")

                name = self.coefficient_name_map.get(key)
                if not Name:
                    continue

                self.coefficients[name] = value

    def write_cal_info(self):
        inst_type = None
        if self.asset_tracking_number.find('66662') != -1:
            inst_type = 'CTDPFA'
        elif self.asset_tracking_number.find('67627') != -1:
            inst_type = 'CTDPFB'
        elif self.asset_tracking_number.find('67977') != -1:
            inst_type = 'CTDPFL'
        elif self.asset_tracking_number.find('69827') != -1:
            inst_type = 'CTDBPN'
        elif self.asset_tracking_number.find('69828') != -1:
            inst_type = 'CTDBPO'
        ## Writes the calibration information to a comma-separated value file
        complete_path = os.path.join(self.type, 'cal_sheets', inst_type)
        file_name = self.asset_tracking_number + '__' + self.date
        with open(os.path.join(complete_path, '%s.csv' % file_name), 'w') as info:
            writer = csv.writer(info)
            writer.writerow(['serial','name', 'value', 'notes'])
            for each in sorted(self.coefficients.items()):
                writer.writerow([self.serial] + list(each))
            if inst_type.startswith("CTDPF"):
                writer.writerow([self.serial, "CC_offset", 0])

def main():
    lookup = get_uid_serial_mapping('CTD/ctd_lookup.csv')
    for path, directories, files in os.walk('CTD/manufacturer'):
        for file in files:
            cal = CTDCalibration()
            with open(os.path.join(path, file)) as unknown_file:
                c = unknown_file.read(1)
                if c == '<':
                    cal.read_xml(os.path.join(path, file))
                else:
                    cal.read_cal(os.path.join(path, file))
                cal.asset_tracking_number = lookup[cal.serial]
                cal.write_cal_info()

if __name__ == '__main__':
    start_time = time.time()
    main()
    print("CTD: %s seconds" % (time.time() - start_time))
