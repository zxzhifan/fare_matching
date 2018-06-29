from multiprocessing import Process
import multiprocessing
import time
import os
import sys
import datetime
import pymysql
from multiprocessing import Pool
from contextlib import closing

hostname = 'rassure-cx-dev.ctepqvlta15m.ap-southeast-2.rds.amazonaws.com'
username = 'raxuser'
password = 'dbSure2016'
database = 'zz_cx_law'
myConnection = pymysql.connect(host=hostname, user=username, passwd=password, db=database)

base = 1


def fm_job(sp, cpu,num):
    curs = myConnection.cursor()
    stmt = 'call zz_cx_law.fm_post(1, %d)' % (num)
    curs.execute(stmt)
    curs.close()


if __name__ == '__main__':
    multiprocessing.freeze_support()
    worker = []
    numworker = base
    start = time.time()
    with closing(Pool(processes=numworker)) as eventing:
        eventing = Pool(processes=numworker)

    p = eventing.map_async(fm_job, (i for i in range(base)))
    eventing.close()
    eventing.join()
    print("The number of CPU is:" + str(multiprocessing.cpu_count()))
    end = time.time()

    print('spec processes take %s seconds' % (end - start), base)
