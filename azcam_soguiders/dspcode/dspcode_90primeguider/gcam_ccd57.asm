;*****************************************************************************
;   GCAM.ASM -- DSP-BASED CCD CONTROLLER PROGRAM
;
;   This version slightly modified by Michael Lesser from
;   original code by Greg Burley for operation of the 
;   ITL guider.
;
;   Last change 23Aug10 MPL for 90primeguider CCD57 new package

;*****************************************************************************
    PAGE    110,60,1,1
    TABS    4
;*****************************************************************************
;   SYS=    0=DEFAULT               1=GCAM              2=GCAM16
;           3=GCAM16 (w/FIBER)      4=GCAM16 CCD57      5=   
;*****************************************************************************
;   DEFINITIONS & POINTERS
;*****************************************************************************
START       EQU     $000100             ; program start location
SEQ         EQU     $000006             ; seq fragment length
DZ          EQU     $001000             ; DAC zero volt offset

WS          EQU     $073FE1             ; periph wait states
WS1         EQU     $073FE1             ; 1 PERIPH 1 SRAM 31 EPROM
WS3         EQU     $077FE1             ; 3 PERIPH 1 SRAM 31 EPROM
WS5         EQU     $07BFE1             ; 5 PERIPH 1 SRAM 31 EPROM

;*****************************************************************************
;   COMPILE-TIME OPTIONS
;*****************************************************************************
    IF (SYS==1)                         ; GCAM -- CCD47-20 14-BIT
VERSION         EQU     $1              ;
RDMODE          EQU     $0              ;
HOLD_P          EQU     $020A           ; P clock timing $20A=40us
HOLD_FT         EQU     $007C           ; FT clock timing $7C=10us xfer
HOLD_FL         EQU     $007C           ; FL clock timimg
HOLD_S          EQU     $0005           ; S clock timing
HOLD_RG         EQU     $0006           ; RG timing
HOLD_PL         EQU     $1F40           ; pre-line settling (1F40=100us)
HOLD_FF         EQU     $0020           ; FF clock timimg
HOLD_IPC        EQU     $0FA0           ; IPC clock timing ($FA0=50us)
HOLD_SIG        EQU     $000F           ; preamp settling time
HOLD_ADC        EQU     $000F           ; pre-sample settling
INIT_NROWS      EQU     $213            ; $213=(1030/2)+16
INIT_NCOLS      EQU     $238            ; $238=(1072/2)+32
INIT_NFT        EQU     $406            ; $406=1030
INIT_NFLUSH     EQU     $430            ; $430=1072
INIT_NCH        EQU     $1              ;
INIT_VBIN       EQU     $2              ;
INIT_HBIN       EQU     $2              ;
INIT_VSKIP      EQU     $0              ;
INIT_HSKIP      EQU     $0              ;
INIT_GAIN       EQU     $0              ; 0=LOW 1=HIGH
INIT_USEC       EQU     $C8             ;
INIT_OPCH       EQU     $1              ; 1=CH_A 2=CH_B
INIT_SCLKS      EQU     $1              ; 1=LEFT 2=RIGHT
INIT_LINK       EQU     $0              ; 0=wire 1=single_fiber
    ENDIF

    IF (SYS==2)                         ; GCAM16 -- CCD47-20 16-BIT
VERSION         EQU     $1              ;
RDMODE          EQU     $0              ;
HOLD_P          EQU     $020A           ; P clock timing $20A=40us
HOLD_FT         EQU     $007C           ; FT clock timing $7C=10us xfer
HOLD_FL         EQU     $007C           ; FL clock timimg
HOLD_S          EQU     $0005           ; S clock timing
HOLD_RG         EQU     $0006           ; RG timing
HOLD_PL         EQU     $1F40           ; pre-line settling (1F40=100us)
HOLD_FF         EQU     $0020           ; FF clock timimg
HOLD_IPC        EQU     $1F40           ; IPC clock timing ($1F40=100us)
HOLD_SIG        EQU     $000F           ; preamp settling time
HOLD_ADC        EQU     $000F           ; pre-sample settling
INIT_NROWS      EQU     $213            ; $213=(1030/2)+16
INIT_NCOLS      EQU     $238            ; $238=(1072/2)+32
INIT_NFT        EQU     $406            ; $406=1030
INIT_NFLUSH     EQU     $430            ; $430=1072
INIT_NCH        EQU     $1              ;
INIT_VBIN       EQU     $2              ;
INIT_HBIN       EQU     $2              ;
INIT_VSKIP      EQU     $0              ;
INIT_HSKIP      EQU     $0              ;
INIT_GAIN       EQU     $0              ; 0=LOW 1=HIGH
INIT_USEC       EQU     $C8             ;
INIT_OPCH       EQU     $1              ; 1=CH_A 2=CH_B
INIT_SCLKS      EQU     $1              ; 1=LEFT 2=RIGHT
INIT_PID        EQU     $0              ; FLAG $0=OFF $1=ON
INIT_LINK       EQU     $0              ; 0=wire 1=single_fiber
    ENDIF

    IF (SYS==3)                         ; GCAM16 w/FIBER  CCD47-20 16-BIT
VERSION         EQU     $1              ;
RDMODE          EQU     $0              ;
HOLD_P          EQU     $020A           ; P clock timing $20A=40us
HOLD_FT         EQU     $007C           ; FT clock timing $7C=10us xfer
HOLD_FL         EQU     $007C           ; FL clock timimg
HOLD_S          EQU     $0005           ; S clock timing
HOLD_RG         EQU     $0006           ; RG timing
HOLD_PL         EQU     $1F40           ; pre-line settling (1F40=100us)
HOLD_FF         EQU     $0020           ; FF clock timimg
HOLD_IPC        EQU     $1F40           ; IPC clock timing ($1F40=100us)
HOLD_SIG        EQU     $000F           ; preamp settling time
HOLD_ADC        EQU     $000F           ; pre-sample settling
INIT_NROWS      EQU     $213            ; $213=(1030/2)+16
INIT_NCOLS      EQU     $238            ; $238=(1072/2)+32
INIT_NFT        EQU     $406            ; $406=1030
INIT_NFLUSH     EQU     $430            ; $430=1072
INIT_NCH        EQU     $1              ;
INIT_VBIN       EQU     $2              ;
INIT_HBIN       EQU     $2              ;
INIT_VSKIP      EQU     $0              ;
INIT_HSKIP      EQU     $0              ;
INIT_GAIN       EQU     $0              ; 0=LOW 1=HIGH
INIT_USEC       EQU     $C8             ;
INIT_OPCH       EQU     $1              ; 1=CH_A 2=CH_B
INIT_SCLKS      EQU     $1              ; 1=LEFT 2=RIGHT
INIT_PID        EQU     $0              ; FLAG $0=OFF $1=ON
INIT_LINK       EQU     $1              ; 0=wire 1=single_fiber
    ENDIF

    IF (SYS==4)                         ; CCD57 -- 16-BIT
