
Motorola DSP56300 Assembler  Version 6.3.4   09-02-02  16:00:28  gcam_ccd57.asm  Page 1



1      
2                          ;*****************************************************************************
3                          ;   GCAM.ASM -- DSP-BASED CCD CONTROLLER PROGRAM
4                          ;
5                          ;   This version slightly modified by Michael Lesser from
6                          ;   original code by Greg Burley for operation of the
7                          ;   ITL guider.
8                          ;
9                          ;   Last change 02Feb09 RAT - dual readout missing data, V and H skips fixed
10                         ;   revised flush code 31 oct 2007  RAT
11                         ;*****************************************************************************
12                             PAGE    110,60,1,1
13                             TABS    4
14                         ;*****************************************************************************
15                         ;   SYS=    0=DEFAULT               1=GCAM              2=GCAM16
16                         ;           3=GCAM16 (w/FIBER)      4=GCAM16 CCD57      5=
17                         ;*****************************************************************************
18                         ;   DEFINITIONS & POINTERS
19                         ;*****************************************************************************
20        000100           START       EQU     $000100             ; program start location
21        000006           SEQ         EQU     $000006             ; seq fragment length
22        001000           DZ          EQU     $001000             ; DAC zero volt offset
23     
24        073FE1           WS          EQU     $073FE1             ; periph wait states
25        073FE1           WS1         EQU     $073FE1             ; 1 PERIPH 1 SRAM 31 EPROM
26        077FE1           WS3         EQU     $077FE1             ; 3 PERIPH 1 SRAM 31 EPROM
27        07BFE1           WS5         EQU     $07BFE1             ; 5 PERIPH 1 SRAM 31 EPROM
28     
29                         ;*****************************************************************************
30                         ;   COMPILE-TIME OPTIONS
31                         ;*****************************************************************************
32                             IF (SYS==1)                         ; GCAM -- CCD47-20 14-BIT
59                             ENDIF
60     
61                             IF (SYS==2)                         ; GCAM16 -- CCD47-20 16-BIT
89                             ENDIF
90     
91                             IF (SYS==3)                         ; GCAM16 w/FIBER  CCD47-20 16-BIT
119                            ENDIF
120    
121                            IF (SYS==4)                         ; CCD57 -- 16-BIT
122       000001           VERSION         EQU     $1              ;
123       000000           RDMODE          EQU     $0              ;
124       00020A           HOLD_P          EQU     $020A           ; P clock timing $20A=40us
125       00007C           HOLD_FT         EQU     $007C           ; FT clock timing $7C=10us xfer
126       00007C           HOLD_FL         EQU     $007C           ; FL clock timimg
127       000005           HOLD_S          EQU     $0005           ; S clock timing
128       000006           HOLD_RG         EQU     $0006           ; RG timing
129       001F40           HOLD_PL         EQU     $1F40           ; pre-line settling (1F40=100us)
130       000020           HOLD_FF         EQU     $0020           ; FF clock timimg
131       001F40           HOLD_IPC        EQU     $1F40           ; IPC clock timing ($1F40=100us)
132       00000F           HOLD_SIG        EQU     $000F           ; preamp settling time (was F)
133       00000F           HOLD_ADC        EQU     $000F           ; pre-sample settling
134       000210           INIT_NROWS      EQU     $210            ; $210=528


Motorola DSP56300 Assembler  Version 6.3.4   09-02-02  16:00:28  gcam_ccd57.asm  Page 2



135       000230           INIT_NCOLS      EQU     $230            ; $230=536+24
136       000210           INIT_NFT        EQU     $210            ; $210=528
137                        INIT_NFLUSH
138       000230           INIT_NFLUSH     EQU     $230            ; $230=536+24
139       000001           INIT_NCH        EQU     $1              ;
140       000001           INIT_VBIN       EQU     $1              ;
141       000001           INIT_HBIN       EQU     $1              ;
142       000008           INIT_VSKIP      EQU     $8              ; MPL
143       000018           INIT_HSKIP      EQU     $18             ; MPL
144       000000           INIT_GAIN       EQU     $0              ; 0=LOW 1=HIGH
145       0000C8           INIT_USEC       EQU     $C8             ; normally $C8
146       000002           INIT_OPCH       EQU     $2              ; 1=CH_A 2=CH_B
147       000002           INIT_SCLKS      EQU     $2              ; 1=LEFT 2=RIGHT
148       000000           INIT_PID        EQU     $0              ; FLAG $0=OFF $1=ON
149       000000           INIT_LINK       EQU     $0              ; 0=wire 1=single_fiber
150                            ENDIF
151    
152                        ;*****************************************************************************
153                        ;   EXTERNAL PERIPHERAL DEFINITIONS (GUIDER CAMERA)
154                        ;*****************************************************************************
155       FFFF80           SEQREG      EQU     $FFFF80             ; external CCD clock register
156       FFFF81           ADC_A       EQU     $FFFF81             ; A/D converter #1
157       FFFF82           ADC_B       EQU     $FFFF82             ; A/D converter #2
158       FFFF85           TXREG       EQU     $FFFF85             ; Transmit Data Register
159       FFFF86           RXREG       EQU     $FFFF86             ; Receive Data register
160       FFFF88           SIG_AB      EQU     $FFFF88             ; bias voltages A+B
161       FFFF90           CLK_AB      EQU     $FFFF90             ; clock voltages A+B
162       FFFF8A           TEC_REG     EQU     $FFFF8A             ; TEC register
163    
164                        ;*****************************************************************************
165                        ;   INTERNAL PERIPHERAL DEFINITIONS (DSP563000)
166                        ;*****************************************************************************
167       FFFFFF           IPRC        EQU     $FFFFFF             ; Interrupt priority register (core)
168       FFFFFE           IPRP        EQU     $FFFFFE             ; Interrupt priority register (periph)
169       FFFFFD           PCTL        EQU     $FFFFFD             ; PLL control register
170       FFFFFB           BCR         EQU     $FFFFFB             ; Bus control register (wait states)
171       FFFFF9           AAR0        EQU     $FFFFF9             ; Address attribute register 0
172       FFFFF8           AAR1        EQU     $FFFFF8             ; Address attribute register 1
173       FFFFF7           AAR2        EQU     $FFFFF7             ; Address attribute register 2
174       FFFFF6           AAR3        EQU     $FFFFF6             ; Address attribute register 3
175       FFFFF5           IDR         EQU     $FFFFF5             ; ID Register
176       FFFFC9           PDRB        EQU     $FFFFC9             ; Port B (HOST) GPIO data
177       FFFFC8           PRRB        EQU     $FFFFC8             ; Port B (HOST) GPIO direction
178       FFFFC4           PCRB        EQU     $FFFFC4             ; Port B (HOST) control register
179       FFFFBF           PCRC        EQU     $FFFFBF             ; Port C (ESSI_0) control register
180       FFFFBE           PRRC        EQU     $FFFFBE             ; Port C (ESSI_0) direction
181       FFFFBD           PDRC        EQU     $FFFFBD             ; Port C (ESSI_0) data
182       FFFFBC           TXD         EQU     $FFFFBC             ; ESSI0 Transmit Data Register 0
183       FFFFB8           RXD         EQU     $FFFFB8             ; ESSI0 Receive Data Register
184       FFFFB7           SSISR       EQU     $FFFFB7             ; ESSI0 Status Register
185       FFFFB6           CRB         EQU     $FFFFB6             ; ESSI0 Control Register B
186       FFFFB5           CRA         EQU     $FFFFB5             ; ESSI0 Control Register A
187       FFFFAF           PCRD        EQU     $FFFFAF             ; Port D (ESSI_1) control register
188       FFFFAE           PRRD        EQU     $FFFFAE             ; Port D (ESSI_1) direction


Motorola DSP56300 Assembler  Version 6.3.4   09-02-02  16:00:28  gcam_ccd57.asm  Page 3



