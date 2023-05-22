# azcamconsole config file for soguiders


import os
import threading

import azcam
import azcam_console.shortcuts
from azcam_console.tools.ds9display import Ds9Display


# ****************************************************************
# files and folders
# ****************************************************************
azcam.db.systemname = "soguiders"
azcam.db.systemfolder = os.path.dirname(__file__)
azcam.db.datafolder = azcam.db.systemfolder
parfile = os.path.join(azcam.db.datafolder, f"parameters_console_{azcam.db.systemname}.ini")

# ****************************************************************
# start logging
# ****************************************************************
logfile = os.path.join(azcam.db.datafolder, "logs", "console.log")
azcam.db.logger.start_logging(logfile=logfile)
azcam.log(f"Configuring console for {azcam.db.systemname}")

# ****************************************************************
# display
# ****************************************************************
display = Ds9Display()
dthread = threading.Thread(target=display.initialize, args=[])
dthread.start()  # thread just for speed

# ****************************************************************
# console tools
# ****************************************************************
from azcam_console.tools import create_console_tools
create_console_tools()

# ****************************************************************
# try to connect to azcamserver
# ****************************************************************
server = azcam.db.tools.["server"]
connected = server.connect(port=2412)
if connected:
    azcam.log("Connected to azcamserver")
else:
    azcam.log("Not connected to azcamserver")

# ****************************************************************
# read par file
# ****************************************************************
azcam.db.parameters.read_parfile(parfile)
azcam.db.parameters.update_pars(0, "azcamconsole")

# ****************************************************************
# finish
# ****************************************************************
azcam.log("Configuration complete")