VERSION         EQU     $1              ;
RDMODE          EQU     $0              ;
HOLD_P          EQU     $020A           ; P clock timing $20A=40us
HOLD_FT         EQU     $007C           ; FT clock timing $7C=10us xfer
HOLD_FL         EQU     $007C           ; FL clock timimg
HOLD_S          EQU     $0005           ; S clock timing 5
HOLD_RG         EQU     $0006           ; RG timing  9 (was 6)
HOLD_PL         EQU     $1F40           ; pre-line settling (1F40=100us)
HOLD_FF         EQU     $0020           ; FF clock timimg
HOLD_IPC        EQU     $1F40           ; IPC clock timing ($1F40=100us)
HOLD_SIG        EQU     $000F           ; preamp settling time (was F)
HOLD_ADC        EQU     $000F           ; pre-sample settling
INIT_NROWS      EQU     $210            ; $210=528
INIT_NCOLS      EQU     $230            ; $230=536+24
INIT_NFT        EQU     $210            ; $210=528
INIT_NFLUSH     EQU     $230            ; $230=536+24
INIT_NCH        EQU     $1              ;
INIT_VBIN       EQU     $1              ;
INIT_HBIN       EQU     $1              ;
INIT_VSKIP      EQU     $0              ;
INIT_HSKIP      EQU     $0              ;
INIT_GAIN       EQU     $0              ; 0=LOW 1=HIGH  1 for 90primeguider
INIT_USEC       EQU     $C8             ; normally $C8
INIT_OPCH       EQU     $2              ; 1=CH_A 2=CH_B
INIT_SCLKS      EQU     $2              ; 1=LEFT 2=RIGHT
INIT_PID        EQU     $0              ; FLAG $0=OFF $1=ON
INIT_LINK       EQU     $0              ; 0=wire 1=single_fiber
    ENDIF

;*****************************************************************************
;   EXTERNAL PERIPHERAL DEFINITIONS (GUIDER CAMERA)
;*****************************************************************************
SEQREG      EQU     $FFFF80             ; external CCD clock register
ADC_A       EQU     $FFFF81             ; A/D converter #1
ADC_B       EQU     $FFFF82             ; A/D converter #2
TXREG       EQU     $FFFF85             ; Transmit Data Register
RXREG       EQU     $FFFF86             ; Receive Data register
SIG_AB      EQU     $FFFF88             ; bias voltages A+B
CLK_AB      EQU     $FFFF90             ; clock voltages A+B
TEC_REG     EQU     $FFFF8A             ; TEC register

;*****************************************************************************
;   INTERNAL PERIPHERAL DEFINITIONS (DSP563000)
;*****************************************************************************
IPRC        EQU     $FFFFFF             ; Interrupt priority register (core)
IPRP        EQU     $FFFFFE             ; Interrupt priority register (periph)
PCTL        EQU     $FFFFFD             ; PLL control register
BCR         EQU     $FFFFFB             ; Bus control register (wait states)
AAR0        EQU     $FFFFF9             ; Address attribute register 0
AAR1        EQU     $FFFFF8             ; Address attribute register 1
AAR2        EQU     $FFFFF7             ; Address attribute register 2
AAR3        EQU     $FFFFF6             ; Address attribute register 3
IDR         EQU     $FFFFF5             ; ID Register
PDRB        EQU     $FFFFC9             ; Port B (HOST) GPIO data
PRRB        EQU     $FFFFC8             ; Port B (HOST) GPIO direction
PCRB        EQU     $FFFFC4             ; Port B (HOST) control register
PCRC        EQU     $FFFFBF             ; Port C (ESSI_0) control register
PRRC        EQU     $FFFFBE             ; Port C (ESSI_0) direction
PDRC        EQU     $FFFFBD             ; Port C (ESSI_0) data
TXD         EQU     $FFFFBC             ; ESSI0 Transmit Data Register 0
RXD         EQU     $FFFFB8             ; ESSI0 Receive Data Register
SSISR       EQU     $FFFFB7             ; ESSI0 Status Register
CRB         EQU     $FFFFB6             ; ESSI0 Control Register B
CRA         EQU     $FFFFB5             ; ESSI0 Control Register A
PCRD        EQU     $FFFFAF             ; Port D (ESSI_1) control register
PRRD        EQU     $FFFFAE             ; Port D (ESSI_1) direction
PDRD        EQU     $FFFFAD             ; Port D (ESSI_1) data
PCRE        EQU     $FFFF9F             ; Port E (SCI) control register
PRRE        EQU     $FFFF9E             ; Port E (SCI) data direction
PDRE        EQU     $FFFF9D             ; Port E (SCI) data
TCSR0       EQU     $FFFF8F             ; TIMER0 Control/Status Register
TLR0        EQU     $FFFF8E             ; TIMER0 Load Reg
TCPR0       EQU     $FFFF8D             ; TIMER0 Compare Register
TCR0        EQU     $FFFF8C             ; TIMER0 Count Register
TCSR1       EQU     $FFFF8B             ; TIMER1 Control/Status Register
TLR1        EQU     $FFFF8A             ; TIMER1 Load Reg
TCPR1       EQU     $FFFF89             ; TIMER1 Compare Register
TCR1        EQU     $FFFF88             ; TIMER1 Count Register
TCSR2       EQU     $FFFF87             ; TIMER2 Control/Status Register
TLR2        EQU     $FFFF86             ; TIMER2 Load Reg
TCPR2       EQU     $FFFF85             ; TIMER2 Compare Register
TCR2        EQU     $FFFF84             ; TIMER2 Count Register
TPLR        EQU     $FFFF83             ; TIMER Prescaler Load Register
TPCR        EQU     $FFFF82             ; TIMER Prescalar Count Register
DSR0        EQU     $FFFFEF             ; DMA source address
DDR0        EQU     $FFFFEE             ; DMA dest address
DCO0        EQU     $FFFFED             ; DMA counter
DCR0        EQU     $FFFFEC             ; DMA control register

;*****************************************************************************
;   REGISTER DEFINITIONS (GUIDER CAMERA)
;*****************************************************************************
CMD         EQU     $000000             ; command word/flags from host
OPFLAGS     EQU     $000001             ; operational flags
NROWS       EQU     $000002             ; number of rows to read
NCOLS       EQU     $000003             ; number of columns to read
NFT         EQU     $000004             ; number of rows for frame transfer
NFLUSH      EQU     $000005             ; number of columns to flush
NCH         EQU     $000006             ; number of output channels (amps)
NPIX        EQU     $000007             ; (not used)
VBIN        EQU     $000008             ; vertical (parallel) binning
HBIN        EQU     $000009             ; horizontal (serial) binning
VSKIP       EQU     $00000A             ; V prescan or offset (rows)
HSKIP       EQU     $00000B             ; H prescan or offset (columns)
VSUB        EQU     $00000C             ; V subraster size
HSUB        EQU     $00000D             ; H subraster size
NEXP        EQU     $00000E             ; number of exposures (not used)
NSHUFFLE    EQU     $00000F             ; (not used)

EXP_TIME    EQU     $000010             ; CCD integration time(r)
TEMP        EQU     $000011             ; Temperature sensor reading(s)
GAIN        EQU     $000012             ; Sig_proc gain
USEC        EQU     $000013             ; Sig_proc sample time
OPCH        EQU     $000014             ; Output channel
HDIR        EQU     $000015             ; serial clock direction
LINK        EQU     $000016             ; 0=wire 1=single_fiber

