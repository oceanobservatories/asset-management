#!/usr/bin/env python

# FLNTUA calibration parser
#
# Create the necessary CI calibration ingest information from a
# FLNTUA calibration file

import csv
import datetime
import os
import shutil
import sys
import time
import json
from common_code.cal_parser_template import Calibration
from loguru import logger


class FLNTUACalibration(Calibration):
    def __init__(self):
        self.chl = None
        self.vol = None
        self.asset_tracking_number = None
        self.serial = None
        self.date = None
        self.type = 'FLNTUA'
        self.coefficients = {
            'CC_angular_resolution': 1.096,
            'CC_depolarization_ratio': 0.039,
            'CC_measurement_wavelength': 700,
            'CC_scattering_angle': 140
        }

    def read_cal(self, filename):
        with open(filename) as fh:
            for line in fh:
                parts = line.split()
                if not len(parts):  # skip blank lines
                    continue
                if 'ECO' == parts[0]:
                    # strip the funny chars that find their way into seabird serial numbers
                    self.serial = parts[1].replace("_", "").replace("BB", "")
                    logger.info(f"Serial number parsed from file {self.serial}")
                elif 'Created' == parts[0]:
                    self.date = datetime.datetime.strptime(
                        parts[-1], '%m/%d/%y').strftime('%Y%m%d')
                deconstruct = parts[0].split('=')
                if deconstruct[0].lower() == 'lambda':
                    self.vol = (parts[1], parts[2])
                    self.coefficients['CC_scale_factor_volume_scatter'] = parts[1]
                    self.coefficients['CC_dark_counts_volume_scatter'] = parts[2]
                elif deconstruct[0].upper() == 'NTU':
                    return False
                elif deconstruct[0] == 'Chl':
                    self.chl = (parts[1], parts[2])
                    self.coefficients['CC_scale_factor_chlorophyll_a'] = parts[1]
                    self.coefficients['CC_dark_counts_chlorophyll_a'] = parts[2]
        return True


def main():
    for path, directories, files in os.walk('FLNTUA/manufacturer'):
        for file in files:
            logger.info(f"File: {file}")
            # Skip hidden files
            if file[0] == '.':
                continue
            cal = FLNTUACalibration()
            if not cal.read_cal(os.path.join(path, file)):
                print("File does not have volume scatter: %s", file)
                continue
            cal.write_cal_info()
            cal.move_to_archive(cal.type, file)


if __name__ == '__main__':
    start_time = time.time()
    main()
    print('FLNTUA: %s seconds' % (time.time() - start_time))
