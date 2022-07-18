#!/usr/bin/env python

# FLOR calibration parser
#
# Create the necessary CI calibration ingest information from a FLOR calibration file

import csv
import datetime
import os
import shutil
import sys
import time
from common_code.cal_parser_template import Calibration


class FLORCalibration(Calibration):
    def __init__(self):
        self.cdom = None
        self.chl = None
        self.vol = None
        self.asset_tracking_number = None
        self.serial = None
        self.date = None
        self.type = 'FLORDD'
        self.coefficients = {'CC_angular_resolution': 1.076, 'CC_depolarization_ratio': 0.039,
                             'CC_measurement_wavelength': 700, 'CC_scattering_angle': 124}

    def read_cal(self, filename):
        with open(filename) as fh:
            for line in fh:
                parts = line.split()
                if not len(parts):  # skip blank lines
                    continue
                if 'BBFL2W' in parts[0]:
                    serial = parts[0].split('-')
                    self.serial = serial[-1]
                if 'ECO' == parts[0]:
                    serial = parts[1].split('-')
                    self.serial = serial[-1]
                elif 'Created' == parts[0]:
                    try:
                        self.date = datetime.datetime.strptime(parts[-1], '%m/%d/%y').strftime('%Y%m%d')
                    except ValueError:
                        try:
                            self.date = datetime.datetime.strptime(parts[-1], '%m/%d/%Y').strftime('%Y%m%d')
                        except ValueError:
                            print('Unanticipated Date Format: ', parts[-1])
                            sys.exit(1)  
                deconstruct = parts[0].upper().split('=')
                if deconstruct[0] == 'LAMBDA':
                    self.vol = (parts[1], parts[2])
                    self.coefficients['CC_scale_factor_volume_scatter'] = parts[1]
                    self.coefficients['CC_dark_counts_volume_scatter'] = parts[2]
                elif deconstruct[0] == 'CHL':
                    self.chl = (parts[1], parts[2])
                    self.coefficients['CC_scale_factor_chlorophyll_a'] = parts[1]
                    self.coefficients['CC_dark_counts_chlorophyll_a'] = parts[2]
                elif deconstruct[0] == 'CDOM':
                    self.cdom = (parts[1], parts[2])
                    self.coefficients['CC_scale_factor_cdom'] = parts[1]
                    self.coefficients['CC_dark_counts_cdom'] = parts[2]
                    break


def main():
    for path, directories, files in os.walk('FLOR/manufacturer'):
        for file in files:
            # Skip hidden files
            if file[0] == '.':
                continue
            cal = FLORCalibration()
            cal.read_cal(os.path.join(path, file))
            cal.write_cal_info()
            cal.move_to_archive('FLOR', file)


if __name__ == '__main__':
    start_time = time.time()
    main()
    print('FLOR: %s seconds' % (time.time() - start_time))
