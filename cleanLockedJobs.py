#!/usr/bin/python

from com.oracle.ovm.mgr.api import *
from com.oracle.ovm.mgr.api.event import *
from com.oracle.ovm.mgr.api.virtual import *
from com.oracle.ovm.mgr.api.physical import *
from com.oracle.ovm.mgr.api.physical.network import *
from com.oracle.ovm.mgr.api.physical.storage import *

om = OvmClient.getOvmManager()
foundry = om.getFoundryContext()
servers = foundry.getServers()
ss=om.getObjects(Server)
for s in ss:
	lockingJob = s.getLockingJob()
	if lockingJob != None:
		print "Found Locking Job, attempting to abort the job"
		j=om.createJob("Abort Lock")
		j.begin()
		lockingJob.abort()
		j.commit()
printf("Done. Thanks")