SCLKS       EQU     $000030             ; serial clocks
SCLKS_FL    EQU     $000031             ; serial clocks flush
INT_X       EQU     $000032             ; reset and integrate clocks
NDMA        EQU     $000033             ; (not used)

VBIAS       EQU     $000018             ; bias voltages
VCLK        EQU     $000020             ; clock voltages
TEC         EQU     $00001A             ; TEC current
PIX         EQU     $000300             ; start address for data storage

;*****************************************************************************
;   SEQUENCE FRAGMENT STARTING ADDRESSES (& OTHER POINTERS)
;*****************************************************************************
MPP         EQU     $0040               ; MPP/hold state
IPCLKS      EQU     $0042               ; input clamp
TCLKS       EQU     $0044               ; Temperature monitor clocks
PCLKS_FT    EQU     $0048               ; parallel frame transfer
PCLKS_RD    EQU     $0050               ; parallel read-out transfer
PCLKS_FL    EQU     $0058               ; parallel flush transfer
INT_L       EQU     $0060               ; reset and first integration $0060
INT_H       EQU     $0068               ; second integration and A/D $0068
SCLKS_R     EQU     $0070               ; serial clocks shift right
SCLKS_FLR   EQU     $0080               ; serial clocks flush right
SCLKS_L     EQU     $0078               ; serial clocks shift left
SCLKS_FLL   EQU     $0088               ; serial clocks flush left
SCLKS_B     EQU     $0090               ; serial clocks both
SCLKS_FLB   EQU     $0098               ; serial clocks flush both
SCLKS_FF    EQU     $00A0               ; serial clocks fast flush

;*******************************************************************************
;   INITIALIZE X MEMORY AND DEFINE PERIPHERALS
;*******************************************************************************
            ORG     X:CMD               ; CCD control information
            DC      $0                  ; CMD/FLAGS
            DC      $0                  ; OPFLAGS
            DC      INIT_NROWS          ; NROWS
            DC      INIT_NCOLS          ; NCOLS
            DC      INIT_NFT            ; NFT
            DC      INIT_NFLUSH         ; NFLUSH
            DC      INIT_NCH            ; NCH
            DC      $1                  ; NPIX (not used)
            DC      INIT_VBIN           ; VBIN
            DC      INIT_HBIN           ; HBIN
            DC      INIT_VSKIP          ; VSKIP ($0)
            DC      INIT_HSKIP          ; HSKIP ($0)
            DC      $0                  ; VSUB
            DC      $0                  ; HSUB
            DC      $1                  ; NEXP (not used)
            DC      $0                  ; (not used)

            ORG     X:EXP_TIME
            DC      $3E8                ; EXP_TIME
            DC      $0                  ; TEMP
            DC      INIT_GAIN           ; GAIN
            DC      INIT_USEC           ; USEC SAMPLE TIME
            DC      INIT_OPCH           ; OUTPUT CHANNEL
            DC      INIT_SCLKS          ; HORIZ DIRECTION
            DC      INIT_LINK           ; SERIAL LINK

    IF (SYS==1)                         ; GCAM
            ORG     X:VBIAS
            DC      (DZ+0800)           ; OFFSET_R (5mV/DN)
            DC      (DZ+0800)           ; OFFSET_L
            DC      (DZ+0010)           ; TEC
            DC      (DZ-1200)           ; OG  voltage
            DC      (DZ+0100)           ; SPARE (10 mV/DN)
            DC      (DZ+0800)           ; RD
            DC      (DZ+2000)           ; OD_R
            DC      (DZ+2000)           ; OD_L

            ORG     X:VCLK
            DC      (DZ-0000)           ; IPC- [V0] voltage (5mV/DN)
            DC      (DZ+1000)           ; IPC+ [V1]
            DC      (DZ-1800)           ; RG-  [V2]
            DC      (DZ+0600)           ; RG+  [V3]
            DC      (DZ-1600)           ; S-   [V4]
            DC      (DZ+0400)           ; S+   [V5]
            DC      (DZ-1800)           ; DG-  [V6]
            DC      (DZ+0600)           ; DG+  [V7]
            DC      (DZ-1800)           ; TG-  [V8]
            DC      (DZ+0600)           ; TG+  [V9]
            DC      (DZ-1800)           ; P1-  [V10]
            DC      (DZ+0600)           ; P1+  [V11]
            DC      (DZ-1800)           ; P2-  [V12]
            DC      (DZ+0600)           ; P2+  [V13]
            DC      (DZ-1800)           ; P3-  [V14]
            DC      (DZ+0600)           ; P3+  [V15]
    ENDIF
 
    IF (SYS==2||SYS==3||SYS==4)         ; GCAM16
            ORG     X:VBIAS
            DC      (DZ-0020)           ; OFFSET_R (5mV/DN)
            DC      (DZ-0020)           ; OFFSET_L
            DC      (DZ+0010)           ; TEC
            DC      (DZ-1300)           ; OG  voltage
            DC      (DZ+0100)           ; SPARE (10 mV/DN)
            DC      (DZ+0850)           ; RD 0850
            DC      (DZ+1950)           ; OD_R 1950
            DC      (DZ+1950)           ; OD_L 1950

            ORG     X:VCLK
            DC      (DZ-0000)           ; IPC- [V0] voltage (5mV/DN)
            DC      (DZ+1000)           ; IPC+ [V1] +1000 17 Mar 06
            DC      (DZ-1900)           ; RG-  [V2] -1900
            DC      (DZ+0500)           ; RG+  [V3] +0500
            DC      (DZ-1900)           ; S-   [V4] -1900
            DC      (DZ+0300)           ; S+   [V5] +0300
            DC      (DZ-1900)           ; DG-  [V6] -1900
            DC      (DZ+0500)           ; DG+  [V7] +0500
            DC      (DZ-1900)           ; TG-  [V8] -1900
            DC      (DZ+0500)           ; TG+  [V9] +0500
            DC      (DZ-1800)           ; P1-  [V10] -1800
            DC      (DZ+1000)           ; P1+  [V11] +1000
            DC      (DZ-1800)           ; P2-  [V12] -1800
            DC      (DZ+1000)           ; P2+  [V13] +1000
            DC      (DZ-1800)           ; P3-  [V14] -1800
            DC      (DZ+1000)           ; P3+  [V15] +1000
    ENDIF

