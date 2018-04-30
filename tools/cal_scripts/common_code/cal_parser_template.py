#!/usr/bin/env python
'''
Common code shared between the different parsers in this file. Includes a Calibration object that
defines some default fields and functions. Also includes a function to parse through a csv that shows
the link between serial numbers and UIDs.
'''
import csv
import datetime
import os
import sys
import time

class Calibration(object):
    def __init__(self):
        self.asset_tracking_number = None
        self.serial = None
        self.date = None
        self.coefficients = {}
        self.type = None

    def write_cal_info(self, directory = 'cal_sheets'):
        file_name = self.asset_tracking_number + '__' + self.date
        with open(os.path.join(self.type, directory, '%s.csv' % file_name), 'w') as info:
            writer = csv.writer(info)
            writer.writerow(['serial','name', 'value', 'notes'])
            for each in sorted(self.coefficients.items()):
                writer.writerow([self.serial] + list(each))

def get_uid_serial_mapping(csv_name):
    lookup = {}
    with open(csv_name, 'rb') as csvfile:
        reader = csv.DictReader(csvfile, delimiter=",")
        for row in reader:
            lookup[row['serial']] = row['uid']
    return lookup
