# script to start azcamserver using IPython

import os

import system_config as config

# virtual enviroment
if config.use_venv:
    ipython = f"call {config.venv_script} && ipython"
else:
    ipython = "ipython"

# set profile and window title
profile = config.server_profile
profiledir = f"{config.datafolder_root}/azcam/profiles/{profile}"

if config.servermode == "interactive":
    interactive = "-i"
elif config.servermode == "prompt":
    ans = input("Enter i for interactive mode: ")
    if ans == "i":
        interactive = "-i"
    else:
        interactive = ""
elif config.servermode == "server":
    interactive = ""
else:
    interactive = ""
xmode = f"InteractiveShell.xmode={config.xmode}"
cl = f'{ipython} --profile {profile} --profile-dir={profiledir} --{xmode} --TerminalInteractiveShell.term_title_format={profile} {interactive} -c "{config.server_cmd}"'

os.system(cl)
