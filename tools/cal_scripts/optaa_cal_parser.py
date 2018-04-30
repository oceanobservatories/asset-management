#!/usr/bin/env python

# OPTAA calibration parser
#
# Create the necessary CI calibration ingest information from an OPTAA calibration file

import csv
import datetime
import os
import json
import sys
import string
import time
from common_code.cal_parser_template import Calibration, get_uid_serial_mapping

class OPTAACalibration(Calibration):
    def __init__(self, serial):
        self.asset_tracking_number = None
        self.cwlngth = []
        self.awlngth = []
        self.tcal = None
        self.tbins = None
        self.ccwo = []
        self.acwo = []
        self.tcarray = []
        self.taarray = []
        self.nbins = None  # number of temperature bins
        self.serial = serial
        self.date = None
        self.coefficients = {'CC_taarray' : 'SheetRef:CC_taarray',
                            'CC_tcarray' : 'SheetRef:CC_tcarray'}
        self.type = 'OPTAA'

    def read_cal(self, filename):
        with open(filename) as fh:
            for line in fh:
                parts = line.split(';')
                if len(parts) != 2:
                    parts = line.split()
                    if parts[0] == '"tcal:':
                        self.tcal = parts[1]
                        self.coefficients['CC_tcal'] = self.tcal
                        cal_date = parts[-1:][0].strip(string.punctuation)
                        self.date = datetime.datetime.strptime(cal_date, "%m/%d/%y").strftime("%Y%m%d")
                    continue
                data, comment = parts

                if comment.startswith(' temperature bins'):
                    self.tbins = data.split()
                    self.tbins = [float(x) for x in self.tbins]
                    self.coefficients['CC_tbins'] = json.dumps(self.tbins)

                elif comment.startswith(' number of temperature bins'):
                    self.nbins = int(data)

                elif comment.startswith(' C and A offset'):
                    if self.nbins is None:
                        print 'Error - failed to read number of temperature bins'
                        sys.exit(1)
                    parts = data.split()
                    self.cwlngth.append(float(parts[0][1:]))
                    self.awlngth.append(float(parts[1][1:]))
                    self.ccwo.append(float(parts[3]))
                    self.acwo.append(float(parts[4]))
                    tcrow = [float(x) for x in parts[5:self.nbins+5]]
                    tarow = [float(x) for x in parts[self.nbins+5:2*self.nbins+5]]
                    self.tcarray.append(tcrow)
                    self.taarray.append(tarow)
                    self.coefficients['CC_cwlngth'] = json.dumps(self.cwlngth)
                    self.coefficients['CC_awlngth'] = json.dumps(self.awlngth)
                    self.coefficients['CC_ccwo'] = json.dumps(self.ccwo)
                    self.coefficients['CC_acwo'] = json.dumps(self.acwo)

    def write_cal_info(self):
        inst_type = None
        if self.asset_tracking_number.find('58332') != -1:
            inst_type = 'OPTAAD'
        elif self.asset_tracking_number.find('69943') != -1:
            inst_type = 'OPTAAC'
        complete_path = os.path.join(self.type, 'cal_sheets', inst_type)
        file_name = self.asset_tracking_number + '__' + self.date
        with open(os.path.join(complete_path, '%s.csv' % file_name), 'w') as info:
            writer = csv.writer(info)
            writer.writerow(['serial','name', 'value', 'notes'])
            for each in sorted(self.coefficients.items()):
                writer.writerow([self.serial] + list(each))

        def write_array(filename, cal_array):
            with open(filename, 'w') as out:
                array_writer = csv.writer(out)
                array_writer.writerows(cal_array)

        write_array(os.path.join(complete_path, '%s__CC_tcarray.ext' % file_name), self.tcarray)
        write_array(os.path.join(complete_path, '%s__CC_taarray.ext' % file_name), self.taarray)

def main():
    lookup = get_uid_serial_mapping('OPTAA/optaa_lookup.csv')
    for path, directories, files in os.walk('OPTAA/manufacturer'):
        for file in files:
            sheet_name = os.path.basename(file).partition('.')[0].upper()
            sheet_name = sheet_name[:3] + '-' + sheet_name[3:]
            cal = OPTAACalibration(sheet_name)
            cal.read_cal(os.path.join(path, file))
            cal.asset_tracking_number = lookup[cal.serial]
            cal.write_cal_info()

if __name__ == '__main__':
    start_time = time.time()
    main()
    print("OPTAA: %s seconds" % (time.time() - start_time))