;*****************************************************************************
;   INITIALIZE X MEMORY
;*****************************************************************************
;        R2L   _______________  ________________ R1L
;        R3L   ______________ || _______________ R3R
;        DG    _____________ |||| ______________ R2R
;        SPARE ____________ |||||| _____________ R1R
;        ST1   ___________ |||||||| ____________ RG
;        ST2   __________ |||||||||| ___________ IPC
;        ST3   _________ |||||||||||| __________ FINT+
;        IM1   ________ |||||||||||||| _________ FINT-
;        IM2   _______ |||||||||||||||| ________ FRST
;        IM3   ______ |||||||||||||||||| _______ CONVST
;                    ||||||||||||||||||||

   IF (RDMODE==0)                   ; MPP clocking mode
             ORG X:MPP              ; reset/hold state
            DC  %000000000000011011000011

            ORG X:IPCLKS            ; input clamp
            DC  %000000000000011011010011
            DC  %000000000000011011000011

            ORG X:TCLKS             ; read temp monitor
            DC  %000000000000011011000010
            DC  %000000000000011011000011

            ORG X:PCLKS_FT          ; frame transfer P1-P2-P3-P1
            DC  %000001101100011011000011
            DC  %000001001000011011000011
            DC  %000011011000011011000011
            DC  %000010010000011011000011
            DC  %000010110100011011000011
            DC  %000000100100011011000011

            ORG X:PCLKS_RD          ; parallel transfer P1-P2-P3-P1
            DC  %000000000100011011010011
            DC  %000000001100011011010011
            DC  %000000001000011011000011
            DC  %000000011000011011000011
            DC  %000000010000011011000011
            DC  %000000000000011011000011

            ORG X:PCLKS_FL          ; parallel flush P1-P2-P3-P1
            DC  %000001101101011011000011	; 01 Nov 07 - RAT
            DC  %000001001001111111100011
            DC  %000011011001111111100011
            DC  %000010010001111111100011
            DC  %000010110101111111100011
            DC  %000000100101011011000011

            ORG X:INT_L             ; reset and first integration
            DC  %000000000000001001100011   ; RG ON  FRST ON
            DC  %000000000000001001000011   ; RG OFF
            DC  %000000000000001001000001   ; FRST OFF
            DC  %000000000000001001001001   ; FINT+ ON
            DC  %000000000000001001000001   ; FINT+ OFF

            ORG X:INT_H             ; second integration and A to D
            DC  %000000000000001001000101   ; FINT- ON
            DC  %000000000000001001000001   ; FINT- OFF
            DC  %000000000000001001000000   ; /CONVST ON
            DC  %000000000000001001000001   ; /CONVST OFF
            DC  %000000000000001001100011   ; FRST ON RG ON

            ORG X:SCLKS_R           ; serial shift (right) S1-S2-S3-S1
            DC  %000000000000011011000001
            DC  %000000000000010010000001
            DC  %000000000000110110000001
            DC  %000000000000100100000001
            DC  %000000000000101101000001
            DC  %000000000000001001000001

            ORG X:SCLKS_FLR         ; serial flush (right) S1-S2-S3-S1
            DC  %000000000000011011100011
            DC  %000000000000010010100011
            DC  %000000000000110110100011
            DC  %000000000000100100100011
            DC  %000000000000101101100011
            DC  %000000000000001001100011

            ORG X:SCLKS_L           ; serial shift (left) S1-S3-S2-S1
            DC  %000000000000101101000001
            DC  %000000000000100100000001
            DC  %000000000000110110000001
            DC  %000000000000010010000001
            DC  %000000000000011011000001
            DC  %000000000000001001000001

            ORG X:SCLKS_FLL         ; serial flush (left) S1-S3-S2-S1
            DC  %000000000000101101100011
            DC  %000000000000100100100011
            DC  %000000000000110110100011
            DC  %000000000000010010100011
            DC  %000000000000011011100011
            DC  %000000000000001001100011

            ORG X:SCLKS_B           ; serial shift (both)
            DC  %000000000000101011000001
            DC  %000000000000100010000001
            DC  %000000000000110110000001
            DC  %000000000000010100000001
            DC  %000000000000011101000001
            DC  %000000000000001001000001

            ORG X:SCLKS_FLB         ; serial flush (both)
            DC  %000000000000101011100011
            DC  %000000000000100010100011
            DC  %000000000000110110100011
            DC  %000000000000010100100011
            DC  %000000000000011101100011
            DC  %000000000000001001100011

            ORG X:SCLKS_FF          ; serial flush (fast) DG
            DC  %000000000001011011100011
            DC  %000000000001000000100011
            DC  %000000000000000000100011
            DC  %000000000000011011100011
            DC  %000000000000011011100011   ; dummy code
            DC  %000000000000011011100011   ; dummy code
   ENDIF


   IF (RDMODE==1)                  ; exp't clocking mode
             ORG X:MPP               ; reset/hold state
            DC  %000000000000011011000011

            ORG X:IPCLKS            ; input clamp
            DC  %000000000000011011010011
            DC  %000000000000011011000011

            ORG X:TCLKS             ; read temp monitor
            DC  %000000000000011011000010
            DC  %000000000000011011000011

            ORG X:PCLKS_FT          ; frame transfer P1-P2-P3-P1
            DC  %000001101100011011000011
            DC  %000001001000011011000011
            DC  %000011011000011011000011
            DC  %000010010000011011000011
            DC  %000010110100011011000011
            DC  %000000100100011011000011

            ORG X:PCLKS_RD          ; parallel transfer P1-P2-P3-P1
            DC  %000000000100011011010011
            DC  %000000001100011011010011
            DC  %000000001000011011000011
            DC  %000000011000011011000011
            DC  %000000010000011011000011
            DC  %000000000000011011000011

            ORG X:PCLKS_FL          ; parallel flush P1-P2-P3-P1
            DC  %000001101101011011000011
            DC  %000001001001011011000011
            DC  %000011011001011011000011
            DC  %000010010001011011000011
            DC  %000010110101011011000011
            DC  %000000100101011011000011

            ORG X:INT_L             ; reset and first integration
            DC  %000000000000011011100011   ; RG ON  FRST ON
            DC  %000000000000011011000011   ; RG OFF
            DC  %000000000000011011000001   ; FRST OFF
            DC  %000000000000011011001001   ; FINT+ ON
            DC  %000000000000011011000001   ; FINT+ OFF

            ORG X:INT_H             ; second integration and A to D
            DC  %000000000000011011000101   ; FINT- ON
            DC  %000000000000011011000001   ; FINT- OFF
            DC  %000000000000011011000000   ; /CONVST ON
            DC  %000000000000011011000001   ; /CONVST OFF
            DC  %000000000000011011100011   ; FRST ON RG ON

            ORG X:SCLKS_R           ; serial shift (right) S2-S3-S1-S2
            DC  %000000000000010010000001
            DC  %000000000000110110000001
            DC  %000000000000100100000001
            DC  %000000000000101101000001
            DC  %000000000000001001000001
            DC  %000000000000011011000001

            ORG X:SCLKS_FLR         ; serial flush (right) S2-S3-S1-S2
            DC  %000000000000010010100011
            DC  %000000000000110110100011
            DC  %000000000000100100100011
            DC  %000000000000101101100011
            DC  %000000000000001001100011
            DC  %000000000000011011100011


            ORG X:SCLKS_L           ; serial shift (left) S1-S3-S2-S1
            DC  %000000000000001001000001
            DC  %000000000000101101000001
            DC  %000000000000100100000001
            DC  %000000000000110110000001
            DC  %000000000000010010000001
            DC  %000000000000011011000001

            ORG X:SCLKS_FLL         ; serial flush (left) S1-S3-S2-S1
            DC  %000000000000001001100011
            DC  %000000000000101101100011
            DC  %000000000000100100100011
            DC  %000000000000110110100011
            DC  %000000000000010010100011
            DC  %000000000000011011100011

            ORG X:SCLKS_B           ; serial shift (both)
            DC  %000000000000001010000001
            DC  %000000000000101110000001
            DC  %000000000000100100000001
            DC  %000000000000110101000001
            DC  %000000000000010001000001
            DC  %000000000000011011000001

            ORG X:SCLKS_FLB         ; serial flush (both)
            DC  %000000000000001010100011
            DC  %000000000000101110100011
            DC  %000000000000100100100011
            DC  %000000000000110101100011
            DC  %000000000000010001100011
            DC  %000000000000011011100011

            ORG X:SCLKS_FF          ; serial flush (fast) DG
            DC  %000000000001011011100011
            DC  %000000000001000000100011
            DC  %000000000000000000100011
            DC  %000000000000011011100011
            DC  %000000000000011011100011   ; dummy code
            DC  %000000000000011011100011   ; dummy code
   ENDIF


