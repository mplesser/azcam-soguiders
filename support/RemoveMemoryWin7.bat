rem Remove memory for image buffer

ECHO OFF

ECHO.
SET/P MB=Enter number of megabytes to use for ImageBuffer: 

bcdedit/set removememory %MB%

ECHO.
ECHO You must reboot before the ImageBuffer is used!
ECHO. 

PAUSE
