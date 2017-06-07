#!/usr/bin/python
## ============================================================================
## Name        : con.py
## Author      : david.cerdas
## Version     : 0.1
## Copyright   : GPLv2
## Description : To Verify the connection from OVS Server to its OVM Manager, 
##               and viceversa.
## ============================================================================
 
# Imported modules
import os
import shlex
import subprocess
import sys
import getopt

# OVM type
def ovmTypeF():
    if os.path.isfile("/etc/ovs-release"):
        ovmType="ovs"
    elif os.path.isfile("/u01/app/oracle/ovm-manager-3/.config"):
        ovmType="ovmm"
    else:
        print ('This is not an OVM Manager or OVS Server')
        # add function of error
    return ovmType
# ovmType=ovmTypeF()
# print ('Finallyyyy %s' %ovmType )
    

# To Verify the Manager UID from OVS DB
def verifyManagerUID():
    if ovmType == "ovs":
        cmd='ovs-agent-db read_item server manager_uuid'
        proc = subprocess.Popen(shlex.split(cmd), stderr=subprocess.PIPE, stdout=subprocess.PIPE)
        ManagerUID = proc.stdout.read()
    elif ovmType == "ovmm":
        fileConfig = open("/u01/app/oracle/ovm-manager-3/.config", "r")
        for line in fileConfig: 
            if 'UUID' in line:
                x = line
                break
        ManagerUID = x[5:]
        fileConfig.close()
    else:
        print ('UID of the Manager was not identified')
        # add function of error
    return ManagerUID
#ManagerUID=verifyManagerUID()
#print ('Manager UID %s' %ManagerUID )


def conOvs(ovsServer):
    if ovmType == "ovs":
        ping="ping %s " %(i)
        os.system(cmd)
   # nc -v </dev/null <OVM Manager IP or name> 7002
   # ovs-agent-rpc -s https://oracle:<password>@localhost:8899/ echo "'Right password'"
    # ovs-agent-rpc -s https://oracle:password@localhost:8899/ echo "'Right password'"
    # 
def conOvm(ovmManager,password):
    logFile = open("/tmp/conTest.txt", 'w')
    # Ping test
    ping="ping -c3 %s " %(ovmManager)
    logFile.write("------PING TES------------\n")
    proc = subprocess.Popen(shlex.split(ping), stderr=subprocess.PIPE, stdout=subprocess.PIPE)
    text = proc.communicate()[0].decode('utf-8')
    for line in text.splitlines():
        logFile.write(line)
        logFile.write('\n') 
	logFile.close()
   # MTU Discovery
#   tracePath="tracepath -n %s" %(ovmManager)
#   logFile.write("MTU Discovery---\n")
#   logFile.write(os.system(tracePath)+"\n")
#   # Testing OVM Manager port
#   managerPort="nc -v </dev/null %s 7002" %(ovmManager)
#   logFile.write("OVM Manager port---\n")
#   logFile.write(os.system(managerPort)+"\n")
#   logFile.close()

ovmType=ovmTypeF()
# Main Menu
def mainMenu():
	myopts, args = getopt.getopt(sys.argv[1:],"m:o:u:c")
	
	###############################
	# o == OVM Manager IP
	# a == argument passed to the o
	###############################
	for o, a in myopts:
		if o == '-m':
			print ('option -m selected')
			ovmManager=a
			print ovmManager
		if o == '-o':
			print ('option -o selected')
			ovsServer=a
			print ovsServer
		if o == '-u':
			print ('option -u selected')
			print ('Manager UUID: %s' % verifyManagerUID() )
		if o == '-c':
			print ('option -c selected')		    
			if ovmType == "ovs":
				password=a
				conOvm(ovmManager,password)
			if ovmType == "omm":
				conOvs(ovsServer,password)        
#		else:
#			assert False, "unhandled option"
mainMenu()