189       FFFFAD           PDRD        EQU     $FFFFAD             ; Port D (ESSI_1) data
190       FFFF9F           PCRE        EQU     $FFFF9F             ; Port E (SCI) control register
191       FFFF9E           PRRE        EQU     $FFFF9E             ; Port E (SCI) data direction
192       FFFF9D           PDRE        EQU     $FFFF9D             ; Port E (SCI) data
193       FFFF8F           TCSR0       EQU     $FFFF8F             ; TIMER0 Control/Status Register
194       FFFF8E           TLR0        EQU     $FFFF8E             ; TIMER0 Load Reg
195       FFFF8D           TCPR0       EQU     $FFFF8D             ; TIMER0 Compare Register
196       FFFF8C           TCR0        EQU     $FFFF8C             ; TIMER0 Count Register
197       FFFF8B           TCSR1       EQU     $FFFF8B             ; TIMER1 Control/Status Register
198       FFFF8A           TLR1        EQU     $FFFF8A             ; TIMER1 Load Reg
199       FFFF89           TCPR1       EQU     $FFFF89             ; TIMER1 Compare Register
200       FFFF88           TCR1        EQU     $FFFF88             ; TIMER1 Count Register
201       FFFF87           TCSR2       EQU     $FFFF87             ; TIMER2 Control/Status Register
202       FFFF86           TLR2        EQU     $FFFF86             ; TIMER2 Load Reg
203       FFFF85           TCPR2       EQU     $FFFF85             ; TIMER2 Compare Register
204       FFFF84           TCR2        EQU     $FFFF84             ; TIMER2 Count Register
205       FFFF83           TPLR        EQU     $FFFF83             ; TIMER Prescaler Load Register
206       FFFF82           TPCR        EQU     $FFFF82             ; TIMER Prescalar Count Register
207       FFFFEF           DSR0        EQU     $FFFFEF             ; DMA source address
208       FFFFEE           DDR0        EQU     $FFFFEE             ; DMA dest address
209       FFFFED           DCO0        EQU     $FFFFED             ; DMA counter
210       FFFFEC           DCR0        EQU     $FFFFEC             ; DMA control register
211    
212                        ;*****************************************************************************
213                        ;   REGISTER DEFINITIONS (GUIDER CAMERA)
214                        ;*****************************************************************************
215       000000           CMD         EQU     $000000             ; command word/flags from host
216       000001           OPFLAGS     EQU     $000001             ; operational flags
217       000002           NROWS       EQU     $000002             ; number of rows to read
218       000003           NCOLS       EQU     $000003             ; number of columns to read
219       000004           NFT         EQU     $000004             ; number of rows for frame transfer
220       000005           NFLUSH      EQU     $000005             ; number of columns to flush
221       000006           NCH         EQU     $000006             ; number of output channels (amps)
222       000007           NPIX        EQU     $000007             ; (not used)
223       000008           VBIN        EQU     $000008             ; vertical (parallel) binning
224       000009           HBIN        EQU     $000009             ; horizontal (serial) binning
225       00000A           VSKIP       EQU     $00000A             ; V prescan or offset (rows)
226       00000B           HSKIP       EQU     $00000B             ; H prescan or offset (columns)
227       00000C           VSUB        EQU     $00000C             ; V subraster size
228       00000D           HSUB        EQU     $00000D             ; H subraster size
229       00000E           NEXP        EQU     $00000E             ; number of exposures (not used)
230       00000F           NSHUFFLE    EQU     $00000F             ; (not used)
231    
232       000010           EXP_TIME    EQU     $000010             ; CCD integration time(r)
233       000011           TEMP        EQU     $000011             ; Temperature sensor reading(s)
234       000012           GAIN        EQU     $000012             ; Sig_proc gain
235       000013           USEC        EQU     $000013             ; Sig_proc sample time
236       000014           OPCH        EQU     $000014             ; Output channel
237       000015           HDIR        EQU     $000015             ; serial clock direction
238       000016           LINK        EQU     $000016             ; 0=wire 1=single_fiber
239    
240       000030           SCLKS       EQU     $000030             ; serial clocks
241       000031           SCLKS_FL    EQU     $000031             ; serial clocks flush
242       000032           INT_X       EQU     $000032             ; reset and integrate clocks


Motorola DSP56300 Assembler  Version 6.3.4   09-02-02  16:00:28  gcam_ccd57.asm  Page 4



243       000033           NDMA        EQU     $000033             ; (not used)
244    
245       000018           VBIAS       EQU     $000018             ; bias voltages
246       000020           VCLK        EQU     $000020             ; clock voltages
247       00001A           TEC         EQU     $00001A             ; TEC current
248       000300           PIX         EQU     $000300             ; start address for data storage
249    
250                        ;*****************************************************************************
251                        ;   SEQUENCE FRAGMENT STARTING ADDRESSES (& OTHER POINTERS)
252                        ;*****************************************************************************
253       000040           MPP         EQU     $0040               ; MPP/hold state
254       000042           IPCLKS      EQU     $0042               ; input clamp
255       000044           TCLKS       EQU     $0044               ; Temperature monitor clocks
256       000048           PCLKS_FT    EQU     $0048               ; parallel frame transfer
257       000050           PCLKS_RD    EQU     $0050               ; parallel read-out transfer
258       000058           PCLKS_FL    EQU     $0058               ; parallel flush transfer
259       000060           INT_L       EQU     $0060               ; reset and first integration $0060
260       000068           INT_H       EQU     $0068               ; second integration and A/D $0068
261       000070           SCLKS_R     EQU     $0070               ; serial clocks shift right
262       000080           SCLKS_FLR   EQU     $0080               ; serial clocks flush right
263       000078           SCLKS_L     EQU     $0078               ; serial clocks shift left
264       000088           SCLKS_FLL   EQU     $0088               ; serial clocks flush left
265       000090           SCLKS_B     EQU     $0090               ; serial clocks both
266       000098           SCLKS_FLB   EQU     $0098               ; serial clocks flush both
267       0000A0           SCLKS_FF    EQU     $00A0               ; serial clocks fast flush
268    
269                        ;*******************************************************************************
270                        ;   INITIALIZE X MEMORY AND DEFINE PERIPHERALS
271                        ;*******************************************************************************
272       X:000000                     ORG     X:CMD               ; CCD control information
273       X:000000                     DC      $0                  ; CMD/FLAGS
274       X:000001                     DC      $0                  ; OPFLAGS
275       X:000002                     DC      INIT_NROWS          ; NROWS
276       X:000003                     DC      INIT_NCOLS          ; NCOLS
277       X:000004                     DC      INIT_NFT            ; NFT
278       X:000005                     DC      INIT_NFLUSH         ; NFLUSH
279       X:000006                     DC      INIT_NCH            ; NCH
280       X:000007                     DC      $1                  ; NPIX (not used)
281       X:000008                     DC      INIT_VBIN           ; VBIN
282       X:000009                     DC      INIT_HBIN           ; HBIN
283       X:00000A                     DC      INIT_VSKIP          ; VSKIP ($0)
284       X:00000B                     DC      INIT_HSKIP          ; HSKIP ($0)
285       X:00000C                     DC      $0                  ; VSUB
286       X:00000D                     DC      $0                  ; HSUB
287       X:00000E                     DC      $1                  ; NEXP (not used)
288       X:00000F                     DC      $0                  ; (not used)
289    
290       X:000010                     ORG     X:EXP_TIME
291       X:000010                     DC      $3E8                ; EXP_TIME
292       X:000011                     DC      $0                  ; TEMP
293       X:000012                     DC      INIT_GAIN           ; GAIN
294       X:000013                     DC      INIT_USEC           ; USEC SAMPLE TIME
295       X:000014                     DC      INIT_OPCH           ; OUTPUT CHANNEL
296       X:000015                     DC      INIT_SCLKS          ; HORIZ DIRECTION


Motorola DSP56300 Assembler  Version 6.3.4   09-02-02  16:00:28  gcam_ccd57.asm  Page 5



297       X:000016                     DC      INIT_LINK           ; SERIAL LINK
298    
299                            IF (SYS==1)                         ; GCAM
327                            ENDIF
328    
329                            IF (SYS==2||SYS==3||SYS==4)         ; GCAM16
330       X:000018                     ORG     X:VBIAS
331       X:000018                     DC      (DZ-0020)           ; OFFSET_R (5mV/DN)
332       X:000019                     DC      (DZ-0020)           ; OFFSET_L
333       X:00001A                     DC      (DZ+0010)           ; TEC
334       X:00001B                     DC      (DZ-1260)           ; OG  voltage
335       X:00001C                     DC      (DZ+0100)           ; SPARE (10 mV/DN)
336       X:00001D                     DC      (DZ+0870)           ; RD
337       X:00001E                     DC      (DZ+2070)           ; OD_R
338       X:00001F                     DC      (DZ+2070)           ; OD_L
339    
340       X:000020                     ORG     X:VCLK
341       X:000020                     DC      (DZ-0000)           ; IPC- [V0] voltage (5mV/DN)
342       X:000021                     DC      (DZ+1000)           ; IPC+ [V1] +1000 17 Mar 06
343       X:000022                     DC      (DZ-1900)           ; RG-  [V2] -1900
344       X:000023                     DC      (DZ+0500)           ; RG+  [V3] +0500
345       X:000024                     DC      (DZ-1900)           ; S-   [V4] -1900
346       X:000025                     DC      (DZ+0300)           ; S+   [V5] +0300
347       X:000026                     DC      (DZ-1900)           ; DG-  [V6] -1900
348       X:000027                     DC      (DZ+0500)           ; DG+  [V7] +0500
349       X:000028                     DC      (DZ-1900)           ; TG-  [V8] -1900
350       X:000029                     DC      (DZ+0500)           ; TG+  [V9] +0500
351       X:00002A                     DC      (DZ-1800)           ; P1-  [V10] -1800
352       X:00002B                     DC      (DZ+1000)           ; P1+  [V11] +1000
353       X:00002C                     DC      (DZ-1800)           ; P2-  [V12] -1800
354       X:00002D                     DC      (DZ+1000)           ; P2+  [V13] +1000
355       X:00002E                     DC      (DZ-1800)           ; P3-  [V14] -1800
356       X:00002F                     DC      (DZ+1000)           ; P3+  [V15] +1000
357                            ENDIF
358    
359                        ;*****************************************************************************
360                        ;   INITIALIZE X MEMORY
361                        ;*****************************************************************************
362                        ;        R2L   _______________  ________________ R1L
363                        ;        R3L   ______________ || _______________ R3R
364                        ;        DG    _____________ |||| ______________ R2R
365                        ;        SPARE ____________ |||||| _____________ R1R
366                        ;        ST1   ___________ |||||||| ____________ RG
367                        ;        ST2   __________ |||||||||| ___________ IPC
368                        ;        ST3   _________ |||||||||||| __________ FINT+
369                        ;        IM1   ________ |||||||||||||| _________ FINT-
370                        ;        IM2   _______ |||||||||||||||| ________ FRST
371                        ;        IM3   ______ |||||||||||||||||| _______ CONVST
372                        ;                    ||||||||||||||||||||
373    
374                           IF (RDMODE==0)                   ; MPP clocking mode
375       X:000040                      ORG X:MPP              ; reset/hold state
376       X:000040                     DC  %000000000000011011000011
377    


