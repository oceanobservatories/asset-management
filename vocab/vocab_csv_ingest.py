import requests
import csv
import argparse
import json
import os

PORT = '12586'
URL = 'http://localhost'
SERVICE = 'vocab'
ADDRESS = "{}:{}/{}".format(URL, PORT, SERVICE)
REFDES = 'Reference_Designator'
INST = 'Instrument'
L1 = 'TOC_L1'
L2 = 'TOC_L2'
L3 = 'TOC_L3'
MANUFR = 'Manufacturer'
MODEL = 'Model'
MIN_DEPTH = 'Min Depth'
MAX_DEPTH = 'Max Depth'
TBD = 'TBD'

CLASS = '.VocabRecord'

parser = argparse.ArgumentParser(description='Read vocab csv, post to web service for ingesting.')
parser.add_argument('filename', metavar='csv_file', type=file, help='filename and path of the vocab file to ingest.')
parser.add_argument('-b', '--batch', action='store_true', help='collect all the vocab records into one http request')
args = parser.parse_args()

#Reference_Designator,Instrument,TOC_L1,TOC_L2,TOC_L3
vocabreader = csv.DictReader(args.filename)

vocablist = []
lineCount = 0
for row in vocabreader:
  lineCount += 1
  if row[MIN_DEPTH] == TBD:
    row[MIN_DEPTH] = ''
  if row[MAX_DEPTH] == TBD:
    row[MAX_DEPTH] = ''
  if row[REFDES] != '':
    vocab = {'refdes': row[REFDES], 'instrument': row[INST], 'tocL1': row[L1], 'tocL2': row[L2], 'tocL3': row[L3], 'manufacturer' : row[MANUFR], 'model' : row[MODEL], 'mindepth' : row[MIN_DEPTH], 'maxdepth' : row[MAX_DEPTH], '@class': CLASS}
    if not args.batch:
      r = requests.post(ADDRESS, json=vocab)
      print 'Line {} processed - status = {}'.format(lineCount, r.text)
    else:
      vocablist.append(vocab)
  else:
    print 'Reference Designator must not be empty on line {}'.format(lineCount)

if args.batch:
  br = requests.put(ADDRESS, json=vocablist)
  print br.text

