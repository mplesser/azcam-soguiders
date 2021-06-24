@echo off

ipython.exe --profile azcamconsole --TerminalInteractiveShell.term_title_format=azcamconsole -i -m azcam.console -- -config azcam_soguiders.console_soguiders