Motorola DSP56300 Assembler  Version 6.3.4   09-02-02  16:00:28  gcam_ccd57.asm  Page 6



378       X:000042                     ORG X:IPCLKS            ; input clamp
379       X:000042                     DC  %000000000000011011010011
380       X:000043                     DC  %000000000000011011000011
381    
382       X:000044                     ORG X:TCLKS             ; read temp monitor
383       X:000044                     DC  %000000000000011011000010
384       X:000045                     DC  %000000000000011011000011
385    
386       X:000048                     ORG X:PCLKS_FT          ; frame transfer P1-P2-P3-P1
387       X:000048                     DC  %000001101100011011000011
388       X:000049                     DC  %000001001000011011000011
389       X:00004A                     DC  %000011011000011011000011
390       X:00004B                     DC  %000010010000011011000011
391       X:00004C                     DC  %000010110100011011000011
392       X:00004D                     DC  %000000100100011011000011
393    
394       X:000050                     ORG X:PCLKS_RD          ; parallel transfer P1-P2-P3-P1
395       X:000050                     DC  %000000000100011011010011
396       X:000051                     DC  %000000001100011011010011
397       X:000052                     DC  %000000001000011011000011
398       X:000053                     DC  %000000011000011011000011
399       X:000054                     DC  %000000010000011011000011
400       X:000055                     DC  %000000000000011011000011
401    
402       X:000058                     ORG X:PCLKS_FL          ; parallel flush P1-P2-P3-P1
403       X:000058                     DC  %000001101101011011000011   ; 01 Nov 07 - RAT
404       X:000059                     DC  %000001001001111111100011
405       X:00005A                     DC  %000011011001111111100011
406       X:00005B                     DC  %000010010001111111100011
407       X:00005C                     DC  %000010110101111111100011
408       X:00005D                     DC  %000000100101011011000011
409    
410       X:000060                     ORG X:INT_L             ; reset and first integration
411       X:000060                     DC  %000000000000001001100011   ; RG ON  FRST ON
412       X:000061                     DC  %000000000000001001000011   ; RG OFF
413       X:000062                     DC  %000000000000001001000001   ; FRST OFF
414       X:000063                     DC  %000000000000001001001001   ; FINT+ ON
415       X:000064                     DC  %000000000000001001000001   ; FINT+ OFF
416    
417       X:000068                     ORG X:INT_H             ; second integration and A to D
418       X:000068                     DC  %000000000000001001000101   ; FINT- ON
419       X:000069                     DC  %000000000000001001000001   ; FINT- OFF
420       X:00006A                     DC  %000000000000001001000000   ; /CONVST ON
421       X:00006B                     DC  %000000000000001001000001   ; /CONVST OFF
422       X:00006C                     DC  %000000000000001001100011   ; FRST ON RG ON
423    
424       X:000070                     ORG X:SCLKS_R           ; serial shift (right) S1-S2-S3-S1
425       X:000070                     DC  %000000000000011011000001
426       X:000071                     DC  %000000000000010010000001
427       X:000072                     DC  %000000000000110110000001
428       X:000073                     DC  %000000000000100100000001
429       X:000074                     DC  %000000000000101101000001
430       X:000075                     DC  %000000000000001001000001
431    


Motorola DSP56300 Assembler  Version 6.3.4   09-02-02  16:00:28  gcam_ccd57.asm  Page 7



432       X:000080                     ORG X:SCLKS_FLR         ; serial flush (right) S1-S2-S3-S1
433       X:000080                     DC  %000000000000011011100011
434       X:000081                     DC  %000000000000010010100011
435       X:000082                     DC  %000000000000110110100011
436       X:000083                     DC  %000000000000100100100011
437       X:000084                     DC  %000000000000101101100011
438       X:000085                     DC  %000000000000001001100011
439    
440       X:000078                     ORG X:SCLKS_L           ; serial shift (left) S1-S3-S2-S1
441       X:000078                     DC  %000000000000101101000001
442       X:000079                     DC  %000000000000100100000001
443       X:00007A                     DC  %000000000000110110000001
444       X:00007B                     DC  %000000000000010010000001
445       X:00007C                     DC  %000000000000011011000001
446       X:00007D                     DC  %000000000000001001000001
447    
448       X:000088                     ORG X:SCLKS_FLL         ; serial flush (left) S1-S3-S2-S1
449       X:000088                     DC  %000000000000101101100011
450       X:000089                     DC  %000000000000100100100011
451       X:00008A                     DC  %000000000000110110100011
452       X:00008B                     DC  %000000000000010010100011
453       X:00008C                     DC  %000000000000011011100011
454       X:00008D                     DC  %000000000000001001100011
455    
456       X:000090                     ORG X:SCLKS_B           ; serial shift (both)
457       X:000090                     DC  %000000000000101011000001
458       X:000091                     DC  %000000000000100010000001
459       X:000092                     DC  %000000000000110110000001
460       X:000093                     DC  %000000000000010100000001
461       X:000094                     DC  %000000000000011101000001
462       X:000095                     DC  %000000000000001001000001
463    
464       X:000098                     ORG X:SCLKS_FLB         ; serial flush (both)
465       X:000098                     DC  %000000000000101011100011
466       X:000099                     DC  %000000000000100010100011
467       X:00009A                     DC  %000000000000110110100011
468       X:00009B                     DC  %000000000000010100100011
469       X:00009C                     DC  %000000000000011101100011
470       X:00009D                     DC  %000000000000001001100011
471    
472       X:0000A0                     ORG X:SCLKS_FF          ; serial flush (fast) DG
473       X:0000A0                     DC  %000000000001011011100011
474       X:0000A1                     DC  %000000000001000000100011
475       X:0000A2                     DC  %000000000000000000100011
476       X:0000A3                     DC  %000000000000011011100011
477       X:0000A4                     DC  %000000000000011011100011   ; dummy code
478       X:0000A5                     DC  %000000000000011011100011   ; dummy code
479                           ENDIF
480    
481    
482                           IF (RDMODE==1)                  ; exp't clocking mode
588                           ENDIF
589    
590    


Motorola DSP56300 Assembler  Version 6.3.4   09-02-02  16:00:28  gcam_ccd57.asm  Page 8



591                        ;*******************************************************************************
592                        ;   GENERAL COMMENTS
593                        ;*******************************************************************************
594                        ; Hardware RESET causes download from serial port (code in EPROM)
595                        ; R0 is a pointer to sequence fragments
596                        ; R1 is a pointer used by send/receive routines
597                        ; R2 is a pointer to the current data location
598                        ; See dspdvr.h for command and opflag definitions
599                        ;*******************************************************************************
600                        ;   INITIALIZE INTERRUPT VECTORS
601                        ;*******************************************************************************
602       P:000000                     ORG     P:$0000
603       P:000000 0C0100              JMP     START
604                        ;*******************************************************************************
605                        ;   MAIN PROGRAM
606                        ;*******************************************************************************
607       P:000100                     ORG     P:START
608       P:000100 0003F8  SET_MODE    ORI     #$3,MR                  ; mask all interrupts
609       P:000101 08F4B6              MOVEP   #$FFFC21,X:AAR3         ; PERIPH $FFF000--$FFFFFF
                   FFFC21
610       P:000103 08F4B8              MOVEP   #$D00909,X:AAR1         ; EEPROM $D00000--$D07FFF 32K
                   D00909
611       P:000105 08F4B9              MOVEP   #$000811,X:AAR0         ; SRAM X $000000--$00FFFF 64K
                   000811
612       P:000107 08F4BB              MOVEP   #WS,X:BCR               ; Set periph wait states
                   073FE1