;*******************************************************************************
;   GENERAL COMMENTS
;*******************************************************************************
; Hardware RESET causes download from serial port (code in EPROM)
; R0 is a pointer to sequence fragments
; R1 is a pointer used by send/receive routines
; R2 is a pointer to the current data location
; See dspdvr.h for command and opflag definitions
;*******************************************************************************
;   INITIALIZE INTERRUPT VECTORS
;*******************************************************************************
            ORG     P:$0000
            JMP     START
;*******************************************************************************
;   MAIN PROGRAM
;*******************************************************************************
            ORG     P:START
SET_MODE    ORI     #$3,MR                  ; mask all interrupts
            MOVEP   #$FFFC21,X:AAR3         ; PERIPH $FFF000--$FFFFFF
            MOVEP   #$D00909,X:AAR1         ; EEPROM $D00000--$D07FFF 32K
            MOVEP   #$000811,X:AAR0         ; SRAM X $000000--$00FFFF 64K
            MOVEP   #WS,X:BCR               ; Set periph wait states
            MOVE    #SEQ-1,M0               ; Set sequencer address modulus

PORTB_SETUP MOVEP   #>$1,X:PCRB             ; set PB[15..0] GPIO

PORTD_SETUP MOVEP   #>$0,X:PCRD             ; GPIO PD0=TM PD1=GAIN
            MOVEP   #>$3,X:PRRD             ; PD2=/ENRX PD3=/ENTX
            MOVEP   #>$0,X:PDRD             ; PD4=RXRDY

SSI_SETUP   MOVEP   #>$032070,X:CRB         ; async, LSB, enable TE RE
            MOVEP   #>$140803,X:CRA         ; 10 Mbps, 16 bit word
            MOVEP   #>$3F,X:PCRC            ; enable ESSI

PORTE_SETUP MOVEP   #$0,X:PCRE              ; enable GPIO, disable SCI
            MOVEP   #>$1,X:PRRE             ; PE0=SHUTTER
            MOVEP   #>$0,X:PDRE             ;

SET_TIMER   MOVEP   #$300A10,X:TCSR0        ; Pulse mode, no prescale
            MOVEP   #$0,X:TLR0              ; timer reload value
            MOVEP   X:USEC,X:TCPR0          ; timer compare value
            MOVEP   #$308A10,X:TCSR1        ; Pulse mode, prescaled
            MOVEP   #$0,X:TLR1              ; timer reload value
            MOVEP   X:EXP_TIME,X:TCPR1      ; timer compare value
            MOVEP   #>$9C3F,X:TPLR          ; timer prescale ($9C3F=1ms 80MHz)

DMA_SETUP   MOVEP   #PIX,X:DSR0             ; set DMA source
            MOVEP   #$0,X:DCO0              ; set DMA counter
FIBER       JCLR    #$0,X:LINK,RS485        ; set up optical
            MOVEP   #>TXREG,X:DDR0          ; set DMA destination
            MOVEP   #>$080255,X:DCR0        ; DMA word xfer, /IRQA, src+1
RS485       JSET    #$0,X:LINK,ENDDP        ; set up RS485
            MOVEP   #>TXD,X:DDR0            ; DMA destination
            MOVEP   #>$085A51,X:DCR0        ; DMA word xfer, TDE0, src+1
ENDDP       NOP                             ;

INIT_SETUP  JSR     MPPHOLD                 ;
            JSR     SET_GAIN                ;
            JSR     SET_DACS                ;
            JSR     SET_SCLKS               ;

WAIT_CMD    JCLR    #$0,X:LINK,WAITB        ; check for cmd ready
            JCLR    #$4,X:PDRD,ECHO         ; fiber link (single-fiber)
WAITB       JSET    #$0,X:LINK,ENDW         ;
            JCLR    #7,X:SSISR,ECHO         ; wire link
ENDW        NOP                             ;

            JSR     READ16                  ; wait for command word
            MOVE    A1,X:CMD                ; cmd in X:CMD
            JSR     CMD_FIX                 ; interpret command word

ECHO        JCLR    #$1,X:CMD,GET           ; test for DSP_ECHO command
            JSR     READ16                  ;
            JSR     WRITE16                 ;
            BCLR    #$1,X:CMD               ;

GET         JCLR    #$2,X:CMD,PUT           ; test for DSP_GET command
            JSR     MEM_SEND                ;
            BCLR    #$2,X:CMD               ;

PUT         JCLR    #$3,X:CMD,EXP_START     ; test for DSP_PUT command
            JSR     MEM_LOAD                ;
            BCLR    #$3,X:CMD               ;

EXP_START   JCLR    #$6,X:CMD,FASTFLUSH     ; test for EXPOSE command
            JSR     MPPHOLD                 ;
            MOVE    #PIX,R2                 ; set data pointer
            MOVEP   X:EXP_TIME,X:TCPR1      ; timer compare value
            BSET    #$F,X:OPFLAGS           ; set exp_in_progress flag
            BCLR    #$6,X:CMD               ;

            JCLR    #$1,X:OPFLAGS,FASTFLUSH ; check for AUTO_FLUSH
            BSET    #$4,X:CMD               ;

FASTFLUSH   JCLR    #$4,X:CMD,BEAM_ON       ; test for FLUSH command
            JSR     FLUSHFRAME              ; fast FLUSH
            JSR     FLUSHFRAME              ; fast FLUSH
            JSR     FLUSHLINE               ; clear serial register
            BCLR    #$4,X:CMD               ;

BEAM_ON     JCLR    #$5,X:CMD,EXPOSE        ; test for open shutter
            BSET    #$0,X:PDRE              ; set SHUTTER
            BCLR    #$5,X:CMD               ;

EXPOSE      JCLR    #$F,X:OPFLAGS,BEAM_OFF  ; check exp_in_progress flag

            JSR     MPPHOLD                 ;
            JSR     M_TIMER                 ;
            BCLR    #$F,X:OPFLAGS           ; clear exp_in_progress flag

OPT_A       JCLR    #$2,X:OPFLAGS,OPT_B     ; check for AUTO_SHUTTER
            BSET    #$7,X:CMD               ; prep to close shutter
OPT_B       JCLR    #$4,X:OPFLAGS,BEAM_OFF  ; check for AUTO_READ
            BSET    #$8,X:CMD               ; prep for full readout

BEAM_OFF    JCLR    #$7,X:CMD,READ_CCD      ; test for shutter close
            BCLR    #$0,X:PDRE              ; clear SHUTTER
            BCLR    #$7,X:CMD               ;

