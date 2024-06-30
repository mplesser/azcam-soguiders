"""
Python process start file
"""

import subprocess

OPTIONS = "-system bigguider"
CMD = f"ipython --profile azcamserver -i -m azcam_soguiders.server -- {OPTIONS}"

p = subprocess.Popen(
    CMD,
    creationflags=subprocess.CREATE_NEW_CONSOLE,
)