613       P:000109 0505A0              MOVE    #SEQ-1,M0               ; Set sequencer address modulus
614    
615                        PORTB_SETUP
616       P:00010A 08F484  PORTB_SETUP MOVEP   #>$1,X:PCRB             ; set PB[15..0] GPIO
                   000001
617    
618                        PORTD_SETUP
619       P:00010C 07F42F  PORTD_SETUP MOVEP   #>$0,X:PCRD             ; GPIO PD0=TM PD1=GAIN
                   000000
620       P:00010E 07F42E              MOVEP   #>$3,X:PRRD             ; PD2=/ENRX PD3=/ENTX
                   000003
621       P:000110 07F42D              MOVEP   #>$0,X:PDRD             ; PD4=RXRDY
                   000000
622    
623       P:000112 07F436  SSI_SETUP   MOVEP   #>$032070,X:CRB         ; async, LSB, enable TE RE
                   032070
624       P:000114 07F435              MOVEP   #>$140803,X:CRA         ; 10 Mbps, 16 bit word
                   140803
625       P:000116 07F43F              MOVEP   #>$3F,X:PCRC            ; enable ESSI
                   00003F
626    
627                        PORTE_SETUP
628       P:000118 07F41F  PORTE_SETUP MOVEP   #$0,X:PCRE              ; enable GPIO, disable SCI
                   000000
629       P:00011A 07F41E              MOVEP   #>$1,X:PRRE             ; PE0=SHUTTER
                   000001
630       P:00011C 07F41D              MOVEP   #>$0,X:PDRE             ;
                   000000


Motorola DSP56300 Assembler  Version 6.3.4   09-02-02  16:00:28  gcam_ccd57.asm  Page 9



631    
632       P:00011E 07F40F  SET_TIMER   MOVEP   #$300A10,X:TCSR0        ; Pulse mode, no prescale
                   300A10
633       P:000120 07F40E              MOVEP   #$0,X:TLR0              ; timer reload value
                   000000
634       P:000122 07F00D              MOVEP   X:USEC,X:TCPR0          ; timer compare value
                   000013
635       P:000124 07F40B              MOVEP   #$308A10,X:TCSR1        ; Pulse mode, prescaled
                   308A10
636       P:000126 07F40A              MOVEP   #$0,X:TLR1              ; timer reload value
                   000000
637       P:000128 07F009              MOVEP   X:EXP_TIME,X:TCPR1      ; timer compare value
                   000010
638       P:00012A 07F403              MOVEP   #>$9C3F,X:TPLR          ; timer prescale ($9C3F=1ms 80MHz)
                   009C3F
639    
640       P:00012C 08F4AF  DMA_SETUP   MOVEP   #PIX,X:DSR0             ; set DMA source
                   000300
641       P:00012E 08F4AD              MOVEP   #$0,X:DCO0              ; set DMA counter
                   000000
642       P:000130 0A1680  FIBER       JCLR    #$0,X:LINK,RS485        ; set up optical
                   000136
643       P:000132 08F4AE              MOVEP   #>TXREG,X:DDR0          ; set DMA destination
                   FFFF85
644       P:000134 08F4AC              MOVEP   #>$080255,X:DCR0        ; DMA word xfer, /IRQA, src+1
                   080255
645       P:000136 0A16A0  RS485       JSET    #$0,X:LINK,ENDDP        ; set up RS485
                   00013C
646       P:000138 08F4AE              MOVEP   #>TXD,X:DDR0            ; DMA destination
                   FFFFBC
647       P:00013A 08F4AC              MOVEP   #>$085A51,X:DCR0        ; DMA word xfer, TDE0, src+1
                   085A51
648       P:00013C 000000  ENDDP       NOP                             ;
649    
650       P:00013D 0BF080  INIT_SETUP  JSR     MPPHOLD                 ;
                   0001C3
651       P:00013F 0BF080              JSR     SET_GAIN                ;
                   000335
652       P:000141 0BF080              JSR     SET_DACS                ;
                   0002DA
653       P:000143 0BF080              JSR     SET_SCLKS               ;
                   00033F
654    
655       P:000145 0A1680  WAIT_CMD    JCLR    #$0,X:LINK,WAITB        ; check for cmd ready
                   000149
656       P:000147 01AD84              JCLR    #$4,X:PDRD,ECHO         ; fiber link (single-fiber)
                   000153
657       P:000149 0A16A0  WAITB       JSET    #$0,X:LINK,ENDW         ;
                   00014D
658       P:00014B 01B787              JCLR    #7,X:SSISR,ECHO         ; wire link
                   000153
659       P:00014D 000000  ENDW        NOP                             ;
660    
661       P:00014E 0BF080              JSR     READ16                  ; wait for command word


Motorola DSP56300 Assembler  Version 6.3.4   09-02-02  16:00:28  gcam_ccd57.asm  Page 10



                   000275
662       P:000150 540000              MOVE    A1,X:CMD                ; cmd in X:CMD
663       P:000151 0BF080              JSR     CMD_FIX                 ; interpret command word
                   00036A
664    
665       P:000153 0A0081  ECHO        JCLR    #$1,X:CMD,GET           ; test for DSP_ECHO command
                   00015A
666       P:000155 0BF080              JSR     READ16                  ;
                   000275
667       P:000157 0BF080              JSR     WRITE16                 ;
                   000285
668       P:000159 0A0001              BCLR    #$1,X:CMD               ;
669    
670       P:00015A 0A0082  GET         JCLR    #$2,X:CMD,PUT           ; test for DSP_GET command
                   00015F
671       P:00015C 0BF080              JSR     MEM_SEND                ;
                   0002CD
672       P:00015E 0A0002              BCLR    #$2,X:CMD               ;
673    
674       P:00015F 0A0083  PUT         JCLR    #$3,X:CMD,EXP_START     ; test for DSP_PUT command
                   000164
675       P:000161 0BF080              JSR     MEM_LOAD                ;
                   0002C1
676       P:000163 0A0003              BCLR    #$3,X:CMD               ;
677    
678       P:000164 0A0086  EXP_START   JCLR    #$6,X:CMD,FASTFLUSH     ; test for EXPOSE command
                   000171
679       P:000166 0BF080              JSR     MPPHOLD                 ;
                   0001C3
680       P:000168 62F400              MOVE    #PIX,R2                 ; set data pointer
                   000300
681       P:00016A 07F009              MOVEP   X:EXP_TIME,X:TCPR1      ; timer compare value
                   000010
682       P:00016C 0A012F              BSET    #$F,X:OPFLAGS           ; set exp_in_progress flag
683       P:00016D 0A0006              BCLR    #$6,X:CMD               ;
684    
685       P:00016E 0A0181              JCLR    #$1,X:OPFLAGS,FASTFLUSH ; check for AUTO_FLUSH
                   000171
686       P:000170 0A0024              BSET    #$4,X:CMD               ;
687    
688       P:000171 0A0084  FASTFLUSH   JCLR    #$4,X:CMD,BEAM_ON       ; test for FLUSH command
                   00017A
689       P:000173 0BF080              JSR     FLUSHFRAME              ; fast FLUSH
                   0001EB
690       P:000175 0BF080              JSR     FLUSHFRAME              ; fast FLUSH
                   0001EB
691       P:000177 0BF080              JSR     FLUSHLINE               ; clear serial register
                   0001D0
692       P:000179 0A0004              BCLR    #$4,X:CMD               ;
693    
694       P:00017A 0A0085  BEAM_ON     JCLR    #$5,X:CMD,EXPOSE        ; test for open shutter
                   00017E
695       P:00017C 011D20              BSET    #$0,X:PDRE              ; set SHUTTER
696       P:00017D 0A0005              BCLR    #$5,X:CMD               ;


Motorola DSP56300 Assembler  Version 6.3.4   09-02-02  16:00:28  gcam_ccd57.asm  Page 11



697    
698       P:00017E 0A018F  EXPOSE      JCLR    #$F,X:OPFLAGS,BEAM_OFF  ; check exp_in_progress flag
                   00018B
699    
700       P:000180 0BF080              JSR     MPPHOLD                 ;
                   0001C3
701       P:000182 0BF080              JSR     M_TIMER                 ;
                   00032F
702       P:000184 0A010F              BCLR    #$F,X:OPFLAGS           ; clear exp_in_progress flag
703    
704       P:000185 0A0182  OPT_A       JCLR    #$2,X:OPFLAGS,OPT_B     ; check for AUTO_SHUTTER
                   000188
705       P:000187 0A0027              BSET    #$7,X:CMD               ; prep to close shutter
706       P:000188 0A0184  OPT_B       JCLR    #$4,X:OPFLAGS,BEAM_OFF  ; check for AUTO_READ
                   00018B
707       P:00018A 0A0028              BSET    #$8,X:CMD               ; prep for full readout
708    
709       P:00018B 0A0087  BEAM_OFF    JCLR    #$7,X:CMD,READ_CCD      ; test for shutter close
                   00018F