READ_CCD    JCLR    #$8,X:CMD,AUTO_WIPE     ; test for READCCD command
            JSR     FRAME                   ; frame transfer
;           JSR     IPC_CLAMP               ; discharge ac coupling cap
            JSR     FLUSHROWS               ; vskip
            DO      X:NROWS,END_READ        ; read the array
            JSR     FLUSHLINE               ;
            JSR     PARALLEL                ;
            JSR     FLUSHPIX                ; hskip
            BSET    #$0,X:OPFLAGS           ; set first pixel flag
            JSR     READPIX                 ;
            BCLR    #$0,X:OPFLAGS           ; clear first pixel flag
            JSR     READLINE                ;
END_READ    NOP                             ;
            BCLR    #$8,X:CMD               ;

AUTO_WIPE   JCLR    #$9,X:CMD,HH_DACS       ; test for AUTOWIPE command
;           BSET    #$E,X:OPFLAGS           ;
;           BSET    #$5,X:OPFLAGS           ;
;           JSR     FL_CLOCKS               ; flush one parallel row
;           JSR     READLINE                ;
;           BCLR    #$9,X:CMD               ;

HH_DACS     JCLR    #$A,X:CMD,HH_TEMP       ; test for HH_SYNC command
            JSR     SET_DACS                ;
            BCLR    #$A,X:CMD               ;

HH_TEMP     JCLR    #$B,X:CMD,HH_TEC        ; test for HH_TEMP command
            JSR     TEMP_READ               ; perform housekeeping chores
            BCLR    #$B,X:CMD               ;

HH_TEC      JCLR    #$C,X:CMD,HH_OTHER      ; test for HH_TEC command
            JSR     TEMP_SET                ; set the TEC value
            BCLR    #$C,X:CMD               ;

HH_OTHER    JCLR    #$D,X:CMD,END_CODE      ; test for HH_OTHER command
            JSR     SET_GAIN                ;
            JSR     SET_SCLKS               ;
            JSR     SET_USEC                ;
            BCLR    #$D,X:CMD               ;

END_CODE    JCLR    #$5,X:OPFLAGS,WAIT_CMD  ; check for AUTO_WIPE
            BSET    #$9,X:CMD               ;
            JMP     WAIT_CMD                ; Get next command

;*****************************************************************************
;   HOLD (MPP MODE)
;*****************************************************************************
MPPHOLD     MOVEP   X:MPP,Y:<<SEQREG        ;
            RTS                             ;

;*****************************************************************************
;   INPUT CLAMP
;*****************************************************************************
IPC_CLAMP   MOVEP   X:IPCLKS,Y:<<SEQREG     ;
            MOVE    #>HOLD_IPC,X0           ;
            REP     X0                      ; $1F4O=100 us
            NOP                             ;
            MOVEP   X:(IPCLKS+1),Y:<<SEQREG ;
            NOP                             ;
            RTS                             ;

;*****************************************************************************
;   FLUSHLINE  (FAST FLUSH)
;*****************************************************************************
FLUSHLINE   MOVE    #SCLKS_FF,R0            ; initialize pointer
            DO      #SEQ,ENDFF              ;
            MOVEP   X:(R0)+,Y:<<SEQREG      ;
            REP     #HOLD_FF                ;
            NOP                             ;
ENDFF       RTS                             ;

;*****************************************************************************
;   FLUSHPIX (HSKIP)
;*****************************************************************************
FLUSHPIX    DO      X:HSKIP,ENDFP           ;
            MOVE    X:SCLKS_FL,R0           ; initialize pointer
            DO      #SEQ,ENDHCLK            ;
            MOVEP   X:(R0)+,Y:<<SEQREG      ;
            REP     #HOLD_S                 ;
            NOP                             ;
ENDHCLK     NOP                             ;
ENDFP       RTS                             ;

;*****************************************************************************
;   FLUSHROWS (VSKIP)
;*****************************************************************************
FLUSHROWS   DO      X:VSKIP,ENDVSKIP        ;
            MOVE    #PCLKS_RD,R0            ; initialize pointer
            DO      #SEQ,ENDVCLK            ;
            MOVEP   X:(R0)+,Y:<<SEQREG      ;
            REP     #HOLD_FL                ;
            NOP                             ;
ENDVCLK     NOP                             ;
ENDVSKIP    RTS                             ;

;*****************************************************************************
;   FLUSHFRAME
;*****************************************************************************
FLUSHFRAME  DO      X:NFT,ENDFLFR           ;
FL_CLOCKS   MOVE    #PCLKS_FL,R0            ; initialize pointer
            DO      #SEQ,ENDFLCLK           ;
            MOVEP   X:(R0)+,Y:<<SEQREG      ;
            REP     #HOLD_FL                ;
            NOP                             ;
ENDFLCLK    NOP                             ;
ENDFLFR     RTS                             ;

;*****************************************************************************
;   PARALLEL TRANSFER (READOUT)
;*****************************************************************************
PARALLEL    DO      X:VBIN,ENDPT            ;
P_CLOCKS    MOVE    #PCLKS_RD,R0            ; initialize pointer
            DO      #SEQ,ENDPCLK            ;
            MOVEP   X:(R0)+,Y:<<SEQREG      ;
            MOVE    #>HOLD_P,X0             ;
            REP     X0                      ; $317=10us per phase
            NOP                             ;
ENDPCLK     NOP                             ;
ENDPT       RTS                             ;

;*****************************************************************************
;   PARALLEL TRANSFER (FRAME TRANSFER)
;*****************************************************************************
FRAME       MOVEP   X:(PCLKS_FT),Y:<<SEQREG ; 100 us CCD47 pause
            MOVE    #>$1F40,X0              ;
            REP     X0                      ; $1F40=100 usec
            NOP                             ;
            DO      X:NFT,ENDFT             ;
FT_CLOCKS   MOVE    #PCLKS_FT,R0            ; initialize seq pointer
            DO      #SEQ,ENDFTCLK           ;
            MOVEP   X:(R0)+,Y:<<SEQREG      ;
            REP     #HOLD_FT                ;
            NOP                             ;
ENDFTCLK    NOP                             ;
ENDFT       RTS                             ;

;*****************************************************************************
;   READLINE SUBROUTINE
;*****************************************************************************
READLINE    DO      X:NCOLS,ENDRL           ;
READPIX     MOVEP   X:(INT_L),Y:<<SEQREG    ; FRST=ON RG=ON
            DUP     HOLD_RG                 ; macro
            NOP                             ;
            ENDM                            ; end macro
            MOVEP   X:(INT_L+1),Y:<<SEQREG  ; RG=OFF
            MOVEP   X:(INT_L+2),Y:<<SEQREG  ; FRST=OFF
            REP     #HOLD_SIG               ; preamp settling time
;           REP     #$F                     ; preamp settling
            NOP                             ;
INT1        MOVEP   X:(INT_L+3),Y:<<SEQREG  ; FINT+=ON
SLEEP1      MOVE    X:USEC,X0               ; sleep USEC * 12.5ns
            REP     X0                      ;
            NOP                             ;
            MOVEP   X:(INT_L+4),Y:<<SEQREG  ; FINT+=OFF
