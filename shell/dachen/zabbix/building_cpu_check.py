#!/usr/bin/python
# -*- coding: UTF-8 -*-

import sys,os
import commands
import fnmatch

buildingstat = "0"

for root, dirnames, filenames in os.walk('/tmp'):
   for filename  in fnmatch.filter(filenames, '*_building'):
        #print(os.path.join(root, filename))
        buildingstat = "1" 

if sys.argv[1] == "cpu_usr" :
    if buildingstat == "0" :
        print commands.getoutput("mpstat -P ALL | awk 'NR==4 {print $4}' ")
elif sys.argv[1] == "cpu_iowait" :
    if buildingstat == "0" :
        print commands.getoutput("mpstat -P ALL | awk 'NR==4 {print $7}' ")		
else:
    print ""