710       P:00018D 011D00              BCLR    #$0,X:PDRE              ; clear SHUTTER
711       P:00018E 0A0007              BCLR    #$7,X:CMD               ;
712    
713       P:00018F 0A0088  READ_CCD    JCLR    #$8,X:CMD,AUTO_WIPE     ; test for READCCD command
                   0001A5
714       P:000191 0BF080              JSR     FRAME                   ; frame transfer
                   000201
715                        ;           JSR     IPC_CLAMP               ; discharge ac coupling cap
716       P:000193 0BF080              JSR     FLUSHROWS               ; vskip
                   0001E1
717       P:000195 060200              DO      X:NROWS,END_READ        ; read the array
                   0001A2
718       P:000197 0BF080              JSR     FLUSHLINE               ;
                   0001D0
719       P:000199 0BF080              JSR     PARALLEL                ;
                   0001F5
720       P:00019B 0BF080              JSR     FLUSHPIX                ; hskip
                   0001D7
721       P:00019D 0A0120              BSET    #$0,X:OPFLAGS           ; set first pixel flag
722       P:00019E 0BF080              JSR     READPIX                 ;
                   000213
723       P:0001A0 0A0100              BCLR    #$0,X:OPFLAGS           ; clear first pixel flag
724       P:0001A1 0BF080              JSR     READLINE                ;
                   000211
725       P:0001A3 000000  END_READ    NOP                             ;
726       P:0001A4 0A0008              BCLR    #$8,X:CMD               ;
727    
728       P:0001A5 0A0089  AUTO_WIPE   JCLR    #$9,X:CMD,HH_DACS       ; test for AUTOWIPE command
                   0001A7
729                        ;           BSET    #$E,X:OPFLAGS           ;
730                        ;           BSET    #$5,X:OPFLAGS           ;
731                        ;           JSR     FL_CLOCKS               ; flush one parallel row
732                        ;           JSR     READLINE                ;
733                        ;           BCLR    #$9,X:CMD               ;
734    


Motorola DSP56300 Assembler  Version 6.3.4   09-02-02  16:00:28  gcam_ccd57.asm  Page 12



735       P:0001A7 0A008A  HH_DACS     JCLR    #$A,X:CMD,HH_TEMP       ; test for HH_SYNC command
                   0001AC
736       P:0001A9 0BF080              JSR     SET_DACS                ;
                   0002DA
737       P:0001AB 0A000A              BCLR    #$A,X:CMD               ;
738    
739       P:0001AC 0A008B  HH_TEMP     JCLR    #$B,X:CMD,HH_TEC        ; test for HH_TEMP command
                   0001B1
740       P:0001AE 0BF080              JSR     TEMP_READ               ; perform housekeeping chores
                   0002F7
741       P:0001B0 0A000B              BCLR    #$B,X:CMD               ;
742    
743       P:0001B1 0A008C  HH_TEC      JCLR    #$C,X:CMD,HH_OTHER      ; test for HH_TEC command
                   0001B6
744       P:0001B3 0BF080              JSR     TEMP_SET                ; set the TEC value
                   00031B
745       P:0001B5 0A000C              BCLR    #$C,X:CMD               ;
746    
747       P:0001B6 0A008D  HH_OTHER    JCLR    #$D,X:CMD,END_CODE      ; test for HH_OTHER command
                   0001BF
748       P:0001B8 0BF080              JSR     SET_GAIN                ;
                   000335
749       P:0001BA 0BF080              JSR     SET_SCLKS               ;
                   00033F
750       P:0001BC 0BF080              JSR     SET_USEC                ;
                   00033C
751       P:0001BE 0A000D              BCLR    #$D,X:CMD               ;
752    
753       P:0001BF 0A0185  END_CODE    JCLR    #$5,X:OPFLAGS,WAIT_CMD  ; check for AUTO_WIPE
                   000145
754       P:0001C1 0A0029              BSET    #$9,X:CMD               ;
755       P:0001C2 0C0145              JMP     WAIT_CMD                ; Get next command
756    
757                        ;*****************************************************************************
758                        ;   HOLD (MPP MODE)
759                        ;*****************************************************************************
760       P:0001C3 07B080  MPPHOLD     MOVEP   X:MPP,Y:<<SEQREG        ;
                   000040
761       P:0001C5 00000C              RTS                             ;
762    
763                        ;*****************************************************************************
764                        ;   INPUT CLAMP
765                        ;*****************************************************************************
766       P:0001C6 07B080  IPC_CLAMP   MOVEP   X:IPCLKS,Y:<<SEQREG     ;
                   000042
767       P:0001C8 44F400              MOVE    #>HOLD_IPC,X0           ;
                   001F40
768       P:0001CA 06C420              REP     X0                      ; $1F4O=100 us
769       P:0001CB 000000              NOP                             ;
770       P:0001CC 07B080              MOVEP   X:(IPCLKS+1),Y:<<SEQREG ;
                   000043
771       P:0001CE 000000              NOP                             ;
772       P:0001CF 00000C              RTS                             ;
773    


Motorola DSP56300 Assembler  Version 6.3.4   09-02-02  16:00:28  gcam_ccd57.asm  Page 13



774                        ;*****************************************************************************
775                        ;   FLUSHLINE  (FAST FLUSH)
776                        ;*****************************************************************************
777       P:0001D0 30A000  FLUSHLINE   MOVE    #SCLKS_FF,R0            ; initialize pointer
778       P:0001D1 060680              DO      #SEQ,ENDFF              ;
                   0001D5
779       P:0001D3 079880              MOVEP   X:(R0)+,Y:<<SEQREG      ;
780       P:0001D4 0620A0              REP     #HOLD_FF                ;
781       P:0001D5 000000              NOP                             ;
782       P:0001D6 00000C  ENDFF       RTS                             ;
783    
784                        ;*****************************************************************************
785                        ;   FLUSHPIX (HSKIP)
786                        ;*****************************************************************************
787       P:0001D7 060B00  FLUSHPIX    DO      X:HSKIP,ENDFP           ;
                   0001DF
788       P:0001D9 60B100              MOVE    X:SCLKS_FL,R0           ; initialize pointer
789       P:0001DA 060680              DO      #SEQ,ENDHCLK            ;
                   0001DE
790       P:0001DC 079880              MOVEP   X:(R0)+,Y:<<SEQREG      ;
791       P:0001DD 0605A0              REP     #HOLD_S                 ;
792       P:0001DE 000000              NOP                             ;
793       P:0001DF 000000  ENDHCLK     NOP                             ;
794       P:0001E0 00000C  ENDFP       RTS                             ;
795    
796                        ;*****************************************************************************
797                        ;   FLUSHROWS (VSKIP)
798                        ;*****************************************************************************
799       P:0001E1 060A00  FLUSHROWS   DO      X:VSKIP,ENDVSKIP        ;
                   0001E9
800       P:0001E3 305000              MOVE    #PCLKS_RD,R0            ; initialize pointer
801       P:0001E4 060680              DO      #SEQ,ENDVCLK            ;
                   0001E8
802       P:0001E6 079880              MOVEP   X:(R0)+,Y:<<SEQREG      ;
803       P:0001E7 067CA0              REP     #HOLD_FL                ;
804       P:0001E8 000000              NOP                             ;
805       P:0001E9 000000  ENDVCLK     NOP                             ;
806       P:0001EA 00000C  ENDVSKIP    RTS                             ;
807    
808                        ;*****************************************************************************
809                        ;   FLUSHFRAME
810                        ;*****************************************************************************
811       P:0001EB 060400  FLUSHFRAME  DO      X:NFT,ENDFLFR           ;
                   0001F3
812       P:0001ED 305800  FL_CLOCKS   MOVE    #PCLKS_FL,R0            ; initialize pointer
813       P:0001EE 060680              DO      #SEQ,ENDFLCLK           ;
                   0001F2
814       P:0001F0 079880              MOVEP   X:(R0)+,Y:<<SEQREG      ;
815       P:0001F1 067CA0              REP     #HOLD_FL                ;
816       P:0001F2 000000              NOP                             ;
817       P:0001F3 000000  ENDFLCLK    NOP                             ;
818       P:0001F4 00000C  ENDFLFR     RTS                             ;
819    
820                        ;*****************************************************************************


Motorola DSP56300 Assembler  Version 6.3.4   09-02-02  16:00:28  gcam_ccd57.asm  Page 14



821                        ;   PARALLEL TRANSFER (READOUT)
822                        ;*****************************************************************************
823       P:0001F5 060800  PARALLEL    DO      X:VBIN,ENDPT            ;
                   0001FF
824       P:0001F7 305000  P_CLOCKS    MOVE    #PCLKS_RD,R0            ; initialize pointer
825       P:0001F8 060680              DO      #SEQ,ENDPCLK            ;
                   0001FE
826       P:0001FA 079880              MOVEP   X:(R0)+,Y:<<SEQREG      ;
827       P:0001FB 44F400              MOVE    #>HOLD_P,X0             ;
                   00020A
