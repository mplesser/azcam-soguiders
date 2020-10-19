# azcam server app for ITL detchar systems

import os
import sys
import importlib
import datetime
import subprocess

from azcam.server import azcam
from azcam.genpars import GenPars
import azcam.shortcuts
from azcam.displays.ds9display import Ds9Display
from azcam.telescopes.telescope import Telescope
from azcam.cmdserver import CommandServer
import azcam.monitorinterface

azcam.log("Loading azcam-soguiders environment")

# ****************************************************************
# parse command line arguments
# ****************************************************************
try:
    i = sys.argv.index("-system")
    subsystem = sys.argv[i + 1]
except ValueError:
    subsystem = "menu"
    # subsystem = "soguiders"  # debug
try:
    i = sys.argv.index("-datafolder")
    azcam.db.datafolder = sys.argv[i + 1]
except ValueError:
    azcam.db.datafolder = None

# ****************************************************************
# optionally select system with menu
# ****************************************************************
menu_options = {
    "90primeguider": "90primeguider",
    "bigguider": "bigguider",
    "bokcassguider": "bokcassguider",
    "maestroguider": "maestroguider",
    "mmtguider": "mmtguider",
    "pepsiguider": "pepsiguider",
    "spolguider_bok": "spolguider_bok",
    "spolguider_big61": "spolguider_big61",
    "itlguider": "itlguider",
}
if subsystem == "menu":
    subsystem = azcam.utils.show_menu(menu_options)

azcam.db.systemname = "soguiders"

# ****************************************************************
# define folders for system and optionally a project
# ****************************************************************
azcam.db.rootfolder = os.path.abspath(os.path.dirname(__file__))
azcam.db.rootfolder = os.path.normpath(azcam.db.rootfolder).replace("\\", "/")
azcam.db.systemfolder = os.path.dirname(__file__)
azcam.db.projectfolder = os.path.join(azcam.db.systemfolder, azcam.db.systemname)
azcam.db.datafolder = azcam.db.systemfolder
azcam.db.systemfolder = azcam.utils.fix_path(azcam.db.systemfolder)
azcam.db.projectfolder = azcam.utils.fix_path(azcam.db.projectfolder)
azcam.db.datafolder = azcam.utils.fix_path(azcam.db.datafolder)

# ****************************************************************
# enable logging
# ****************************************************************
tt = datetime.datetime.strftime(datetime.datetime.now(), "%d%b%y_%H%M%S")
azcam.db.logfile = os.path.join(azcam.db.datafolder, "logs", f"server_{tt}.log")
azcam.logging.start_logging(azcam.db.logfile, "123")
azcam.log(f"Configuring {azcam.db.systemname}")

# ****************************************************************
# define and start command server
# ****************************************************************
cmdserver = CommandServer()
cmdserver.port = 2402
azcam.log(f"Starting cmdserver - listening on port {cmdserver.port}")
# cmdserver.welcome_message = "Welcome - azcam-itl server"
cmdserver.start()

# ****************************************************************
# import specific system code
# ****************************************************************
importlib.import_module(f"azcam_soguiders.config_server_soguiders")

# ****************************************************************
# define display
# ****************************************************************
display = Ds9Display()

# ****************************************************************
# define telescope
# ****************************************************************
telescope = Telescope()
azcam.api.exposure.objects_init.remove("telescope")
azcam.api.exposure.objects_reset.remove("telescope")

# ****************************************************************
# read par file
# ****************************************************************
parfile = os.path.join(azcam.db.datafolder, f"parameters_soguiders.ini")
genpars = GenPars()
pardict = genpars.parfile_read(parfile)["azcamserver"]
azcam.utils.update_pars(0, pardict)
wd = genpars.get_par(pardict, "wd", "default")
azcam.utils.curdir(wd)

# ****************************************************************
# web server
# ****************************************************************
from azcam.webserver.web_server import WebServer

webserver = WebServer()

import azcam_webobs
import azcam_exptool
import azcam_status

webserver.start()

# ****************************************************************
# azcammonitor
# ****************************************************************
monitor = azcam.monitorinterface.MonitorInterface()
monitor.proc_path = "c:/azcam/azcam_soguiders/bin/restart_server.bat"
monitor.register()

# ****************************************************************
# guider.tcl GUI
# ****************************************************************
scope_names = {
    "90primeguider": "BOK",
    "bigguider": "BIG61",
    "bokcassguider": "BOK",
    "maestroguider": "MMT",
    "mmtguider": "MMT",
    "spolguider_bok": "BOK",
    "spolguider_big61": "BIG61",
    "itlguider": "NOTEL",
}
scope_hosts = {
    "90primeguider": "bokpc3",
    "bigguider": "bigguider",
    "bokcassguider": "bokpc3",
    "maestroguider": "mmt",
    "mmtguider": "mmt",
    "spolguider_bok": "bokpc3",
    "spolguider_big61": "bigguider",
    "itlguider": "NOTEL",
}
scope_ports = {
    "90primeguider": 5750,
    "bigguider": 5750,
    "bokcassguider": 5750,
    "maestroguider": 5750,
    "mmtguider": 5750,
    "spolguider_bok": 5750,
    "spolguider_big61": 5750,
    "itlguider": 0,
}
azcam_hosts = {
    "90primeguider": "localhost",
    "bigguider": "localhost",
    "bokcassguider": "localhost",
    "maestroguider": "localhost",
    "mmtguider": "localhost",
    "spolguider_bok": "localhost",
    "spolguider_big61": "localhost",
    "itlguider": "localhost",
}

scope_name = scope_names[subsystem]
guider_name = subsystem
scope_host = scope_hosts[subsystem]
scope_port = scope_ports[subsystem]
azcam_host = azcam_hosts[subsystem]
azcam_port = 2402

cmd = "wish guider.tcl %s %s %s %s %s %s" % (
    scope_name,
    guider_name,
    scope_host,
    scope_port,
    azcam_host,
    azcam_port,
)
azcam.log(f"Starting guider.tcl: {cmd}")
if os.name == "posix":
    os.system(cmd)
else:
    subprocess.Popen(cmd, cwd=".")

# ****************************************************************
# Debug code
# ****************************************************************
if 0:
    pass