SERIAL      MOVE    X:SCLKS,R0              ; serial transfer
            DO      X:HBIN,ENDSCLK          ;
S_CLOCKS    DUP     SEQ                     ;    macro
            MOVEP   X:(R0)+,Y:<<SEQREG      ;
            DUP     HOLD_S                  ;    macro
            NOP                             ;
            ENDM                            ;
            ENDM                            ;
ENDSCLK     REP     #HOLD_SIG               ; preamp settling time
            NOP                             ; (adjust with o'scope)
GET_DATA    MOVEP   #WS5,X:BCR              ;
            NOP                             ;
            NOP                             ;
            MOVEP   Y:<<ADC_A,A             ; read ADC
            MOVEP   Y:<<ADC_B,B             ; read ADC
            MOVEP   #WS,X:BCR               ;
            NOP                             ;
INT2        MOVEP   X:(INT_H),Y:<<SEQREG    ; FINT-=ON
SLEEP2      MOVE    X:USEC,X0               ; sleep USEC * 20ns
            REP     X0                      ;
            NOP                             ;
            MOVEP   X:(INT_H+1),Y:<<SEQREG  ; FINT-=OFF
    IF (SYS==1)
DATA_MASK   AND     #>$3FFF,A               ; keep only 14-bits
            AND     #>$3FFF,B               ;
            BCHG    #$D,A1                  ; 2complement to binary
            BCHG    #$D,B1                  ;
    ENDIF
            MOVE    A1,Y:(PIX)              ;
            MOVE    B1,Y:(PIX+1)            ;
            REP     #HOLD_ADC               ; settling time
            NOP                             ; (adjust for best noise)
CONVST      MOVEP   X:(INT_H+2),Y:<<SEQREG  ; /CONVST=ON
            MOVEP   N5,X:DSR0               ; set DMA source
            NOP                             ;
            NOP                             ;
            MOVEP   X:(INT_H+3),Y:<<SEQREG  ; /CONVST=OFF MIN 40 NS
            MOVEP   X:(INT_H+4),Y:<<SEQREG  ; FRST=ON
            JSET    #$0,X:OPFLAGS,ENDCHK    ; check for first pixel
            BSET    #$17,X:DCR0             ; enable DMA
ENDCHK      NOP                             ;
ENDRL       RTS                             ;

;*******************************************************************************
;   READ AND WRITE 16-BIT AND 24-BIT DATA
;*******************************************************************************
READ16      JCLR    #$0,X:LINK,RD16B        ; check RS485 or fiber
            JCLR    #$4,X:PDRD,*            ; wait for data in RXREG
            MOVE    Y:RXREG,A               ; bits 15..0
            AND     #>$FFFF,A               ;
RD16B       JSET    #$0,X:LINK,ENDRD16      ; check RS485 or fiber
            JCLR    #7,X:SSISR,*            ; wait for RDRF to go high
            MOVE    X:RXD,A1                ; read from ESSI
            NOP                             ;
ENDRD16     RTS                             ; 16-bit word in A1

WRITE16     JCLR    #$0,X:LINK,WR16B        ; check RS485 or fiber
            MOVE    A1,Y:TXREG              ; write bits 15..0
WR16B       JSET    #$0,X:LINK,ENDWR16      ;
            JCLR    #6,X:SSISR,*            ; wait for TDE
            MOVE    A1,X:TXD                ;
ENDWR16     RTS                             ;

READ24      JCLR    #$0,X:LINK,RD24B        ; check RS485 or fiber
            JCLR    #$4,X:PDRD,*            ; wait for data in RXREG
            MOVE    Y:RXREG,A               ; bits 15..0
            AND     #>$FFFF,A               ;
            ASR     #$10,A,A                ; shift right 16 bits
            JCLR    #$4,X:PDRD,*            ; wait for data in RXREG
            MOVE    Y:RXREG,A1              ; bits 15..0
            ASL     #$10,A,A                ; shift left 16 bits
RD24B       JSET    #$0,X:LINK,ENDRD24      ;
            JCLR    #7,X:SSISR,*            ; wait for RDRF to go high
            MOVE    X:RXD,A                 ; read from ESSI
            ASR     #$10,A,A                ; shift right 16 bits
            JCLR    #7,X:SSISR,*            ; wait for RDRF to go high
            MOVE    X:RXD,A1                ;
            ASL     #$10,A,A                ; shift left 16 bits
ENDRD24     RTS                             ; 24-bit word in A1

WRITE24     JCLR    #$0,X:LINK,WR24B        ; check RS485 or fiber
            MOVE    A1,Y:TXREG              ; send bits 15..0
            ASR     #$10,A,A                ; right shift 16 bits
            REP     #$10                    ; wait for data sent
            NOP                             ;
            MOVE    A1,Y:TXREG              ; send bits 23..16
WR24B       JSET    #$0,X:LINK,ENDWR24      ;
            JCLR    #6,X:SSISR,*            ; wait for TDE
            MOVE    A1,X:TXD                ; send bits 15..0
            ASR     #$10,A,A                ; right shift 16 bits
            NOP                             ; wait for flag update
            JCLR    #6,X:SSISR,*            ; wait for TDE
            MOVE    A1,X:TXD                ; send bits 23..16
ENDWR24     RTS                             ;

;*****************************************************************************
;   LOAD NEW DATA VIA SSI PORT
;*****************************************************************************
MEM_LOAD    JSR     READ24                  ; get memspace/address
            MOVE    A1,R1                   ; load address into R1
            MOVE    A1,X0                   ; store memspace code
            JSR     READ24                  ; get data
            BCLR    #$17,R1                 ; clear memspace bit
X_LOAD      JSET    #$17,X0,Y_LOAD          ;
            MOVE    A1,X:(R1)               ; load x memory
Y_LOAD      JCLR    #$17,X0,END_LOAD        ;
            MOVE    A1,Y:(R1)               ; load y memory
END_LOAD    RTS                             ;

;*****************************************************************************
;   SEND MEMORY CONTENTS VIA SSI PORT
;*****************************************************************************
MEM_SEND    JSR     READ24                  ; get memspace/address
            MOVE    A1,R1                   ; load address into R1
            MOVE    A1,X0                   ; save memspace code
            BCLR    #$17,R1                 ; clear memspace bit
X_SEND      JSET    #$17,X0,Y_SEND          ;
            MOVE    X:(R1),A1               ; send x memory
Y_SEND      JCLR    #$17,X0,WRITE24         ;
            MOVE    Y:(R1),A1               ; send y memory
SEND24      JSR     WRITE24                 ;
            NOP                             ;
            RTS                             ;

;*****************************************************************************
;   SET DAC VOLTAGES  DEFAULTS:  OD=20V  RD=8V  OG=ABG=-6V
;   PCLKS=+3V -9V SCLKS=+2V -8V RG=+3V -9V
;*****************************************************************************
SET_DACS    JSR     SET_VBIAS               ;
            JSR     SET_VCLKS               ;
            RTS                             ;

SET_VBIAS   MOVEP   #WS5,X:BCR              ; add wait states
            MOVE    #VBIAS,R3               ; bias voltages
            MOVE    #SIG_AB,R4              ; bias DAC registers
            DO      #$8,ENDSETB             ; set bias voltages
            MOVE    X:(R3)+,X0              ;
            MOVE    X0,Y:(R4)+              ;
ENDSETB     MOVEP   #WS,X:BCR               ;
            RTS                             ;

SET_VCLKS   MOVEP   #WS5,X:BCR              ; add wait states
            MOVE    #VCLK,R3                ; clock voltages
            MOVE    #CLK_AB,R4              ; clock DAC registers
            DO      #$10,ENDSETV            ; set clock voltages
            MOVE    X:(R3)+,X0              ;
            MOVE    X0,Y:(R4)+              ;
ENDSETV     MOVEP   #WS,X:BCR               ; re-set wait states
            RTS

;*****************************************************************************
;   TEMP MONITOR ADC START AND CONVERT
;*****************************************************************************
TEMP_READ   BSET    #$0,X:PDRD              ; turn on temp sensor

; -------------------------------------------------------------------
; test  - 30 oct 07	RAT
; set OFFSET_R to zero during idle periods.

            MOVEP   #WS5,X:BCR              ; add wait states
            MOVE    #DZ+0200,X0             ; temperature bias voltage (OFFSET_R is first)
            MOVE    #SIG_AB,R4              ; bias DAC registers
		NOP					  ; -RAT 5 sep 08
		NOP					  ; -RAT 5 sep 08
            MOVE    X0,Y:(R4)               ;
            MOVEP   #WS,X:BCR               ; re-set wait states	

;--------------------------------------------------------------------

            MOVEP   #$20,X:TCPR1            ; set timer compare value
            JSR     M_TIMER                 ; wait for output to settle

            MOVEP   #WS3,X:BCR              ; set wait states for ADC
            MOVEP   X:TCLKS,Y:<<SEQREG      ; assert /CONVST
            REP     #$4                     ;
            NOP                             ;
            MOVEP   X:(TCLKS+1),Y:<<SEQREG  ; deassert /CONVST and wait
            REP     #$50                    ;
            NOP                             ;

            MOVEP   Y:<<ADC_B,A1            ; read ADC2
            MOVE    #>$3FFF,X1              ; prepare 14-bit mask
            AND     X1,A1                   ; get 14 LSBs
            BCLR    #$0,X:PDRD              ; turn off temp sensor
            BCHG    #$D,A1                  ; 2complement to binary
            MOVEP   #WS,X:BCR               ; re-set wait states
            MOVE    A1,X:TEMP               ;
            RTS                             ;

TEMP_SET    MOVEP   #WS5,X:BCR              ; add wait states
            NOP                             ;

; -------------------------------------------------------------------
; test  - 23 oct 07	RAT
; restore OFFSET_R value during imaging

            MOVE    #VBIAS,R3               ; bias voltages (OFFSET_R is first)
            MOVE    #SIG_AB,R4              ; bias DAC registers
	    NOP				    ; -RAT 5 sep 08
            MOVE    X:(R3),X0               ;
            MOVE    X0,Y:(R4)               ;

;--------------------------------------------------------------------

            MOVEP   X:TEC,Y:<<TEC_REG       ; set TEC DAC
            MOVEP   #WS,X:BCR               ; re-set wait states
            RTS

;*****************************************************************************
;   MILLISECOND AND MICROSECOND TIMER MODULE
;*****************************************************************************
U_TIMER     BSET    #$0,X:TCSR0             ; start timer
            BTST    #$0,X:TCSR0             ; delay for flag update

            JCLR    #$15,X:TCSR0,*          ; wait for TCF flag
            BCLR    #$0,X:TCSR0             ; stop timer, clear flag
            RTS                             ; flags update during RTS

M_TIMER     BSET    #$0,X:TCSR1             ; start timer
            BTST    #$0,X:TCSR0             ; delay for flag update

            JCLR    #$15,X:TCSR1,*          ; wait for TCF flag
            BCLR    #$0,X:TCSR1             ; stop timer, clear flag
            RTS                             ; flags update during RTS

;*****************************************************************************
;   SIGNAL-PROCESSING GAIN MODULE
;*****************************************************************************
SET_GAIN    JSET    #$0,X:GAIN,HI_GAIN      ;
            BCLR    #$1,X:PDRD              ; set gain=0
HI_GAIN     JCLR    #$0,X:GAIN,END_GAIN     ;
            BSET    #$1,X:PDRD              ; set gain=1
END_GAIN    RTS                             ;

;*****************************************************************************
;   SIGNAL-PROCESSING DUAL-SLOPE TIME MODULE
;*****************************************************************************
SET_USEC    MOVEP   X:USEC,X:TCPR0          ; timer compare value
END_USEC    RTS                             ;

;*****************************************************************************
;   SELECT SERIAL CLOCK SEQUENCE (IE OUTPUT AMPLIFIER)
;*****************************************************************************
SET_SCLKS   MOVE    X:OPCH,A                ; 0x1=right 0x2=left
RIGHT_AMP   MOVE    #>$1,X0                 ; 0x3=both  0x4=all
            CMP     X0,A                    ;
            JNE     LEFT_AMP                ;
            MOVE    #>SCLKS_R,Y0            ; serial clock sequences
            MOVE    #>SCLKS_FLR,Y1          ; serial flush sequences
            MOVE    #PIX+1,N5               ; pointer to start of data
            MOVEP   #>$0,X:DCO0             ; DMA counter
LEFT_AMP    MOVE    #>$2,X0                 ;
            CMP     X0,A                    ;
            JNE     BOTH_AMP                ;
            MOVE    #>SCLKS_L,Y0            ;
            MOVE    #>SCLKS_FLL,Y1          ;
            MOVE    #PIX,N5                 ;
            MOVEP   #>$0,X:DCO0             ;
BOTH_AMP    MOVE    #>$3,X0                 ;
            CMP     X0,A                    ;
            JNE     END_AMP                 ;
            MOVE    #>SCLKS_B,Y0            ;
            MOVE    #>SCLKS_FLB,Y1          ;
            MOVE    #PIX,N5                 ;
            MOVEP   #>$1,X:DCO0             ;
END_AMP     MOVE    Y0,X:SCLKS              ;
            MOVE    Y1,X:SCLKS_FL           ;
            RTS                             ;

;*****************************************************************************
;   CMD.ASM -- ROUTINE TO INTERPRET AN 8-BIT COMMAND + COMPLEMENT
;*****************************************************************************
; Each command word is sent as two bytes -- the LSB has the command
; and the MSB has the complement.

CMD_FIX     MOVE    X:CMD,A                 ; extract cmd[7..0]
            AND     #>$FF,A                 ; and put in X1
            MOVE    A1,X1                   ;
            MOVE    X:CMD,A                 ; extract cmd[15..8]
            LSR     #$8,A                   ; complement
            NOT     A   #>$1,B              ; and put in A1
            AND     #>$FF,A                 ;
            ASL     X1,B,B                  ;
            CMP     X1,A                    ; compare X1 and A1
            JEQ     CMD_OK                  ;
CMD_NG      CLR     B                       ; cmd word no good
            NOP                             ;
CMD_OK      MOVE    B1,X:CMD                ; cmd word OK
            NOP                             ;
END_CMD     RTS                             ;

            END
