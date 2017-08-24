import subprocess
import socket
import sys
import datetime
import json
import psycopg2
import time
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

def rCall(argString):
     print('Now updating')
     print(argString)
     print('You are connected to "imt-admin" for updating!')
     command = 'Rscript'
     pathToScript = '/home/imt-admin/Kracken/KrackenStats.R'
     cmd = [command, pathToScript, argString]
     rOut = subprocess.check_output(cmd, universal_newlines=True)
     print("Printing out stuff.")
     print(rOut)
     print('Update complete, now waiting 5 minutes...')
     time.sleep(300)

def client(connection):
  inVal = connection.recv(1024)
  print(inVal)
#  print(datetime.datetime.now().strftime('%H:%M:%S') + ' : Received \'' + inVal + '\' from client. Executing R script...')
#  outVal = rCall(inVal)
#  values = json.loads(outVal)
  try:
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
    connection.sendall(str(cur.fetchall()).encode('utf-8'))
    connection.close()
  except psycopg2.DatabaseError as e:
    if db_conn:
        db_conn.rollback()
    print("Error: %s" % e)
  finally:
    if db_conn:
         db_conn.close()
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
