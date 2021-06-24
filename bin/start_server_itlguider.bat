@echo off

ipython.exe --profile azcamserver --TerminalInteractiveShell.term_title_format=azcamserver -i -m azcam.server -- -config azcam_soguiders.server_soguiders  -system itlguider -broadcast
