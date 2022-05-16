#!/usr/bin/env python
'''
Common code shared between the different parsers in this file. Includes a Calibration object that
defines some default fields and functions. Also includes a function to parse through a csv that shows
the link between serial numbers and UIDs.
'''
import csv
import datetime
import os
import pandas as pd
import sqlite3
import sys
import time

class Calibration(object):
    def __init__(self):
        self.asset_tracking_number = None
        self.serial = None
        self.date = None
        self.coefficients = {}
        self.type = None

    def write_cal_info(self):
        if not self.assetID_lookup():
            return
        complete_path = os.path.join(os.path.realpath('../..'), 'calibration', self.type)
        file_name = self.asset_tracking_number + '__' + self.date
        with open(os.path.join(complete_path, '%s.csv' % file_name), 'w') as info:
            writer = csv.writer(info)
            writer.writerow(['serial','name', 'value', 'notes'])
            for each in sorted(self.coefficients.items()):
                row = [self.serial] + list(each)
                row.append('')
                writer.writerow(row)

    def move_to_archive(self, inst_type, file):
        archive_file = self.asset_tracking_number + '__' + self.date + '.marks'
        os.rename(os.path.join(os.getcwd(), inst_type, 'manufacturer', file), \
                    os.path.join(os.getcwd(), inst_type, 'manufacturer_ARCHIVE', archive_file))
    
    def assetID_lookup(self):
        rca_sensorMap = pd.read_csv('RCA_sensorMap.csv')
        dictKeys = set(rca_sensorMap['instrumentType']) 
        sensorDict = {}
        for item in dictKeys:
            sensorDict[item] = {}
        for index, row in rca_sensorMap.iterrows():
            sensorDict[row['instrumentType']][row['assetID']] = row['mfgSN']
        for key, value in sensorDict[self.type].items():
            if self.serial in value:
                self.asset_tracking_number = key
                return True

