rem Create .s file for Magellan timing board

set ROOT=c:\AzCam\MotorolaDSPTools\CLAS563\BIN\

%ROOT%asm56300 -b -a -o NOPP -o NODXL -lgcam_ccd57.ls -DSYS 4 gcam_ccd57.asm

rem %ROOT%dsplnk -bgcam_ccd57.cld -v gcam_ccd57.cln

rem del gcam_ccd57.cln
rem del gcam_ccd57.lod

%ROOT%cldlod gcam_ccd57.cld > gcam_ccd57.lod

%ROOT%srec -s -r -w -a3 -t3 gcam_ccd57.cld

del gcam_ccd57.cld

rem copy gcam_ccd57.s ..\gcam_ccd57.s
