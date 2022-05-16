#!/usr/bin/env python

# VEL3DA calibration parser
#
# Create the necessary CI calibration ingest information from an VEL3DAA calibration file

import csv
import datetime
import os
import shutil
import sys
import time
from common_code.cal_parser_template import Calibration


class VEL3DACalibration(Calibration):
    def __init__(self, serial):
        super(VEL3DACalibration, self).__init__()  
        self.coefficients = {}
        self.hdg_cal = []
        self.hx_cal = []
        self.hy_cal = []
        self.serial = serial
        self.type = 'VEL3DA'

    def read_cal(self, filename):
        with open(filename) as fh:
            for line in fh:
                parts = line.split(',')
                if not len(parts):  # skip blank lines
                    continue
                self.date = datetime.datetime.strptime(parts[0].split()[0],'%Y-%m-%d').strftime('%Y%m%d')
                self.hx_cal.append(float(parts[1]))
                self.hy_cal.append(float(parts[2]))
                heading = float(parts[4]) - 25
                if heading < 0:
                    heading = heading + 360
                self.hdg_cal.append(heading)
        self.coefficients['CC_hx_cal'] = self.hx_cal
        self.coefficients['CC_hy_cal'] = self.hy_cal
        self.coefficients['CC_hdg_cal'] = self.hdg_cal

def main():
    for path, directories, files in os.walk('VEL3DA/manufacturer'):
        for file in files:
            # Skip hidden files
            if file[0] == '.':
                continue
            serial = file.split('_')[1]
            cal = VEL3DACalibration(serial)
            cal.read_cal(os.path.join(path, file))
            cal.write_cal_info()
            cal.move_to_archive(cal.type, file)


if __name__ == '__main__':
    start_time = time.time()
    main()
    print('VEL3DA: %s seconds' % (time.time() - start_time))
