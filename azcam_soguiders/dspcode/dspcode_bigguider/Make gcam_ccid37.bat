rem Create .s file for Magellan timing board

set CCD=gcam_ccid37

set ROOT=\azcam\MotorolaDSPTools\CLAS563\BIN\

%ROOT%asm56300 -b -a -o NOPP -o NODXL -l%CCD%.ls -DSYS 4 %CCD%.asm

rem %ROOT%dsplnk -b%CCD%.cld -v %CCD%.cln

rem del %CCD%.cln
rem del %CCD%.lod

%ROOT%cldlod %CCD%.cld > %CCD%.lod

%ROOT%srec -s -r -w -a3 -t3 %CCD%.cld

del %CCD%.cld

rem pause


