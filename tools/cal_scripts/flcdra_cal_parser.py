#!/usr/bin/env python3

"""
FLCDRA Calibration Parser
Create the necessary CI calibration ingest information from a FLCDRA
calibration file.
"""

import csv
import datetime
import os
import shutil
import sys
import time
from common_code.cal_parser_template import Calibration


class FLCDRACalibration(Calibration):
    """Calibration class for FLCDRA instruments.

    Attributes:
        dark (int): counts
        scale (float):

    """

    def __init__(self):
        """Initializes the FLCDRACalibration Class."""

        super(FLCDRACalibration, self).__init__('FLCDRA')
        self.dark = 0
        self.scale = 0.0

    def read_cal(self, filename):
        """Reads cal file and scrapes it for calibration values.

        Arguments:
            filename (str) -- path to the calibration file.
        """

        with open(filename, 'r', encoding='windows-1252') as fh:
            for line in fh:
                parts = line.split()
                if not len(parts):  # skip blank lines
                    continue
                if 'ECO' == parts[0]:
                    self.serial = parts[-1]
                elif 'Created' == parts[0]:
                    self.date = datetime.datetime.strptime(
                        parts[-1], '%m/%d/%Y')
                deconstruct = parts[0].split('=')
                if deconstruct[0] == 'CDOM':
                    self.dark = int(parts[-1])
                    self.scale = float(parts[1])
                    self.coefficients['CC_dark_counts_cdom'] = self.dark
                    self.coefficients['CC_scale_factor_cdom'] = self.scale
            fh.close()


def main():
    for path, _, files in os.walk('FLCDRA/manufacturer'):
        for file in files:
            # Skip hidden files
            if file[0] == '.':
                continue
            cal = FLCDRACalibration()
            cal.read_cal(os.path.join(path, file))
            cal.write_cal_info()
            cal.move_to_archive(cal.type, file)


if __name__ == '__main__':
    start_time = time.time()
    main()
    print('FLCDRA: %s seconds' % (time.time() - start_time))
