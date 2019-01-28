#!/usr/bin/env python3
"""
PARADA Calibration Parser
Create the necessary CI calibration ingest information from a PARADA
calibration file.
"""

__author__ = "Daniel Tran"
__version__ = "0.1.0"
__license__ = "MIT"

import csv
import datetime
import os
import shutil
import sys
import time
from common_code.cal_parser_template import Calibration


class PARADACalibration(Calibration):
    """Calibration class for PARADA instruments.

    Attributes:
        dark (int): counts used in CDOM calculations.
        scale (float): scale factor used in CDOM calculations.

    """

    def __init__(self):
        """Initializes the PARADACalibration Class."""

        super(PARADACalibration, self).__init__('PARADA')
        self.dark = 0
        self.scale = 0.0

    def read_cal(self, filename):
        """Reads cal file and scrapes it for calibration values.

        Arguments:
            filename (str) -- path to the calibration file.

        """

        with open(filename) as fh:
            for line in fh:
                parts = line.split()
                if not len(parts):  # skip blank lines
                    continue
                if 'ECO' == parts[0]:
                    self.serial = parts[-1].split('-')[-1]
                elif 'Created' == parts[0]:
                    self.date = datetime.datetime.strptime(
                        parts[-1].split(':')[-1], '%m/%d/%y')
                deconstruct = parts[0].split('=')
                coefficient_name = deconstruct[0].lower()
                if coefficient_name == 'im':
                    self.coefficients['CC_Im'] = parts[-1]
                elif coefficient_name == 'a1':
                    self.coefficients['CC_a1'] = parts[-1]
                elif coefficient_name == 'a0':
                    self.coefficients['CC_a0'] = parts[-1]
        fh.close()


def main():
    """Main entry point of the script."""

    for path, _, files in os.walk('PARADA/manufacturer'):
        for file in files:
            # Skip hidden files
            if file[0] == '.':
                continue
            cal = PARADACalibration()
            cal.read_cal(os.path.join(path, file))
            cal.write_cal_info(os.path.join(path, file))


if __name__ == '__main__':
    start_time = time.time()
    main()
    print('PARADA: %s seconds' % (time.time() - start_time))
