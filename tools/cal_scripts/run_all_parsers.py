#!/usr/bin/env python
import os, glob, subprocess
import time

base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))

def main():
    for parser in glob.glob('*_cal_parser.py'):
        print(parser)
        command = ['python2.7', parser]
        p = subprocess.Popen(command)

if __name__ == '__main__':
    start_time = time.time()
    main()
    print("--- %s seconds ---" % (time.time() - start_time))
