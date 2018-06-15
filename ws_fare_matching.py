from multiprocessing import Process
import multiprocessing
import time
import os
import sys
from datetime import datetime, date
import pymysql
from multiprocessing import Pool
from contextlib import closing
import itertools



hostname = 'rassure-cx-dev.ctepqvlta15m.ap-southeast-2.rds.amazonaws.com'
username = 'jaydenw'
password = 'Wps12300'
database = 'zz_jw'
myConnection = pymysql.connect(host=hostname, user=username, passwd=password, db=database)


def mysql(stmt):
    curs = myConnection.cursor()
    curs.execute(stmt)
    result = curs.fetchall()
    curs.close()
    return result[0][0]

def FileWrite(msg):
    FileLog = open(Recordfile, 'a')
    print(msg)
    FileLog.write(msg)
    FileLog.write('\n')
    FileLog.close()

def fbr(inp):
    cpu, num = inp
    curs = myConnection.cursor()
    stmt = 'call rax.ws_fare_matching_fbr(%d,%d)' % (cpu, num)
    curs.execute(stmt)
    curs.close()


def fbrs(inp):
    cpu, num = inp
    curs = myConnection.cursor()
    stmt = 'call rax.ws_fare_matching_fbrs(%d,%d)' % (cpu, num)
    curs.execute(stmt)
    curs.close()


def ocda(inp):
    cpu, num = inp
    curs = myConnection.cursor()
    stmt = 'call rax.ws_fare_matching_ocda(%d,%d)' % (cpu, num)
    curs.execute(stmt)
    curs.close()


def dcda(inp):
    cpu, num = inp
    curs = myConnection.cursor()
    stmt = 'call rax.ws_fare_matching_dcda(%d,%d)' % (cpu, num)
    curs.execute(stmt)
    curs.close()


def twocda(inp):
    cpu, num = inp
    curs = myConnection.cursor()
    stmt = 'call rax.ws_fare_matching_2cda(%d,%d)' % (cpu, num)
    curs.execute(stmt)
    curs.close()


def spec(inp):
    cpu, num = inp
    curs = myConnection.cursor()
    stmt = 'call rax.ws_fare_matching_spec(%d,%d)' % (cpu, num)
    curs.execute(stmt)
    curs.close()

def fm_post_2(inp):
    cpu, num = inp
    curs = myConnection.cursor()
    stmt = 'call rax.ws_fm_post2_r12r2(%d,%d)' % (cpu, num)
    curs.execute(stmt)
    curs.close()

