# azcamconsole config file for soguiders


import datetime
import os
import sys
import threading

from azcam_ds9.ds9display import Ds9Display

import azcam.shortcuts
from azcam.console import azcam
from azcam.genpars import GenPars

# ****************************************************************
# files and folders
# ****************************************************************
azcam.db.systemname = "soguiders"
azcam.db.systemfolder = os.path.dirname(__file__)
azcam.db.datafolder = azcam.db.systemfolder
azcam.db.parfile = os.path.join(azcam.db.datafolder, f"parameters_{azcam.db.systemname}.ini")

# ****************************************************************
# start logging
# ****************************************************************
tt = datetime.datetime.strftime(datetime.datetime.now(), "%d%b%y_%H%M%S")
azcam.db.logger.logfile = os.path.join(azcam.db.datafolder, "logs", f"console_{tt}.log")
azcam.db.logger.start_logging()
azcam.log(f"Configuring console for {azcam.db.systemname}")

# ****************************************************************
# display
# ****************************************************************
display = Ds9Display()
dthread = threading.Thread(target=display.initialize, args=[])
dthread.start()  # thread just for speed

# ****************************************************************
# try to connect to azcamserver
# ****************************************************************
connected = azcam.api.serverconn.connect(port=2412)
if connected:
    azcam.log("Connected to azcamserver")
else:
    azcam.log("Not connected to azcamserver")

# ****************************************************************
# read par file
# ****************************************************************
genpars = GenPars()
pardict = genpars.parfile_read(azcam.db.parfile)["azcamconsole"]
azcam.utils.update_pars(0, pardict)
wd = genpars.get_par(pardict, "wd", "default")
azcam.utils.curdir(wd)

# ****************************************************************
# finish
# ****************************************************************
azcam.log("Configuration complete")
