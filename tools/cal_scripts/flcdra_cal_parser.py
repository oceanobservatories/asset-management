#!/usr/bin/env python

# FLCDRA calibration parser
#
# Create the necessary CI calibration ingest information from an FLCDRA calibration file

import csv
import datetime
import os
import sys
import time
from common_code.cal_parser_template import Calibration, get_uid_serial_mapping

class FLCDRACalibration(Calibration):
    def __init__(self):
        super(FLCDRACalibration, self).__init__()
        self.dark = 0
        self.scale = 0.0
        self.type = "FLCDRA"

    def read_cal(self, filename):
        with open(filename) as fh:
            for line in fh:
                parts = line.split()
                if not len(parts):  # skip blank lines
                    continue
                if 'ECO' == parts[0]:
                    self.serial = parts[-1]
                elif 'Created' == parts[0]:
                    self.date = datetime.datetime.strptime(parts[-1], '%m/%d/%Y').strftime('%Y%m%d')
                deconstruct = parts[0].split('=')
                if deconstruct[0] == 'CDOM':
                    self.dark = parts[-1]
                    self.scale = parts[1]
                    self.coefficients['CC_dark_counts_cdom'] = self.dark
                    self.coefficients['CC_scale_factor_cdom'] = self.scale

def main():
    lookup = get_uid_serial_mapping('FLCDRA/flcdra_lookup.csv')
    for path, directories, files in os.walk('FLCDRA/manufacturer'):
        for file in files:
            cal = FLCDRACalibration()
            cal.read_cal(os.path.join(path, file))
            cal.asset_tracking_number = lookup[cal.serial]
            cal.write_cal_info()

if __name__ == '__main__':
    start_time = time.time()
    main()
    print("FLCDRA: %s seconds" % (time.time() - start_time))
