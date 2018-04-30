#!/usr/bin/env python

# SPKIR calibration parser
#
# Create the necessary CI calibration ingest information from an SPKIR calibration file
# These scripts are based on ones available

import csv
import datetime
import os
import sys
import time
import json
from dateutil.parser import parse
from common_code.cal_parser_template import Calibration, get_uid_serial_mapping

class SPKIRCalibration(Calibration):
    def __init__(self):
        super(SPKIRCalibration, self).__init__()
        self.offset = []
        self.scale = []
        self.immersion_factor = []
        self.type = 'SPKIRA'

    def read_cal(self, filename):
        with open(filename) as fh:
            read_record = False  # indicates next line is record we want to read
            for line in fh:
                parts = line.split()
                if "OCR-507" in line:
                    self.serial = str(parts[-2]).lstrip('0')
                elif not len(parts):  # skip blank lines
                    continue
                elif '#' == parts[0]:
                    try:
                        parse(parts[1])
                    except ValueError:
                        continue
                    self.date = str(parts[1]).replace('-','')

                elif parts[0] == 'ED':
                    read_record = True
                    continue
                elif read_record:
                    if len(parts) == 3:  # only parse if we have all the data
                        offset, scale, factor = parts
                        self.offset.append(float(offset))
                        self.scale.append(float(scale))
                        self.immersion_factor.append(float(factor))
                        self.coefficients['CC_offset'] = json.dumps(self.offset)
                        self.coefficients['CC_scale'] = json.dumps(self.scale)
                        self.coefficients['CC_immersion_factor'] = self.immersion_factor
                        read_record = False


def main():
    lookup = get_uid_serial_mapping('SPKIRA/spkir_lookup.csv')
    for path, directories, files in os.walk('SPKIRA/manufacturer'):
        for file in files:
            cal = SPKIRCalibration()
            cal.read_cal(os.path.join(path, file))
            cal.asset_tracking_number = lookup[cal.serial]
            cal.write_cal_info()

if __name__ == '__main__':
    start_time = time.time()
    main()
    print("SPKIR: %s seconds" % (time.time() - start_time))
