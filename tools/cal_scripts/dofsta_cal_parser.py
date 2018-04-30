#!/usr/bin/env python

# DOFSTA calibration parser
#
# Create the necessary CI calibration ingest information from a DOFSTA calibration file

import csv
import datetime
import os
import sys
import time
from common_code.cal_parser_template import Calibration, get_uid_serial_mapping

class SBE43Calibration(Calibration):
    def __init__(self):
        super(SBE43Calibration, self).__init__()
        self.type = 'DOFSTA'
        self.coefficient_name_map = {
            'E': 'CC_residual_temperature_correction_factor_e',
            'C': 'CC_residual_temperature_correction_factor_c',
            'VOFFSET': 'CC_voltage_offset',  # note that this was previously called CC_frequency_offset
            'SOC': 'CC_oxygen_signal_slope',
            'A': 'CC_residual_temperature_correction_factor_a',
            'B': 'CC_residual_temperature_correction_factor_b',
        }

    def read_cal(self, filename):
        with open(filename) as fh:
            for line in fh:
                parts = line.split('=')

                if len(parts) != 2:
                    continue  # skip anything that is not key value paired

                key = parts[0]
                value = parts[1].strip()

                if key == 'INSTRUMENT_TYPE' and value != 'SBE43':
                    print 'Error - unexpected type calibration file (%s != SBE43)' % value
                    sys.exit(1)

                if self.coefficient_name_map.has_key(key):
                    name = self.coefficient_name_map.get(key)
                    self.coefficients[name] = value
                    if name == 'CC_voltage_offset':
                        self.coefficients['CC_frequency_offset'] = value

                if key == "OCALDATE":
                    cal_date = value
                    cal_date = datetime.datetime.strptime(cal_date, "%d-%b-%y").strftime("%Y%m%d")
                    self.date = cal_date

                if key == "SERIALNO":
                    self.serial = "43-" + str(value)

def main():
    # Starts in the directory with
    # Get corresponding mapping between serial number and uid
    lookup = get_uid_serial_mapping('DOFSTA/dofsta_lookup.csv')
    #Begin writing files
    for path, directories, files in os.walk('DOFSTA/manufacturer'):
        for file in files:
            cal = SBE43Calibration()
            cal.read_cal(os.path.join(path, file))
            cal.asset_tracking_number = lookup[cal.serial]
            cal.write_cal_info()


if __name__ == '__main__':
    start_time = time.time()
    main()
    print("DOFSTA: %s seconds" % (time.time() - start_time))
