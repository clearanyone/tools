#!/usr/bin/python
# -*- coding: UTF-8 -*-

import sys,os
import commands
import requests
import json
import re

def app_discovery():
    '''用于发现应用名'''

    r = r"[s|v]d[a-z]$"
    rstr = re.compile(r)

    appname_list = []
    appname_dict = {}

    for root, dirs, files in os.walk('/data/program'):
        for name in files:
            if (name.endswith(".war")):
                if (name != "derby.war"):
                    appname_list.append({"{#APPNAME}": name[:-4]})

    appname_dict["data"] = appname_list

    print json.dumps(appname_dict)
    
 
def app_health_check():
    '''健康检查'''
 
    app=sys.argv[1]
    app_building_mark = '/tmp/' + sys.argv[1] + '_building'
    app_path='/data/program'
    appdir=os.path.join(app_path,app)


    if os.path.isfile(app_building_mark):
        print "1"
    else:
        if os.path.isdir(appdir):
            os.chdir(appdir)

            appport = commands.getoutput("head start |grep -oP '(?<=server.port=)\S+' |head -n 1 ")

            p = re.compile(r'^\d{4}$')
            m = p.match(appport)

            if m is not None:
                #print('Match found: ', m.group())

                url1 = 'http://127.0.0.1:'
                url2 = '/health'
                url3 = '/inner/health'
                url = url1 + appport + url2
                url_new = url1 + appport +url3
           
                try: 
                    r = requests.get(url,timeout=10)
                    if r.status_code == 404:
                       r = requests.get(url_new,timeout=10)           
                    rjson = r.json()
                except (requests.ConnectionError, requests.exceptions.ReadTimeout):
                    print "健康检查失败,应用可能已停止服务" 
                    sys.exit(0)           


                try:
                    if rjson[u'status'][u'code'] ==  "UP":
                        print "1"
                    elif rjson[u'status'][u'code'] ==  "DOWN":
                        re_vender = re.compile(r'error":\s*?"([^"]*?)"')
                        print re_vender.findall(r.text) 
                except (KeyError, TypeError):
                    if rjson[u'status'] ==  "UP":
                        print "1"
                    elif rjson[u'status'] ==  "DOWN":
                        print "没错误信息返回"
                        re_vender = re.compile(r'error":\s*?"([^"]*?)"')
                

if __name__ == '__main__':
    if len(sys.argv) == 2:
        if sys.argv[1] == "appname":
            app_discovery()
        else:
            app_health_check()

