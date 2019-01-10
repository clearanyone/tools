#!/usr/bin/env python
import re,os
import json
import commands

r = r"[s|v]d[a-z]$"
rstr = re.compile(r)

appname_list = []
appname_dict = {}

for root,dirs,files in os.walk('/data/program'):
     for name in files:
         if(name.endswith(".war")):
            if ( name != "derby.war" ): 
                 appname_list.append({"{#APPNAME}":name[:-4] })

appname_dict["data"] = appname_list
print json.dumps(appname_dict)
