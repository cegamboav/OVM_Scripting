#!/usr/bin/python

from com.oracle.ovm.mgr.api import *
from com.oracle.ovm.mgr.api.event import *
from com.oracle.ovm.mgr.api.virtual import *
from com.oracle.ovm.mgr.api.physical import *
from com.oracle.ovm.mgr.api.physical.network import *
from com.oracle.ovm.mgr.api.physical.storage import *

om=OvmClient.getOvmManager()
vms=om.getObjects(VirtualMachine)
print('List VMs:')
for vm in vms:
	print(str(vm.getUuidForHypervisor()) + " - " + str(vm))
print ("please provide this output to the SR")