828       P:0001FD 06C420              REP     X0                      ; $317=10us per phase
829       P:0001FE 000000              NOP                             ;
830       P:0001FF 000000  ENDPCLK     NOP                             ;
831       P:000200 00000C  ENDPT       RTS                             ;
832    
833                        ;*****************************************************************************
834                        ;   PARALLEL TRANSFER (FRAME TRANSFER)
835                        ;*****************************************************************************
836       P:000201 07B080  FRAME       MOVEP   X:(PCLKS_FT),Y:<<SEQREG ; 100 us CCD47 pause
                   000048
837       P:000203 44F400              MOVE    #>$1F40,X0              ;
                   001F40
838       P:000205 06C420              REP     X0                      ; $1F40=100 usec
839       P:000206 000000              NOP                             ;
840       P:000207 060400              DO      X:NFT,ENDFT             ;
                   00020F
841       P:000209 304800  FT_CLOCKS   MOVE    #PCLKS_FT,R0            ; initialize seq pointer
842       P:00020A 060680              DO      #SEQ,ENDFTCLK           ;
                   00020E
843       P:00020C 079880              MOVEP   X:(R0)+,Y:<<SEQREG      ;
844       P:00020D 067CA0              REP     #HOLD_FT                ;
845       P:00020E 000000              NOP                             ;
846       P:00020F 000000  ENDFTCLK    NOP                             ;
847       P:000210 00000C  ENDFT       RTS                             ;
848    
849                        ;*****************************************************************************
850                        ;   READLINE SUBROUTINE
851                        ;*****************************************************************************
852       P:000211 060300  READLINE    DO      X:NCOLS,ENDRL           ;
                   000273
853       P:000213 07B080  READPIX     MOVEP   X:(INT_L),Y:<<SEQREG    ; FRST=ON RG=ON
                   000060
854                                    DUP     HOLD_RG                 ; macro
855  m                                 NOP                             ;
856  m                                 ENDM                            ; end macro
863       P:00021B 07B080              MOVEP   X:(INT_L+1),Y:<<SEQREG  ; RG=OFF
                   000061
864       P:00021D 07B080              MOVEP   X:(INT_L+2),Y:<<SEQREG  ; FRST=OFF
                   000062
865       P:00021F 060FA0              REP     #HOLD_SIG               ; preamp settling time
866                        ;           REP     #$F                     ; preamp settling
867       P:000220 000000              NOP                             ;
868       P:000221 07B080  INT1        MOVEP   X:(INT_L+3),Y:<<SEQREG  ; FINT+=ON
                   000063


Motorola DSP56300 Assembler  Version 6.3.4   09-02-02  16:00:28  gcam_ccd57.asm  Page 15



869       P:000223 449300  SLEEP1      MOVE    X:USEC,X0               ; sleep USEC * 12.5ns
870       P:000224 06C420              REP     X0                      ;
871       P:000225 000000              NOP                             ;
872       P:000226 07B080              MOVEP   X:(INT_L+4),Y:<<SEQREG  ; FINT+=OFF
                   000064
873       P:000228 60B000  SERIAL      MOVE    X:SCLKS,R0              ; serial transfer
874       P:000229 060900              DO      X:HBIN,ENDSCLK          ;
                   00024E
