rem Create .s file for Magellan timing board

set ROOT=c:\AzCam\MotorolaDSPTools\CLAS563\BIN\

%ROOT%asm56300 -b -a -o NOPP -o NODXL -lgcam_512ft.ls -DSYS 4 gcam_512ft.asm

rem %ROOT%dsplnk -bgcam_512ft.cld -v gcam_512ft.cln

rem del gcam_512ft.cln
rem del gcam_512ft.lod

%ROOT%cldlod gcam_512ft.cld > gcam_512ft.lod

%ROOT%srec -s -r -w -a3 -t3 gcam_512ft.cld

del gcam_512ft.cld

rem copy gcam_512ft.s ..\gcam_512ft.s