if __name__ == '__main__':
    multiprocessing.freeze_support()
    ProjectDir = 'C:\Temp\JaydenW\pythonlog'
    if not os.path.exists(ProjectDir):
        os.makedirs(ProjectDir)
    start = datetime.now().strftime("%Y%m%d_%H%M%S")
    Recordfile = ProjectDir + '\Processing'+start+'.log'
    if os.path.exists(Recordfile):
        os.remove(Recordfile)
    start = datetime.now()
    msg = 'Start Time %s ' % start
    FileWrite(msg)
    worker = []
    base = 3
    cpu = base
    input = list(i for i in range(base))
    processor = len(input) * [cpu]
    arg = list(zip(processor, input))
    if not os.path.exists(ProjectDir):
        os.makedirs(ProjectDir)
    numworker = base

    # curs = myConnection.cursor()
    # stmt = 'call rax.create_tables; '
    # curs.execute(stmt)
    # curs.close()
    #
    curs = myConnection.cursor()
    stmt = 'truncate zz_ws.temp_tbl_fc_fare_map_fbr '
    curs.execute(stmt)
    curs.close()

    # curs = myConnection.cursor()
    # stmt = 'truncate zz_ws.temp_tbl_fc_fare_map_fbrs '
    # curs.execute(stmt)
    # curs.close()
    #
    # curs = myConnection.cursor()
    # stmt = 'truncate zz_ws.temp_tbl_fc_fare_map_ocda  '
    # curs.execute(stmt)
    # curs.close()
    #
    # curs = myConnection.cursor()
    # stmt = 'truncate zz_ws.temp_tbl_fc_fare_map_dcda '
    # curs.execute(stmt)
    # curs.close()
    #
    # curs = myConnection.cursor()
    # stmt = 'truncate zz_ws.temp_tbl_fc_fare_map_2cda '
    # curs.execute(stmt)
    # curs.close()
    #
    # curs = myConnection.cursor()
    # stmt = 'truncate zz_ws.temp_tbl_fc_fare_map_spec'
    # curs.execute(stmt)
    # curs.close()

    ## pre_matching
    #
    # msg = 'Processing pre_ws_fm_pre_cmz matching...'
    # FileWrite(msg)
    # start = datetime.now()
    # curs = myConnection.cursor()
    # stmt = "call rax.ws_fm_pre_cmz(1, 1,'WS','201805')"
    # curs.execute(stmt)
    # curs.close()
    # end = datetime.now()
    # msg = "Pre_fare_static matching cost %s seconds" % (end - start).total_seconds()
    # FileWrite(msg)
    #
    #
    # msg = 'Processing pre_fare_static matching...'
    # FileWrite(msg)
    # start = datetime.now()
    # curs = myConnection.cursor()
    # stmt = "call rax.ws_fm_pre_static(1, 1,'WS','201805')"
    # curs.execute(stmt)
    # curs.close()
    # end = datetime.now()
    # msg = "Pre_fare_static matching cost %s seconds" % (end - start).total_seconds()
    # FileWrite(msg)
    # msg = 'Processing pre_fare_dynn matching...'
    # FileWrite(msg)
    # start = datetime.now()
    # curs = myConnection.cursor()
    # stmt = "call rax.ws_fm_pre_dynm(1, 1, 'WS','201805')"
    # curs.execute(stmt)
    # curs.close()
    # end = datetime.now()
    # msg = "Pre_fare_dynm matching cost %s seconds" % (end - start).total_seconds()
    # FileWrite(msg)

    # Fare matching
    # pro_item = ['fbr', 'fbrs', 'spec', 'ocda', 'dcda', 'twocda']
    pro_item = ['fbr']
    #
    for i in range(len(pro_item)):
        msg = 'processing %s' % pro_item[i]
        FileWrite(msg)
        start = datetime.now()
        msg = 'Start Time %s '%start
        FileWrite(msg)
        with closing(Pool(processes=numworker)) as eventing:
            eventing = Pool(processes=numworker)
        p = eventing.map(eval(pro_item[i]), arg)
        eventing.close()
        eventing.join()
        end = datetime.now()

        msg = 'End Time %s ' % end
        FileWrite(msg)
        msg = '{0} processing takes {1} seconds with {2} processors'.format(pro_item[i], (end - start).total_seconds(), base)
        FileWrite(msg)

    myConnection = pymysql.connect(host=hostname, user=username, passwd=password, db=database)
    stmt = 'select count(*) from zz_ws.temp_tbl_fc_fare_map_fbr'
    number = mysql(stmt)
    msg = 'fbr generates {0} records'.format(number)
    FileWrite(msg)
    stmt = 'select count(*) from zz_ws.temp_tbl_fc_fare_map_fbrs'
    number = mysql(stmt)
    msg = 'fbrs generates {0} records'.format(number)
    FileWrite(msg)
    stmt = 'select count(*) from zz_ws.temp_tbl_fc_fare_map_spec'
    number = mysql(stmt)
    msg = 'spec generates {0} records'.format(number)
    FileWrite(msg)
    stmt = 'select count(*) from zz_ws.temp_tbl_fc_fare_map_ocda'
    number = mysql(stmt)
    msg = 'ocda generates {0} records'.format(number)
    FileWrite(msg)
    stmt = 'select count(*) from zz_ws.temp_tbl_fc_fare_map_dcda'
    number = mysql(stmt)
    msg = 'dcda generates {0} records'.format(number)
    FileWrite(msg)
    stmt = 'select count(*) from zz_ws.temp_tbl_fc_fare_map_2cda'
    number = mysql(stmt)
    msg = '2cda generates {0} records'.format(number)
    FileWrite(msg)


    msg = "post_matching post_1"
    FileWrite(msg)
    start = datetime.now()
    msg = "Start Time %s"%start
    FileWrite(msg)
    curs = myConnection.cursor()
    stmt = 'call rax.ws_fm_post1_chk'
    curs.execute(stmt)
    curs.close()
    end = datetime.now()
    msg = "Post_1 cost %s seconds "%(end-start).total_seconds()
    FileWrite(msg)

    stmt = 'select count(*) from zz_ws.temp_tbl_fc_fare_matching'
    number = mysql(stmt)
    msg = '{0} records for post_matching'.format(number)
    FileWrite(msg)

    msg = "processing Post_2"
    FileWrite(msg)
    start = datetime.now()
    msg = "Start Time %s"%start
    FileWrite(msg)
    with closing(Pool(processes=numworker)) as eventing:
        eventing = Pool(processes=numworker)
    p = eventing.map(fm_post_2, arg)
    eventing.close()
    eventing.join()
    end = datetime.now()
    msg = 'End Time %s ' % end
    FileWrite(msg)
    msg = 'fm_post_2 processing takes {0} seconds with {1} processors'.format((end - start).total_seconds(), base)
    FileWrite(msg)

    msg = "processing post_matching post_3"
    FileWrite(msg)
    start = datetime.now()
    msg = "Start Time %s"%start
    FileWrite(msg)
    curs = myConnection.cursor()
    # stmt = "call rax.ws_fm_post3_dump2audit(1, 1, '2018-05-01', '2018-5-31','201805')"
    stmt = "call rax.ws_fm_post3_dump2audit_pu_io('201805')"
    curs.execute(stmt)
    curs.close()
    end = datetime.now()
    msg = "End Time %s"%end
    FileWrite(msg)
    msg = "Post_3 cost %s seconds "%(end-start).total_seconds()
    FileWrite(msg)
