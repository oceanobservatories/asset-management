#!/usr/bin/env python3
"""
SPKIRA Calibration Parser
Create the necessary CI calibration ingest information from a SPKIRA
calibration file.
"""

__author__ = "Daniel Tran"
__version__ = "0.1.0"
__license__ = "MIT"

import csv
import datetime
import dateutil
import json
import os
import shutil
import sys
import time
from dateutil.parser import parse
from common_code.cal_parser_template import Calibration


class SPKIRCalibration(Calibration):
    """Calibration class for DOFSTA instruments.

    Attributes:
        immersion_factor (list):
        offset (list):
        scale (list):

    """

    def __init__(self):
        """Initializes the SPKIRCalibration Class."""

        super(SPKIRCalibration, self).__init__('SPKIRA')
        self.immersion_factor = []
        self.offset = []
        self.scale = []

    def read_cal(self, filename):
        """Reads cal file and scrapes it for calibration values.

        Arguments:
            filename (str) -- path to the calibration file.
        """

        with open(filename) as fh:
            read_record = False  # indicates next line desired record
            for line in fh:
                parts = line.split()
                if 'OCR-507' in line:
                    self.serial = str(parts[-2]).lstrip('0')
                elif not len(parts):  # skip blank lines
                    continue
                elif '#' == parts[0]:
                    try:
                        parse(parts[1])
                    except ValueError:
                        continue
                    self.date = dateutil.parser.parse(parts[1])

                elif parts[0] == 'ED':
                    read_record = True
                    continue
                elif read_record:
                    if len(parts) == 3:  # only parse if we have all the data
                        offset, scale, factor = parts
                        self.offset.append(float(offset))
                        self.scale.append(float(scale))
                        self.immersion_factor.append(float(factor))
                        self.coefficients['CC_offset'] = json.dumps(
                            self.offset)
                        self.coefficients['CC_scale'] = json.dumps(self.scale)
                        self.coefficients['CC_immersion_factor'] = self.immersion_factor
                        read_record = False
            fh.close()


def main():
    """ Main entry point of the app """

    for path, _, files in os.walk('SPKIRA/manufacturer'):
        for file in files:
            # Skip hidden files
            if file[0] == '.':
                continue
            cal = SPKIRCalibration()
            cal.read_cal(os.path.join(path, file))
            cal.write_cal_info(os.path.join(path, file))


if __name__ == '__main__':
    start_time = time.time()
    main()
    print('SPKIR: %s seconds' % (time.time() - start_time))
