#!/usr/bin/env python
import os
import glob
import subprocess
import time

all_p = []


def main():
    for parser in glob.glob('*_cal_parser.py'):
        command = ['python3', parser]
        p = subprocess.Popen(command)
        all_p.append(p)


if __name__ == '__main__':
    start_time = time.time()
    main()
    print('--- %s seconds ---' % (time.time() - start_time))
    for p in all_p:
        p.kill()
