# azcamserver configuration parameters

use_venv = 1
venv_script = "c:/venvs/azcam/Scripts/activate.bat"

server_profile = "AzCamServer"
console_profile = "AzCamConsole"
server_cmd = "import azcamserver_soguiders; from cli_servercommands import *"
console_cmd = "import azcamconsole_soguiders; from cli_consolecommands import *"

azcamlogfolder = "c:/azcam/systems/soguiders/azcam/logs/azcamlog"
commonfolder = "c:/azcam/systems/common"
datafolder_root = "c:/azcam/systems/soguiders/soguider"
systemname = "bokcassguider"  # name or menu
location = "itl MM"  # site or menu

verbosity = 3
logcommands = 1
xmode = "Minimal"  # Minimal, Context, Verbose
test_mode = 0
readparfile = 0
servermode = "interactive"  # prompt, interactive, server
start_azcamtool = 0
start_webapp = 0