875                        S_CLOCKS    DUP     SEQ                     ;    macro
876  m                                 MOVEP   X:(R0)+,Y:<<SEQREG      ;
877  m                                 DUP     HOLD_S                  ;    macro
878  m                                 NOP                             ;
879  m                                 ENDM                            ;
880  m                                 ENDM                            ;
935       P:00024F 060FA0  ENDSCLK     REP     #HOLD_SIG               ; preamp settling time
936       P:000250 000000              NOP                             ; (adjust with o'scope)
937       P:000251 08F4BB  GET_DATA    MOVEP   #WS5,X:BCR              ;
                   07BFE1
938       P:000253 000000              NOP                             ;
939       P:000254 000000              NOP                             ;
940       P:000255 044E21              MOVEP   Y:<<ADC_A,A             ; read ADC
941       P:000256 044F22              MOVEP   Y:<<ADC_B,B             ; read ADC
942       P:000257 08F4BB              MOVEP   #WS,X:BCR               ;
                   073FE1
943       P:000259 000000              NOP                             ;
944       P:00025A 07B080  INT2        MOVEP   X:(INT_H),Y:<<SEQREG    ; FINT-=ON
                   000068
945       P:00025C 449300  SLEEP2      MOVE    X:USEC,X0               ; sleep USEC * 20ns
946       P:00025D 06C420              REP     X0                      ;
947       P:00025E 000000              NOP                             ;
948       P:00025F 07B080              MOVEP   X:(INT_H+1),Y:<<SEQREG  ; FINT-=OFF
                   000069
949                            IF (SYS==1)
954                            ENDIF
955       P:000261 5C7000              MOVE    A1,Y:(PIX)              ;
                   000300
956       P:000263 5D7000              MOVE    B1,Y:(PIX+1)            ;
                   000301
957       P:000265 060FA0              REP     #HOLD_ADC               ; settling time
958       P:000266 000000              NOP                             ; (adjust for best noise)
959       P:000267 07B080  CONVST      MOVEP   X:(INT_H+2),Y:<<SEQREG  ; /CONVST=ON
                   00006A
960       P:000269 08DD2F              MOVEP   N5,X:DSR0               ; set DMA source
961       P:00026A 000000              NOP                             ;
962       P:00026B 000000              NOP                             ;
963       P:00026C 07B080              MOVEP   X:(INT_H+3),Y:<<SEQREG  ; /CONVST=OFF MIN 40 NS
                   00006B
964       P:00026E 07B080              MOVEP   X:(INT_H+4),Y:<<SEQREG  ; FRST=ON
                   00006C
965       P:000270 0A01A0              JSET    #$0,X:OPFLAGS,ENDCHK    ; check for first pixel
                   000273
966       P:000272 0AAC37              BSET    #$17,X:DCR0             ; enable DMA
967       P:000273 000000  ENDCHK      NOP                             ;
968       P:000274 00000C  ENDRL       RTS                             ;


Motorola DSP56300 Assembler  Version 6.3.4   09-02-02  16:00:28  gcam_ccd57.asm  Page 16



969    
970                        ;*******************************************************************************
971                        ;   READ AND WRITE 16-BIT AND 24-BIT DATA
972                        ;*******************************************************************************
973       P:000275 0A1680  READ16      JCLR    #$0,X:LINK,RD16B        ; check RS485 or fiber
                   00027D
974       P:000277 01AD84              JCLR    #$4,X:PDRD,*            ; wait for data in RXREG
                   000277
975       P:000279 5EF000              MOVE    Y:RXREG,A               ; bits 15..0
                   FFFF86
976       P:00027B 0140C6              AND     #>$FFFF,A               ;
                   00FFFF
977       P:00027D 0A16A0  RD16B       JSET    #$0,X:LINK,ENDRD16      ; check RS485 or fiber
                   000284
978       P:00027F 01B787              JCLR    #7,X:SSISR,*            ; wait for RDRF to go high
                   00027F
979       P:000281 54F000              MOVE    X:RXD,A1                ; read from ESSI
                   FFFFB8
980       P:000283 000000              NOP                             ;
981       P:000284 00000C  ENDRD16     RTS                             ; 16-bit word in A1
982    
983       P:000285 0A1680  WRITE16     JCLR    #$0,X:LINK,WR16B        ; check RS485 or fiber
                   000289
984       P:000287 5C7000              MOVE    A1,Y:TXREG              ; write bits 15..0
                   FFFF85
985       P:000289 0A16A0  WR16B       JSET    #$0,X:LINK,ENDWR16      ;
                   00028F
986       P:00028B 01B786              JCLR    #6,X:SSISR,*            ; wait for TDE
                   00028B
987       P:00028D 547000              MOVE    A1,X:TXD                ;
                   FFFFBC
988       P:00028F 00000C  ENDWR16     RTS                             ;
989    
990       P:000290 0A1680  READ24      JCLR    #$0,X:LINK,RD24B        ; check RS485 or fiber
                   00029E
991       P:000292 01AD84              JCLR    #$4,X:PDRD,*            ; wait for data in RXREG
                   000292
992       P:000294 5EF000              MOVE    Y:RXREG,A               ; bits 15..0
                   FFFF86
993       P:000296 0140C6              AND     #>$FFFF,A               ;
                   00FFFF
994       P:000298 0C1C20              ASR     #$10,A,A                ; shift right 16 bits
995       P:000299 01AD84              JCLR    #$4,X:PDRD,*            ; wait for data in RXREG
                   000299
996       P:00029B 5CF000              MOVE    Y:RXREG,A1              ; bits 15..0
                   FFFF86
997       P:00029D 0C1D20              ASL     #$10,A,A                ; shift left 16 bits
998       P:00029E 0A16A0  RD24B       JSET    #$0,X:LINK,ENDRD24      ;
                   0002AA
999       P:0002A0 01B787              JCLR    #7,X:SSISR,*            ; wait for RDRF to go high
                   0002A0
1000      P:0002A2 56F000              MOVE    X:RXD,A                 ; read from ESSI
                   FFFFB8
1001      P:0002A4 0C1C20              ASR     #$10,A,A                ; shift right 16 bits


Motorola DSP56300 Assembler  Version 6.3.4   09-02-02  16:00:28  gcam_ccd57.asm  Page 17



1002      P:0002A5 01B787              JCLR    #7,X:SSISR,*            ; wait for RDRF to go high
                   0002A5
1003      P:0002A7 54F000              MOVE    X:RXD,A1                ;
                   FFFFB8
1004      P:0002A9 0C1D20              ASL     #$10,A,A                ; shift left 16 bits
1005      P:0002AA 00000C  ENDRD24     RTS                             ; 24-bit word in A1
1006   
1007      P:0002AB 0A1680  WRITE24     JCLR    #$0,X:LINK,WR24B        ; check RS485 or fiber
                   0002B4
1008      P:0002AD 5C7000              MOVE    A1,Y:TXREG              ; send bits 15..0
                   FFFF85
1009      P:0002AF 0C1C20              ASR     #$10,A,A                ; right shift 16 bits
1010      P:0002B0 0610A0              REP     #$10                    ; wait for data sent
1011      P:0002B1 000000              NOP                             ;
1012      P:0002B2 5C7000              MOVE    A1,Y:TXREG              ; send bits 23..16
                   FFFF85
1013      P:0002B4 0A16A0  WR24B       JSET    #$0,X:LINK,ENDWR24      ;
                   0002C0
1014      P:0002B6 01B786              JCLR    #6,X:SSISR,*            ; wait for TDE
                   0002B6
1015      P:0002B8 547000              MOVE    A1,X:TXD                ; send bits 15..0
                   FFFFBC
1016      P:0002BA 0C1C20              ASR     #$10,A,A                ; right shift 16 bits
1017      P:0002BB 000000              NOP                             ; wait for flag update
1018      P:0002BC 01B786              JCLR    #6,X:SSISR,*            ; wait for TDE
                   0002BC
1019      P:0002BE 547000              MOVE    A1,X:TXD                ; send bits 23..16
                   FFFFBC
1020      P:0002C0 00000C  ENDWR24     RTS                             ;
1021   
1022                       ;*****************************************************************************
1023                       ;   LOAD NEW DATA VIA SSI PORT
1024                       ;*****************************************************************************
1025      P:0002C1 0D0290  MEM_LOAD    JSR     READ24                  ; get memspace/address
1026      P:0002C2 219100              MOVE    A1,R1                   ; load address into R1
1027      P:0002C3 218400              MOVE    A1,X0                   ; store memspace code
1028      P:0002C4 0D0290              JSR     READ24                  ; get data
1029      P:0002C5 0AD157              BCLR    #$17,R1                 ; clear memspace bit
1030      P:0002C6 0AC437  X_LOAD      JSET    #$17,X0,Y_LOAD          ;
                   0002C9
1031      P:0002C8 546100              MOVE    A1,X:(R1)               ; load x memory
1032      P:0002C9 0AC417  Y_LOAD      JCLR    #$17,X0,END_LOAD        ;
                   0002CC
1033      P:0002CB 5C6100              MOVE    A1,Y:(R1)               ; load y memory
1034      P:0002CC 00000C  END_LOAD    RTS                             ;
1035   
1036                       ;*****************************************************************************
1037                       ;   SEND MEMORY CONTENTS VIA SSI PORT
1038                       ;*****************************************************************************
1039      P:0002CD 0D0290  MEM_SEND    JSR     READ24                  ; get memspace/address
1040      P:0002CE 219100              MOVE    A1,R1                   ; load address into R1
1041      P:0002CF 218400              MOVE    A1,X0                   ; save memspace code
1042      P:0002D0 0AD157              BCLR    #$17,R1                 ; clear memspace bit
1043      P:0002D1 0AC437  X_SEND      JSET    #$17,X0,Y_SEND          ;


Motorola DSP56300 Assembler  Version 6.3.4   09-02-02  16:00:28  gcam_ccd57.asm  Page 18



                   0002D4
1044      P:0002D3 54E100              MOVE    X:(R1),A1               ; send x memory
1045      P:0002D4 0AC417  Y_SEND      JCLR    #$17,X0,WRITE24         ;
                   0002AB
1046      P:0002D6 5CE100              MOVE    Y:(R1),A1               ; send y memory
1047      P:0002D7 0D02AB  SEND24      JSR     WRITE24                 ;
1048      P:0002D8 000000              NOP                             ;
1049      P:0002D9 00000C              RTS                             ;
1050   
1051                       ;*****************************************************************************
1052                       ;   SET DAC VOLTAGES  DEFAULTS:  OD=20V  RD=8V  OG=ABG=-6V
1053                       ;   PCLKS=+3V -9V SCLKS=+2V -8V RG=+3V -9V
1054                       ;*****************************************************************************
1055      P:0002DA 0BF080  SET_DACS    JSR     SET_VBIAS               ;
                   0002DF
1056      P:0002DC 0BF080              JSR     SET_VCLKS               ;
                   0002EB
1057      P:0002DE 00000C              RTS                             ;
1058   
1059      P:0002DF 08F4BB  SET_VBIAS   MOVEP   #WS5,X:BCR              ; add wait states
                   07BFE1
1060      P:0002E1 331800              MOVE    #VBIAS,R3               ; bias voltages
1061      P:0002E2 64F400              MOVE    #SIG_AB,R4              ; bias DAC registers
                   FFFF88
1062      P:0002E4 060880              DO      #$8,ENDSETB             ; set bias voltages
                   0002E7
1063      P:0002E6 44DB00              MOVE    X:(R3)+,X0              ;
1064      P:0002E7 4C5C00              MOVE    X0,Y:(R4)+              ;
1065      P:0002E8 08F4BB  ENDSETB     MOVEP   #WS,X:BCR               ;
                   073FE1
1066      P:0002EA 00000C              RTS                             ;
1067   
1068      P:0002EB 08F4BB  SET_VCLKS   MOVEP   #WS5,X:BCR              ; add wait states
                   07BFE1
1069      P:0002ED 332000              MOVE    #VCLK,R3                ; clock voltages
1070      P:0002EE 64F400              MOVE    #CLK_AB,R4              ; clock DAC registers
                   FFFF90
1071      P:0002F0 061080              DO      #$10,ENDSETV            ; set clock voltages
                   0002F3
1072      P:0002F2 44DB00              MOVE    X:(R3)+,X0              ;
1073      P:0002F3 4C5C00              MOVE    X0,Y:(R4)+              ;
1074      P:0002F4 08F4BB  ENDSETV     MOVEP   #WS,X:BCR               ; re-set wait states
                   073FE1
1075      P:0002F6 00000C              RTS
1076   
1077                       ;*****************************************************************************
1078                       ;   TEMP MONITOR ADC START AND CONVERT
1079                       ;*****************************************************************************
1080      P:0002F7 012D20  TEMP_READ   BSET    #$0,X:PDRD              ; turn on temp sensor
1081   
1082                       ; -------------------------------------------------------------------
1083                       ; test  - 30 oct 07 RAT
1084                       ; set OFFSET_R to zero during idle periods.
1085   


Motorola DSP56300 Assembler  Version 6.3.4   09-02-02  16:00:28  gcam_ccd57.asm  Page 19



1086      P:0002F8 08F4BB              MOVEP   #WS5,X:BCR              ; add wait states
                   07BFE1
1087      P:0002FA 44F400              MOVE    #DZ+0200,X0             ; temperature bias voltage (OFFSET_R is
 first)
                   0010C8
1088      P:0002FC 64F400              MOVE    #SIG_AB,R4              ; bias DAC registers
                   FFFF88
1089      P:0002FE 000000          NOP                   ; -RAT 5 sep 08
1090      P:0002FF 000000          NOP                   ; -RAT 5 sep 08
1091      P:000300 4C6400              MOVE    X0,Y:(R4)               ;
1092      P:000301 08F4BB              MOVEP   #WS,X:BCR               ; re-set wait states
                   073FE1
1093   
1094                       ;--------------------------------------------------------------------
1095   
1096      P:000303 07F409              MOVEP   #$20,X:TCPR1            ; set timer compare value
                   000020
1097      P:000305 0BF080              JSR     M_TIMER                 ; wait for output to settle
                   00032F
1098   
1099      P:000307 08F4BB              MOVEP   #WS3,X:BCR              ; set wait states for ADC
                   077FE1
1100      P:000309 07B080              MOVEP   X:TCLKS,Y:<<SEQREG      ; assert /CONVST
                   000044
1101      P:00030B 0604A0              REP     #$4                     ;
1102      P:00030C 000000              NOP                             ;
1103      P:00030D 07B080              MOVEP   X:(TCLKS+1),Y:<<SEQREG  ; deassert /CONVST and wait
                   000045
