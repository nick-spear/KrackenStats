import subprocess
import socket
import sys
import datetime
import json
import psycopg2
import time
import censor
from threading import Thread
from _thread import start_new_thread

HOST, PORT = '10.0.3.54', 6011

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
print('Socked created successfully')
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
sock.bind((HOST, PORT))
print('Socket bound successfully')
sock.listen(10)
print('Socket now listening')
print('Loading censor list')
censor_list = censor.load_censor_list("censor_list.txt")
def rCall(argString):
     print('Now updating')
     try:
          conn = psycopg2.connect (
            dbname='imt-admin',
            user='imt-admin',
            host='10.0.3.7',
            password='1q2w3e4r'
           )
          print('You are connected to "imt-admin" for updating!')
          command = 'Rscript'
          pathToScript = '/home/imt-admin/Kracken/KrackenStats.R'
          cmd = [command, pathToScript, argString]
          rOut = subprocess.check_output(cmd, universal_newlines=True)
          output = json.loads(str(rOut))
          seen_common_output = output['seen_common']
          wild_common_output = output['wild_common']
          fastest_output = output['fastest']
          sql = 'INSERT INTO seen_count VALUES(%s,%s)'
          cur = conn.cursor()
          for items in seen_common_output:
               pw = items.get('plaintext')
               seen_count = items.get('seen_count')
               cur.execute(sql, (pw, seen_count))
          sql = 'UPDATE rank_in_wild SET plaintext = %s WHERE rank = %s'
          cur = conn.cursor()
          for items in wild_common_output:
               pw = items.get('plaintext')
               rank = items.get('rank_wild')
               cur.execute(sql, (pw, rank))
          sql = 'INSERT INTO fastest_crack_time VALUES(%s,%s)'
          cur = conn.cursor()
          for items in fastest_output:
               pw = items.get('plaintext')
               crack_time = items.get('cpu_brute_time')
               cur.execute(sql, (pw, crack_time))
          conn.commit()
          print('Update complete.')
     except psycopg2.DatabaseError as e:
          if conn:
                  conn.rollback()
          print("Error: %s" % e)
     finally:
          if conn:
                  conn.close()
          print('Now waiting 5 minutes for next function')
          time.sleep(300)

def client(connection):
  inVal = connection.recv(1024)
  print(inVal)
  val_list = inVal.split(" ")
  if val_list[0] == "getuserstats":
    db_conn = psycopg2.connect(
         dbname='imt-admin',
         user='imt-admin',
         host='10.0.3.7',
         password='1q2w3e4r'
   )
    print("You are connected to 'imt-admin'!")
    cur = db_conn.cursor()
    sql = 'SELECT * FROM rank_in_wild;'
    cur.execute(sql)
    res_list = cur.fetchall()
    ret_list = []
    for i in range(len(res_list)):
        c = censor.censor(res_list[i][0], censor_list, mark_censored=True)
        ret_list.append([c, res_list[i][1]])
    connection.sendall(str(ret_list).encode('utf-8'))
    connection.close()
  except psycopg2.DatabaseError as e:
    if db_conn:
        db_conn.rollback()
    print("Error: %s" % e)
  finally:
    if db_conn:
         db_conn.close()
   print("Get user stats")
  else:
    print("else")
  try:
#  print(datetime.datetime.now().strftime('%H:%M:%S') + ' : Received \'' + outVal + '\' from R script. Sending to client...')
#  connection.sendall(outVal.encode('utf-8'))
#  print(datetime.datetime.now().strftime('%H:%M:%S') + ' : Response sent to client')
#  connection.close()

def top10():
     while True:
          connection, address = sock.accept()
          print(datetime.datetime.now().strftime('%H:%M:%S') + ' : Connected with ' + address[0] + ':' + str(address[1]))
          start_new_thread(client, (connection,))

def update_db():
     while True:
          rCall('gettop 10'.encode())

t1 = Thread(target = top10)
t2 = Thread(target = update_db)

t1.start()
t2.start()
print("2 new threads started")
