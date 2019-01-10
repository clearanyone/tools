#!/usr/bin/python
# -*- coding: UTF-8 -*-

import glob,os,sys,re,time
import commands
import requests
import prometheus_client
from prometheus_client import Gauge,start_http_server


def get_status():
   apps = glob.glob(r'/data/program/*/*.war')
  
   status_list = []

   for war in apps:
       os.chdir(os.path.dirname(war))

       appname = os.path.dirname(war)
       appname = appname.replace('/data/program/','')
       app_building_mark = '/tmp/' + appname + '_building'

       appport = commands.getoutput("head start |grep -oP '(?<=server.port=)\S+' |head -n 1 ")

       p = re.compile(r'^\d{4}$')
       m = p.match(appport)
 
       if m is not None:
          url = 'http://127.0.0.1:' + appport + '/inner/health'
          oldurl = 'http://127.0.0.1:' + appport + '/health' 
      
       if os.path.isfile(app_building_mark):
          url = 'http://172.16.1.88:9090'
        
       try:
          r = requests.get(url,timeout=10)
    
          if r.status_code == 404:
             r = requests.get(oldurl,timeout=10)   
            
          if r.status_code == 200:      
             status_list.append({os.path.basename(war)[:-4]:1 })
          else:
             status_list.append({os.path.basename(war)[:-4]:0 })
       except (requests.ConnectionError, requests.exceptions.ReadTimeout, requests.exceptions.ConnectionError, requests.exceptions.RequestException,requests.exceptions.HTTPError ):
          pass
          

   return status_list


if __name__ == "__main__":
    g = Gauge('app_health_check','Description of gauge',['app_name'])
    start_http_server(9901)
    while True:
       for key in get_status():
          for k,v in key.iteritems():
             k = re.sub(r'-','_',k)
             g.labels(app_name=k).set(v)
       time.sleep(180)

    

