# azcam server app for ITL detchar systems

import os
import subprocess
import sys

import azcam
import azcam.server
import azcam.shortcuts
from azcam.tools.cmdserver import CommandServer
from azcam.tools.instrument import Instrument
from azcam_ds9.ds9display import Ds9Display
from azcam_mag.controller_mag import ControllerMag
from azcam_mag.exposure_mag import ExposureMag
from azcam_mag.tempcon_mag import TempConMag
from azcam_mag.udpinterface import UDPinterface

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
try:
    i = sys.argv.index("-broadcast")
    BROADCAST = 1
except ValueError:
    BROADCAST = 0

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
azcam.db.servermode = subsystem

# ****************************************************************
# define folders for system and optionally a project
# ****************************************************************
azcam.db.rootfolder = os.path.abspath(os.path.dirname(__file__))
azcam.db.rootfolder = os.path.normpath(azcam.db.rootfolder).replace("\\", "/")
azcam.db.systemfolder = os.path.dirname(__file__)
azcam.db.systemfolder = azcam.utils.fix_path(azcam.db.systemfolder)
azcam.db.datafolder = os.path.join("/data", azcam.db.systemname)
azcam.db.datafolder = azcam.utils.fix_path(azcam.db.datafolder)

# ****************************************************************
# enable logging
# ****************************************************************
logfile = os.path.join(azcam.db.datafolder, "logs", "server.log")
azcam.db.logger.start_logging(logfile=logfile)
azcam.log(f"Configuring {azcam.db.systemname}")

# ****************************************************************
# broadcast:
# ****************************************************************
guider_address = "bigag"
guider_port = 2425
if BROADCAST:
    udpobj = UDPinterface()
    reply = udpobj.get_ids()
    if reply == []:
        azcam.log("No systems responded to broadcast")
        guider_address = "guider2"
        guider_port = 2405
    for system in reply:
        tokens = system[0].split(" ")
        azcam.log(f"Found {tokens[2]} at ({tokens[4]}:{int(tokens[3])})")
        guider_address = tokens[4]
        guider_port = int(tokens[3])
        # reply = udpobj.GetIP('guider_z1')
        break  # for now, use first response

azcam.log("Using guide camera:", guider_address, guider_port)


# ****************************************************************
# controller
# ****************************************************************
controller = ControllerMag()
controller.camserver.set_server(guider_address, guider_port)
controller.timing_file = os.path.join(azcam.db.datafolder, "dspcode", "dspcode", "gcam_ccd57.s")

# ****************************************************************
# instrument
# ****************************************************************
instrument = Instrument()

# ****************************************************************
# temperature controller
# ****************************************************************
tempcon = TempConMag()

# ****************************************************************
# exposure
# ****************************************************************
exposure = ExposureMag()
# filetype = "FITS"
filetype = "BIN"
exposure.filetype = exposure.filetypes[filetype]
exposure.image.filetype = exposure.filetypes[filetype]
exposure.display_image = 0
exposure.root = "image"
exposure.folder = os.path.join(azcam.db.datafolder, "soguider")
# exposure.image.filename = os.path.join(azcam.db.datafolder, "soguider", "image.bin")
exposure.test_image = 0
exposure.display_image = 0
exposure.image.make_lockfile = 1

# ****************************************************************
# detector
# ****************************************************************
from azcam_soguiders.detectors import detector_ccd57

exposure.set_detpars(detector_ccd57)

# ****************************************************************
# define display
# ****************************************************************
display = Ds9Display()

# ****************************************************************
# read par file
# ****************************************************************
parfile = os.path.join(azcam.db.datafolder, f"parameters_soguiders.ini")
azcam.db.tools["parameters"].read_parfile(parfile)
azcam.db.tools["parameters"].update_pars(0, "azcamserver")

# ****************************************************************
# define and start command server
# ****************************************************************
cmdserver = CommandServer()
cmdserver.port = 2402
azcam.log(f"Starting cmdserver - listening on port {cmdserver.port}")
# cmdserver.welcome_message = "Welcome - azcam-itl server"
cmdserver.start()

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

if 1:
    azcam.log(f"Starting guider.tcl: {cmd}")
    if os.name == "posix":
        os.system(cmd)
    else:
        subprocess.Popen(cmd, cwd=os.path.join(azcam.db.datafolder, "soguider"))

# ****************************************************************
# finish
# ****************************************************************
azcam.log("Configuration complete")
