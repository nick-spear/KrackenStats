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

def db_to_list(key, db_conn):
  cur = db_conn.cursor()
  sql = ''.join(["SELECT * FROM ", key])
  cur.execute(sql)
  results_list = cur.fetchall()
  censored_results =  censor.censor_list(results_list, censor_list, mark_censored=True)
  data = []
  for result in censored_results:
    data.append({"plaintext": result[0], key: result[1]})
  return data

def client(connection):
  inVal = connection.recv(1024)
  print(inVal)
  val_list = inVal.split(" ")
  if val_list[0] == "gettop":
    try:
      db_conn = psycopg2.connect(
         dbname='imt-admin',
         user='imt-admin',
         host='10.0.3.7',
         password='1q2w3e4r'
     )
      # get top 10 rank wild
      print("You are connected to 'imt-admin'!")
      rank_list = db_to_list("rank_in_wild", db_conn)
      # get top fastest
      fastest_list = db_to_list("fastest_crack_time", db_conn)
      # get top seen
      seen_list = db_to_list("seen_count", db_conn)
      # construct JSON and send
      all_dict = {"wild_common": rank_list, "fastest": fastest_list, "seen_common": seen_list}
      json_data = json.dump(all_dict)
      connection.sendall(str(json_data).encode('utf-8'))
      connection.close()
    except psycopg2.DatabaseError as e:
      if db_conn:
          db_conn.rollback()
      print("Error: %s" % e)
    finally:
      if db_conn:
           db_conn.close()
  elif val_list[0] == "getuserstats":
    command = 'Rscript'
    pathToScript = '/home/imt-admin/Kracken/KrackenStats.R'
    cmd = [command, pathToScript, argString]
    rOut = subprocess.check_output(cmd, universal_newlines=True)
    connection.sendall(rOut.encode('utf-8'))
    connection.close()
  else:
    connection.sendall(json.dump({"error": "bad request", "error_token": val_list[0]}))


def listen():
     while True:
          connection, address = sock.accept()
          print(datetime.datetime.now().strftime('%H:%M:%S') + ' : Connected with ' + address[0] + ':' + str(address[1]))
          start_new_thread(client, (connection,))

def update_db():
     while True:
          rCall('gettop 10'.encode())

t1 = Thread(target = listen)
t2 = Thread(target = update_db)

t1.start()
t2.start()
