#!/usr/bin/env python

# NUTNR calibration parser
#
# Create the necessary CI calibration ingest information from an NUTNR calibration file

import csv
import datetime
import json
import os
import shutil
import sys
import time
from common_code.cal_parser_template import Calibration


class NUTNRCalibration(Calibration):
    def __init__(self, lower=217, upper=240):
        self.cal_temp = None
        self.wavelengths = []
        self.eno3 = []
        self.eswa = []
        self.di = []
        self.lower_limit = lower
        self.upper_limit = upper
        self.asset_tracking_number = None
        self.date = None
        self.serial = None
        self.type = 'NUTNRA'
        self.coefficients = {'CC_lower_wavelength_limit_for_spectra_fit': self.lower_limit,
                             'CC_upper_wavelength_limit_for_spectra_fit': self.upper_limit}

    def read_cal(self, filename):
        with open(filename) as fh:
            for line in fh:
                parts = line.split(',')

                if len(parts) < 2:
                    continue  # skip anything that is not key value paired
                record_type = parts[0]

                if record_type == 'H':
                    key_value = parts[1].split()
                    if len(key_value) == 2:
                        name, value = key_value
                        if name == 'T_CAL' or (name == 'T_CAL_SWA' and 'CC_cal_temp' not in self.coefficients):
                            self.cal_temp = float(value)
                            self.coefficients['CC_cal_temp'] = self.cal_temp
                    elif 'creation' in key_value:
                        cal_date = key_value[-2]
                        cal_date = datetime.datetime.strptime(
                            cal_date, '%d-%b-%Y').strftime('%Y%m%d')
                        if self.date is not None:
                            if self.date < cal_date:
                                self.date = cal_date
                        else:
                            self.date = cal_date
                    elif 'SUNA' in key_value:
                        self.serial = str(key_value[1]).lstrip('0')

                elif record_type == 'E':
                    _, wavelength, eno3, eswa, _, di = parts
                    self.wavelengths.append(float(wavelength))
                    self.eno3.append(float(eno3))
                    self.eswa.append(float(eswa))
                    self.di.append(float(di))
                    self.coefficients['CC_wl'] = json.dumps(self.wavelengths)
                    self.coefficients['CC_eno3'] = json.dumps(self.eno3)
                    self.coefficients['CC_eswa'] = json.dumps(self.eswa)
                    self.coefficients['CC_di'] = json.dumps(self.di)


def main():
    for path, directories, files in os.walk('NUTNRA/manufacturer'):
        for file in files:
            # Skip hidden files
            if file[0] == '.':
                continue
            cal = NUTNRCalibration()
            #if not file.startswith('SNA'):
            #    continue
            cal.read_cal(os.path.join(path, file))
            cal.write_cal_info()
            cal.move_to_archive(cal.type, file)


if __name__ == '__main__':
    start_time = time.time()
    main()
    print('NUTNR: %s seconds' % (time.time() - start_time))
