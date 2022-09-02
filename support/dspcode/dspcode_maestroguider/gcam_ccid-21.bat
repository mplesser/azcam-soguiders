rem Create .s file for Magellan timing board

set ROOT=c:\azcam\MotorolaDSPTools\CLAS563\BIN\

%ROOT%asm56300 -b -a -o NOPP -o NODXL -lgcam_ccid-21.ls -DSYS 4 gcam_ccid-21.asm

rem %ROOT%dsplnk -bgcam_ccid-21.cld -v gcam_ccid-21.cln

rem del gcam_ccid-21.cln
rem del gcam_ccid-21.lod

%ROOT%cldlod gcam_ccid-21.cld > gcam_ccid-21.lod

%ROOT%srec -s -r -w -a3 -t3 gcam_ccid-21.cld

del gcam_ccid-21.cld

rem copy gcam_ccid-21.s .\gcam_ccid-21.s

rem pause


