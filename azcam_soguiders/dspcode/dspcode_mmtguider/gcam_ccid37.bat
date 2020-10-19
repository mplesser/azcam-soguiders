rem Create .s file for Magellan timing board

set ROOT=c:\AzCam\MotorolaDSPTools\CLAS563\BIN\

%ROOT%asm56300 -b -a -o NOPP -o NODXL -lgcam_ccid37.ls -DSYS 4 gcam_ccid37.asm

rem %ROOT%dsplnk -bgcam_ccid37.cld -v gcam_ccid37.cln

rem del gcam_ccid37.cln
rem del gcam_ccid37.lod

%ROOT%cldlod gcam_ccid37.cld > gcam_ccid37.lod

%ROOT%srec -s -r -w -a3 -t3 gcam_ccid37.cld

del gcam_ccid37.cld

rem copy gcam_ccid37.s ..\gcam_ccid37.s

pause




