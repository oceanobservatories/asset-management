#!/usr/bin/env python3

"""
DOFSTA Calibration Parser
Create the necessary CI calibration ingest information from a DOFSTA
calibration file, preferably an XMLCON file.
"""

import csv
import datetime
import os
import sys
import time
import xml.etree.ElementTree as et
from common_code.cal_parser_template import Calibration


class SBE43Calibration(Calibration):
    """Calibration class for DOFSTA instruments.

    Attributes:
        coefficient_name_map (dict of str:str):

    """

    def __init__(self):
        """Initializes the SBE43Calibration Class."""

        super(SBE43Calibration, self).__init__('DOFSTA')
        self.coefficient_name_map = {
            'E': 'CC_residual_temperature_correction_factor_e',
            'C': 'CC_residual_temperature_correction_factor_c',
            'VOFFSET': 'CC_voltage_offset',
            # note that this was previously called CC_frequency_offset
            'OFFSET': 'CC_voltage_offset',
            'SOC': 'CC_oxygen_signal_slope',
            'A': 'CC_residual_temperature_correction_factor_a',
            'B': 'CC_residual_temperature_correction_factor_b',
        }

    def _read_xml(self, filename):
        """Reads xmlcon file and scrapes it for calibration values.

        Arguments:
            filename (str) -- path to the calibration file.
        """

        if not filename.endswith('.xmlcon'):
            return False

        with open(filename) as fh:
            tree = et.parse(filename)
            for child in tree.iter():
                key = child.tag.upper()
                if key == '':
                    continue
                if child.tag == 'SerialNumber' and child.text is not None and\
                   self.serial is None:
                    self.serial = '43-' + child.text
                if child.tag == 'CalibrationDate' and child.text is not None\
                   and self.date is None:
                    self.date = datetime.datetime.strptime(
                        child.text, '%d-%b-%y')
                name = self.coefficient_name_map.get(key)
                if name is None:
                    continue
                self.coefficients[name] = child.text
                if name == 'CC_voltage_offset':
                    self.coefficients['CC_frequency_offset'] = child.text
        fh.close()
        return True

    def read_cal(self, filename):
        """Reads cal file and scrapes it for calibration values.

        Arguments:
            filename (str) -- path to the calibration file.
        """

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

                if key == 'INSTRUMENT_TYPE' and value != 'SBE43':
                    print(
                        'Error - unexpected type calibration file ({0} != SBE43)'.format(value))
                    sys.exit(1)

                if key in self.coefficient_name_map:
                    name = self.coefficient_name_map.get(key)
                    self.coefficients[name] = value
                    if name == 'CC_voltage_offset':
                        self.coefficients['CC_frequency_offset'] = value

                if key == 'OCALDATE':
                    self.date = datetime.datetime.strptime(
                        value, '%d-%b-%y')

                if key == 'SERIALNO':
                    self.serial = "43-" + str(value)


def main():
    for path, _, files in os.walk('DOFSTA/manufacturer'):
        for file in files:
            # Skip hidden files
            if file[0] == '.':
                continue
            cal = SBE43Calibration()
            cal.read_cal(os.path.join(path, file))
            cal.write_cal_info()
            cal.move_to_archive(cal.type, file)


if __name__ == '__main__':
    start_time = time.time()
    main()
    print('DOFSTA: %s seconds' % (time.time() - start_time))
