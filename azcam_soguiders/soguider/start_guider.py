# Starts guider.tcl

import os
import subprocess

ScopeName = "notel"
GuiderName = "itlguider"
ScopeHost = "localhost"
ScopePort = 5750
AzCamHost = "localhost"
AzCamPort = 2402

cmd = "wish guider.tcl %s %s %s %s %s %s" % (
    ScopeName,
    GuiderName,
    ScopeHost,
    ScopePort,
    AzCamHost,
    AzCamPort,
)

if os.name == "posix":
    os.system(cmd)
else:
    subprocess.Popen(cmd, cwd=".")