1104      P:00030F 0650A0              REP     #$50                    ;
1105      P:000310 000000              NOP                             ;
1106   
1107      P:000311 044C22              MOVEP   Y:<<ADC_B,A1            ; read ADC2
1108      P:000312 45F400              MOVE    #>$3FFF,X1              ; prepare 14-bit mask
                   003FFF
1109      P:000314 200066              AND     X1,A1                   ; get 14 LSBs
1110      P:000315 012D00              BCLR    #$0,X:PDRD              ; turn off temp sensor
1111      P:000316 0BCC4D              BCHG    #$D,A1                  ; 2complement to binary
1112      P:000317 08F4BB              MOVEP   #WS,X:BCR               ; re-set wait states
                   073FE1
1113      P:000319 541100              MOVE    A1,X:TEMP               ;
1114      P:00031A 00000C              RTS                             ;
1115   
1116      P:00031B 08F4BB  TEMP_SET    MOVEP   #WS5,X:BCR              ; add wait states
                   07BFE1
1117      P:00031D 000000              NOP                             ;
1118   
1119                       ; -------------------------------------------------------------------
1120                       ; test  - 23 oct 07 RAT
1121                       ; restore OFFSET_R value during imaging
1122   
1123      P:00031E 331800              MOVE    #VBIAS,R3               ; bias voltages (OFFSET_R is first)
1124      P:00031F 64F400              MOVE    #SIG_AB,R4              ; bias DAC registers
                   FFFF88
1125      P:000321 000000          NOP                 ; -RAT 5 sep 08


Motorola DSP56300 Assembler  Version 6.3.4   09-02-02  16:00:28  gcam_ccd57.asm  Page 20



1126      P:000322 44E300              MOVE    X:(R3),X0               ;
1127      P:000323 4C6400              MOVE    X0,Y:(R4)               ;
1128   
1129                       ;--------------------------------------------------------------------
1130   
1131      P:000324 07B08A              MOVEP   X:TEC,Y:<<TEC_REG       ; set TEC DAC
                   00001A
1132      P:000326 08F4BB              MOVEP   #WS,X:BCR               ; re-set wait states
                   073FE1
1133      P:000328 00000C              RTS
1134   
1135                       ;*****************************************************************************
1136                       ;   MILLISECOND AND MICROSECOND TIMER MODULE
1137                       ;*****************************************************************************
1138      P:000329 010F20  U_TIMER     BSET    #$0,X:TCSR0             ; start timer
1139      P:00032A 014F20              BTST    #$0,X:TCSR0             ; delay for flag update
1140   
1141      P:00032B 018F95              JCLR    #$15,X:TCSR0,*          ; wait for TCF flag
                   00032B
1142      P:00032D 010F00              BCLR    #$0,X:TCSR0             ; stop timer, clear flag
1143      P:00032E 00000C              RTS                             ; flags update during RTS
1144   
1145      P:00032F 010B20  M_TIMER     BSET    #$0,X:TCSR1             ; start timer
1146      P:000330 014F20              BTST    #$0,X:TCSR0             ; delay for flag update
1147   
1148      P:000331 018B95              JCLR    #$15,X:TCSR1,*          ; wait for TCF flag
                   000331
1149      P:000333 010B00              BCLR    #$0,X:TCSR1             ; stop timer, clear flag
1150      P:000334 00000C              RTS                             ; flags update during RTS
1151   
1152                       ;*****************************************************************************
1153                       ;   SIGNAL-PROCESSING GAIN MODULE
1154                       ;*****************************************************************************
1155      P:000335 0A12A0  SET_GAIN    JSET    #$0,X:GAIN,HI_GAIN      ;
                   000338
1156      P:000337 012D01              BCLR    #$1,X:PDRD              ; set gain=0
1157      P:000338 0A1280  HI_GAIN     JCLR    #$0,X:GAIN,END_GAIN     ;
                   00033B
1158      P:00033A 012D21              BSET    #$1,X:PDRD              ; set gain=1
1159      P:00033B 00000C  END_GAIN    RTS                             ;
1160   
1161                       ;*****************************************************************************
1162                       ;   SIGNAL-PROCESSING DUAL-SLOPE TIME MODULE
1163                       ;*****************************************************************************
1164      P:00033C 07F00D  SET_USEC    MOVEP   X:USEC,X:TCPR0          ; timer compare value
                   000013
1165      P:00033E 00000C  END_USEC    RTS                             ;
1166   
1167                       ;*****************************************************************************
1168                       ;   SELECT SERIAL CLOCK SEQUENCE (IE OUTPUT AMPLIFIER)
1169                       ;*****************************************************************************
1170      P:00033F 569400  SET_SCLKS   MOVE    X:OPCH,A                ; 0x1=right 0x2=left
1171      P:000340 44F400  RIGHT_AMP   MOVE    #>$1,X0                 ; 0x3=both  0x4=all
                   000001


Motorola DSP56300 Assembler  Version 6.3.4   09-02-02  16:00:28  gcam_ccd57.asm  Page 21



1172      P:000342 200045              CMP     X0,A                    ;
1173      P:000343 0AF0A2              JNE     LEFT_AMP                ;
                   00034D
1174      P:000345 46F400              MOVE    #>SCLKS_R,Y0            ; serial clock sequences
                   000070
1175      P:000347 47F400              MOVE    #>SCLKS_FLR,Y1          ; serial flush sequences
                   000080
1176      P:000349 75F400              MOVE    #PIX+1,N5               ; pointer to start of data
                   000301
1177      P:00034B 08F4AD              MOVEP   #>$0,X:DCO0             ; DMA counter
                   000000
1178      P:00034D 44F400  LEFT_AMP    MOVE    #>$2,X0                 ;
                   000002
1179      P:00034F 200045              CMP     X0,A                    ;
1180      P:000350 0AF0A2              JNE     BOTH_AMP                ;
                   00035A
1181      P:000352 46F400              MOVE    #>SCLKS_L,Y0            ;
                   000078
1182      P:000354 47F400              MOVE    #>SCLKS_FLL,Y1          ;
                   000088
1183      P:000356 75F400              MOVE    #PIX,N5                 ;
                   000300
1184      P:000358 08F4AD              MOVEP   #>$0,X:DCO0             ;
                   000000
1185      P:00035A 44F400  BOTH_AMP    MOVE    #>$3,X0                 ;
                   000003
1186      P:00035C 200045              CMP     X0,A                    ;
1187      P:00035D 0AF0A2              JNE     END_AMP                 ;
                   000367
1188      P:00035F 46F400              MOVE    #>SCLKS_B,Y0            ;
                   000090
1189      P:000361 47F400              MOVE    #>SCLKS_FLB,Y1          ;
                   000098
1190      P:000363 75F400              MOVE    #PIX,N5                 ;
                   000300
1191      P:000365 08F4AD              MOVEP   #>$1,X:DCO0             ;
                   000001
1192      P:000367 463000  END_AMP     MOVE    Y0,X:SCLKS              ;
1193      P:000368 473100              MOVE    Y1,X:SCLKS_FL           ;
1194      P:000369 00000C              RTS                             ;
1195   
1196                       ;*****************************************************************************
1197                       ;   CMD.ASM -- ROUTINE TO INTERPRET AN 8-BIT COMMAND + COMPLEMENT
1198                       ;*****************************************************************************
1199                       ; Each command word is sent as two bytes -- the LSB has the command
1200                       ; and the MSB has the complement.
1201   
1202      P:00036A 568000  CMD_FIX     MOVE    X:CMD,A                 ; extract cmd[7..0]
1203      P:00036B 0140C6              AND     #>$FF,A                 ; and put in X1
                   0000FF
1204      P:00036D 218500              MOVE    A1,X1                   ;
1205      P:00036E 568000              MOVE    X:CMD,A                 ; extract cmd[15..8]
1206      P:00036F 0C1ED0              LSR     #$8,A                   ; complement
1207      P:000370 57F417              NOT     A   #>$1,B              ; and put in A1


Motorola DSP56300 Assembler  Version 6.3.4   09-02-02  16:00:28  gcam_ccd57.asm  Page 22



                   000001
1208      P:000372 0140C6              AND     #>$FF,A                 ;
                   0000FF
1209      P:000374 0C1E5D              ASL     X1,B,B                  ;
1210      P:000375 200065              CMP     X1,A                    ; compare X1 and A1
1211      P:000376 0AF0AA              JEQ     CMD_OK                  ;
                   00037A
1212      P:000378 20001B  CMD_NG      CLR     B                       ; cmd word no good
1213      P:000379 000000              NOP                             ;
1214      P:00037A 550000  CMD_OK      MOVE    B1,X:CMD                ; cmd word OK
1215      P:00037B 000000              NOP                             ;
1216      P:00037C 00000C  END_CMD     RTS                             ;
1217   
1218                                   END

0    Errors
0    Warnings


