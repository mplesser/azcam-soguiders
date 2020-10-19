
Motorola DSP56300 Assembler  Version 6.3.4   07-12-14  11:55:19  gcam_512ft.asm  Page 1



1                          ;*****************************************************************************
2                          ;   GCAM.ASM -- DSP-BASED CCD CONTROLLER PROGRAM
3                          ;*****************************************************************************
4                              PAGE    110,60,1,1
5                              TABS    4
6                          ;*****************************************************************************
7                          ;   Code modified for the 512FT 15 March 2007 - R. Tucker
8                          ;   Last change 23Oct07 - RAT - flush (MPL timing)
9                          ;*****************************************************************************
10     
11                         ;
12                         ;*****************************************************************************
13                         ;   DEFINITIONS & POINTERS
14                         ;*****************************************************************************
15        000100           START       EQU     $000100             ; program start location
16        000006           SEQ         EQU     $000006             ; seq fragment length
17        001000           DZ          EQU     $001000             ; DAC zero volt offset
18     
19        073FE1           WS          EQU     $073FE1             ; periph wait states
20        073FE1           WS1         EQU     $073FE1             ; 1 PERIPH 1 SRAM 31 EPROM
21        077FE1           WS3         EQU     $077FE1             ; 3 PERIPH 1 SRAM 31 EPROM
22        07BFE1           WS5         EQU     $07BFE1             ; 5 PERIPH 1 SRAM 31 EPROM
23     
24                         ;*****************************************************************************
25                         ;   COMPILE-TIME OPTIONS
26                         ;*****************************************************************************
27     
28        000001           VERSION         EQU     $1              ;
29        000000           RDMODE          EQU     $0              ;
30        00020A           HOLD_P          EQU     $020A           ; P clock timing $20A=40us
31        00007C           HOLD_FT         EQU     $007C           ; FT clock timing $7C=10us xfer
32        00007C           HOLD_FL         EQU     $007C           ; FL clock timimg
33        000005           HOLD_S          EQU     $0005           ; S clock timing, $0005
34        000006           HOLD_RG         EQU     $0006           ; RG timing, $0006
35        001F40           HOLD_PL         EQU     $1F40           ; pre-line settling (1F40=100us)
36        000020           HOLD_FF         EQU     $0020           ; FF clock timimg
37        001F40           HOLD_IPC        EQU     $1F40           ; IPC clock timing ($1F40=100us)
38        00000F           HOLD_SIG        EQU     $000F           ; preamp settling time
39        00000F           HOLD_ADC        EQU     $000F           ; pre-sample settling (was F)
40        000213           INIT_NROWS      EQU     $213            ; $200=(512)
41        000238           INIT_NCOLS      EQU     $238            ; $204=(512)+4
42        000200           INIT_NFT        EQU     $200            ; $200=512      - RAT
43                         INIT_NFLUSH
44        000400           INIT_NFLUSH     EQU     $400            ; $400=1024
45        000001           INIT_NCH        EQU     $1              ;
46        000002           INIT_VBIN       EQU     $2              ;
47        000002           INIT_HBIN       EQU     $2              ;
48        000000           INIT_VSKIP      EQU     $0              ;
49        000000           INIT_HSKIP      EQU     $0              ;
50        000000           INIT_GAIN       EQU     $0              ; 0=LOW 1=HIGH
51        0000C8           INIT_USEC       EQU     $C8             ;
52        000002           INIT_OPCH       EQU     $2              ; 1=CH_A 2=CH_B - RAT
53        000002           INIT_SCLKS      EQU     $2              ; 1=LEFT (TOP), 2=RIGHT (BOTTOM)    - RAT
54        000000           INIT_PID        EQU     $0              ; FLAG $0=OFF $1=ON


Motorola DSP56300 Assembler  Version 6.3.4   07-12-14  11:55:19  gcam_512ft.asm  Page 2



55        000000           INIT_LINK       EQU     $0              ; 0=wire 1=single_fiber
56     
57                         ;*****************************************************************************
58                         ;   EXTERNAL PERIPHERAL DEFINITIONS (GUIDER CAMERA)
59                         ;*****************************************************************************
60        FFFF80           SEQREG      EQU     $FFFF80             ; external CCD clock register
61        FFFF81           ADC_A       EQU     $FFFF81             ; A/D converter #1
62        FFFF82           ADC_B       EQU     $FFFF82             ; A/D converter #2
63        FFFF85           TXREG       EQU     $FFFF85             ; Transmit Data Register
64        FFFF86           RXREG       EQU     $FFFF86             ; Receive Data register
65        FFFF88           SIG_AB      EQU     $FFFF88             ; bias voltages A+B
66        FFFF90           CLK_AB      EQU     $FFFF90             ; clock voltages A+B
67        FFFF8A           TEC_REG     EQU     $FFFF8A             ; TEC register
68     
69                         ;*****************************************************************************
70                         ;   INTERNAL PERIPHERAL DEFINITIONS (DSP563000)
71                         ;*****************************************************************************
72        FFFFFF           IPRC        EQU     $FFFFFF             ; Interrupt priority register (core)
73        FFFFFE           IPRP        EQU     $FFFFFE             ; Interrupt priority register (periph)
74        FFFFFD           PCTL        EQU     $FFFFFD             ; PLL control register
75        FFFFFB           BCR         EQU     $FFFFFB             ; Bus control register (wait states)
76        FFFFF9           AAR0        EQU     $FFFFF9             ; Address attribute register 0
77        FFFFF8           AAR1        EQU     $FFFFF8             ; Address attribute register 1
78        FFFFF7           AAR2        EQU     $FFFFF7             ; Address attribute register 2
79        FFFFF6           AAR3        EQU     $FFFFF6             ; Address attribute register 3
80        FFFFF5           IDR         EQU     $FFFFF5             ; ID Register
81        FFFFC9           PDRB        EQU     $FFFFC9             ; Port B (HOST) GPIO data
82        FFFFC8           PRRB        EQU     $FFFFC8             ; Port B (HOST) GPIO direction
83        FFFFC4           PCRB        EQU     $FFFFC4             ; Port B (HOST) control register
84        FFFFBF           PCRC        EQU     $FFFFBF             ; Port C (ESSI_0) control register
85        FFFFBE           PRRC        EQU     $FFFFBE             ; Port C (ESSI_0) direction
86        FFFFBD           PDRC        EQU     $FFFFBD             ; Port C (ESSI_0) data
87        FFFFBC           TXD         EQU     $FFFFBC             ; ESSI0 Transmit Data Register 0
88        FFFFB8           RXD         EQU     $FFFFB8             ; ESSI0 Receive Data Register
89        FFFFB7           SSISR       EQU     $FFFFB7             ; ESSI0 Status Register
90        FFFFB6           CRB         EQU     $FFFFB6             ; ESSI0 Control Register B
91        FFFFB5           CRA         EQU     $FFFFB5             ; ESSI0 Control Register A
92        FFFFAF           PCRD        EQU     $FFFFAF             ; Port D (ESSI_1) control register
93        FFFFAE           PRRD        EQU     $FFFFAE             ; Port D (ESSI_1) direction
94        FFFFAD           PDRD        EQU     $FFFFAD             ; Port D (ESSI_1) data
95        FFFF9F           PCRE        EQU     $FFFF9F             ; Port E (SCI) control register
96        FFFF9E           PRRE        EQU     $FFFF9E             ; Port E (SCI) data direction
97        FFFF9D           PDRE        EQU     $FFFF9D             ; Port E (SCI) data
98        FFFF8F           TCSR0       EQU     $FFFF8F             ; TIMER0 Control/Status Register
99        FFFF8E           TLR0        EQU     $FFFF8E             ; TIMER0 Load Reg
100       FFFF8D           TCPR0       EQU     $FFFF8D             ; TIMER0 Compare Register
101       FFFF8C           TCR0        EQU     $FFFF8C             ; TIMER0 Count Register
102       FFFF8B           TCSR1       EQU     $FFFF8B             ; TIMER1 Control/Status Register
103       FFFF8A           TLR1        EQU     $FFFF8A             ; TIMER1 Load Reg
104       FFFF89           TCPR1       EQU     $FFFF89             ; TIMER1 Compare Register
105       FFFF88           TCR1        EQU     $FFFF88             ; TIMER1 Count Register
106       FFFF87           TCSR2       EQU     $FFFF87             ; TIMER2 Control/Status Register
107       FFFF86           TLR2        EQU     $FFFF86             ; TIMER2 Load Reg
108       FFFF85           TCPR2       EQU     $FFFF85             ; TIMER2 Compare Register


Motorola DSP56300 Assembler  Version 6.3.4   07-12-14  11:55:19  gcam_512ft.asm  Page 3



109       FFFF84           TCR2        EQU     $FFFF84             ; TIMER2 Count Register
110       FFFF83           TPLR        EQU     $FFFF83             ; TIMER Prescaler Load Register
111       FFFF82           TPCR        EQU     $FFFF82             ; TIMER Prescalar Count Register
112       FFFFEF           DSR0        EQU     $FFFFEF             ; DMA source address
113       FFFFEE           DDR0        EQU     $FFFFEE             ; DMA dest address
114       FFFFED           DCO0        EQU     $FFFFED             ; DMA counter
115       FFFFEC           DCR0        EQU     $FFFFEC             ; DMA control register
116    
117                        ;*****************************************************************************
118                        ;   REGISTER DEFINITIONS (GUIDER CAMERA)
119                        ;*****************************************************************************
120       000000           CMD         EQU     $000000             ; command word/flags from host
121       000001           OPFLAGS     EQU     $000001             ; operational flags
122       000002           NROWS       EQU     $000002             ; number of rows to read
123       000003           NCOLS       EQU     $000003             ; number of columns to read
124       000004           NFT         EQU     $000004             ; number of rows for frame transfer
125       000005           NFLUSH      EQU     $000005             ; number of columns to flush
126       000006           NCH         EQU     $000006             ; number of output channels (amps)
127       000007           NPIX        EQU     $000007             ; (not used)
128       000008           VBIN        EQU     $000008             ; vertical (parallel) binning
129       000009           HBIN        EQU     $000009             ; horizontal (serial) binning
130       00000A           VSKIP       EQU     $00000A             ; V prescan or offset (rows)
131       00000B           HSKIP       EQU     $00000B             ; H prescan or offset (columns)
132       00000C           VSUB        EQU     $00000C             ; V subraster size
133       00000D           HSUB        EQU     $00000D             ; H subraster size
134       00000E           NEXP        EQU     $00000E             ; number of exposures (not used)
135       00000F           NSHUFFLE    EQU     $00000F             ; (not used)
136    
137       000010           EXP_TIME    EQU     $000010             ; CCD integration time(r)
138       000011           TEMP        EQU     $000011             ; Temperature sensor reading(s)
139       000012           GAIN        EQU     $000012             ; Sig_proc gain
140       000013           USEC        EQU     $000013             ; Sig_proc sample time
141       000014           OPCH        EQU     $000014             ; Output channel
142       000015           HDIR        EQU     $000015             ; serial clock direction
143       000016           LINK        EQU     $000016             ; 0=wire 1=single_fiber
144    
145       000030           SCLKS       EQU     $000030             ; serial clocks
146       000031           SCLKS_FL    EQU     $000031             ; serial clocks flush
147       000032           INT_X       EQU     $000032             ; reset and integrate clocks
148       000033           NDMA        EQU     $000033             ; (not used)
149    
150       000018           VBIAS       EQU     $000018             ; bias voltages
151       000020           VCLK        EQU     $000020             ; clock voltages
152       00001A           TEC         EQU     $00001A             ; TEC current
153       000300           PIX         EQU     $000300             ; start address for data storage
154    
155                        ;*****************************************************************************
156                        ;   SEQUENCE FRAGMENT STARTING ADDRESSES (& OTHER POINTERS)
157                        ;*****************************************************************************
158       000040           MPP         EQU     $0040               ; MPP/hold state
159       000042           IPCLKS      EQU     $0042               ; input clamp
160       000044           TCLKS       EQU     $0044               ; Temperature monitor clocks
161       000048           PCLKS_FT    EQU     $0048               ; parallel frame transfer
162       000050           PCLKS_RD    EQU     $0050               ; parallel read-out transfer


Motorola DSP56300 Assembler  Version 6.3.4   07-12-14  11:55:19  gcam_512ft.asm  Page 4



163       000058           PCLKS_FL    EQU     $0058               ; parallel flush transfer
164       000060           INT_L       EQU     $0060               ; reset and first integration
165       000068           INT_H       EQU     $0068               ; second integration and A/D
166       000070           SCLKS_R     EQU     $0070               ; serial clocks shift right
167       000080           SCLKS_FLR   EQU     $0080               ; serial clocks flush right
168       000078           SCLKS_L     EQU     $0078               ; serial clocks shift left
169       000088           SCLKS_FLL   EQU     $0088               ; serial clocks flush left
170       000090           SCLKS_B     EQU     $0090               ; serial clocks both
171       000098           SCLKS_FLB   EQU     $0098               ; serial clocks flush both
172       0000A0           SCLKS_FF    EQU     $00A0               ; serial clocks fast flush
173    
174                        ;*******************************************************************************
175                        ;   INITIALIZE X MEMORY AND DEFINE PERIPHERALS
176                        ;*******************************************************************************
177       X:000000                     ORG     X:CMD               ; CCD control information
178       X:000000                     DC      $0                  ; CMD/FLAGS
179       X:000001                     DC      $0                  ; OPFLAGS
180       X:000002                     DC      INIT_NROWS          ; NROWS
181       X:000003                     DC      INIT_NCOLS          ; NCOLS
182       X:000004                     DC      INIT_NFT            ; NFT
183       X:000005                     DC      INIT_NFLUSH         ; NFLUSH
184       X:000006                     DC      INIT_NCH            ; NCH
185       X:000007                     DC      $1                  ; NPIX (not used)
186       X:000008                     DC      INIT_VBIN           ; VBIN
187       X:000009                     DC      INIT_HBIN           ; HBIN
188       X:00000A                     DC      INIT_VSKIP          ; VSKIP ($0)
189       X:00000B                     DC      INIT_HSKIP          ; HSKIP ($0)
190       X:00000C                     DC      $0                  ; VSUB
191       X:00000D                     DC      $0                  ; HSUB
192       X:00000E                     DC      $1                  ; NEXP (not used)
193       X:00000F                     DC      $0                  ; (not used)
194    
195       X:000010                     ORG     X:EXP_TIME
196       X:000010                     DC      $3E8                ; EXP_TIME
197       X:000011                     DC      $0                  ; TEMP
198       X:000012                     DC      INIT_GAIN           ; GAIN
199       X:000013                     DC      INIT_USEC           ; USEC SAMPLE TIME
200       X:000014                     DC      INIT_OPCH           ; OUTPUT CHANNEL
201       X:000015                     DC      INIT_SCLKS          ; HORIZ DIRECTION
202       X:000016                     DC      INIT_LINK           ; SERIAL LINK
203    
204                        ;*****************************************************************************
205                        ;   CCD57 SET DAC VOLTAGES  DEFAULTS:  OD=20V  RD=8V  OG=ABG=-6V
206                        ;   PCLKS=+3V -9V SCLKS=+2V -8V RG=+3V -9V
207                        ;   CCID37 SET DAC VOLTAGES  DEFAULTS:  OD=18V  RD=10V  OG=-2V
208                        ;   PCLKS=+4V -6V SCLKS=+4V -4V RG=+8V -2V
209                        ;   512FT SET DAC VOLTAGES  DEFAULTS:  OD=25V  RD=15.0V  OG=-1V
210                        ;   PCLKS=+2V -8V SCLKS=+4V -4V RG=+6V 0V
211                        ;*****************************************************************************
212    
213       X:000018                     ORG     X:VBIAS
214       X:000018                     DC      (DZ-0170)           ; OFFSET_R (5mV/DN)
215       X:000019                     DC      (DZ-0170)           ; OFFSET_L
216       X:00001A                     DC      (DZ+0000)           ; B7        N/U


Motorola DSP56300 Assembler  Version 6.3.4   07-12-14  11:55:19  gcam_512ft.asm  Page 5



217       X:00001B                     DC      (DZ-0200)           ; OG  voltage
218       X:00001C                     DC      (DZ+0000)           ; B5 (10 mV/DN) N/U
219       X:00001D                     DC      (DZ+1300)           ; RD
220       X:00001E                     DC      (DZ+2200)           ; OD_R
221       X:00001F                     DC      (DZ+2200)           ; OD_L
222    
223       X:000020                     ORG     X:VCLK
224       X:000020                     DC      (DZ-0000)           ; IPC- [V0] voltage (5mV/DN)    (0v)
225       X:000021                     DC      (DZ+0000)           ; IPC+ [V1]         (5v)
226       X:000022                     DC      (DZ-0400)           ; RG-  [V2]         (-2v)
227       X:000023                     DC      (DZ+1600)           ; RG+  [V3]         (+8v)
228       X:000024                     DC      (DZ-1200)           ; S-   [V4]         (-5v)
229       X:000025                     DC      (DZ+1200)           ; S+   [V5]         (+5v)
230       X:000026                     DC      (DZ-0000)           ; N/U  [V6]         (0v)
231       X:000027                     DC      (DZ+0000)           ; N/U  [V7]         (0v)
232       X:000028                     DC      (DZ-1800)           ; N/U  [V8]         (0v)
233       X:000029                     DC      (DZ+0600)           ; N/U  [V9]         (0v)
234       X:00002A                     DC      (DZ-1600)           ; P1-  [V10]            (-8v)
235       X:00002B                     DC      (DZ+0600)           ; P1+  [V11]            (+3v)
236       X:00002C                     DC      (DZ-1600)           ; P2-  [V12]            (-8v)
237       X:00002D                     DC      (DZ+0600)           ; P2+  [V13]            (+3v)
238       X:00002E                     DC      (DZ-1600)           ; P3-  [V14]            (-8v)
239       X:00002F                     DC      (DZ+0600)           ; P3+  [V15]            (+3v)
240    
241                        ;*****************************************************************************
242                        ;   INITIALIZE X MEMORY
243                        ;*****************************************************************************
244                        ;        R2L   _______________  ________________ R1L
245                        ;        R3L   ______________ || _______________ R3R
246                        ;        DG    _____________ |||| ______________ R2R
247                        ;        SPARE ____________ |||||| _____________ R1R
248                        ;        ST1   ___________ |||||||| ____________ RG
249                        ;        ST2   __________ |||||||||| ___________ IPC
250                        ;        ST3   _________ |||||||||||| __________ FINT+
251                        ;        IM1   ________ |||||||||||||| _________ FINT-
252                        ;        IM2   _______ |||||||||||||||| ________ FRST
253                        ;        IM3   ______ |||||||||||||||||| _______ CONVST
254                        ;                    ||||||||||||||||||||
255    
256       X:000040                      ORG X:MPP              ; reset/hold state
257       X:000040                     DC  %000000000000010010000011
258    
259       X:000042                     ORG X:IPCLKS            ; input clamp
260       X:000042                     DC  %000000000000010010010011
261       X:000043                     DC  %000000000000010010000011
262    
263       X:000044                     ORG X:TCLKS             ; read temp monitor
264       X:000044                     DC  %000000000000010010000010
265       X:000045                     DC  %000000000000010010000011
266    
267       X:000048                     ORG X:PCLKS_FT          ; frame transfer P3-P2-P1-P3
268       X:000048                     DC  %000001001000010010000011
269       X:000049                     DC  %000011011000010010000011
270       X:00004A                     DC  %000010010000010010000011


Motorola DSP56300 Assembler  Version 6.3.4   07-12-14  11:55:19  gcam_512ft.asm  Page 6



271       X:00004B                     DC  %000010110100010010000011
272       X:00004C                     DC  %000000100100010010000011
273       X:00004D                     DC  %000001101100010010000011
274    
275       X:000050                     ORG X:PCLKS_RD          ; parallel transfer P3-P2-P1-P3
276       X:000050                     DC  %000000001000010010010011
277       X:000051                     DC  %000000011000010010010011
278       X:000052                     DC  %000000010000010010000011
279       X:000053                     DC  %000000010100010010000011
280       X:000054                     DC  %000000000100010010000011
281       X:000055                     DC  %000000001100010010000011
282    
283                        ; ....................................................................
284                        ; original
285    
286                        ;            ORG X:PCLKS_FL          ; parallel flush P3-P2-P1-P3
287                        ;            DC  %000001001000010010000011
288                        ;            DC  %000011011000010010000011
289                        ;            DC  %000010010000010010000011
290                        ;            DC  %000010110100010010000011
291                        ;            DC  %000000100100010010000011
292                        ;            DC  %000001101100010010000011
293    
294    
295                        ; ....................................................................
296                        ; test
297    
298       X:000058                     ORG X:PCLKS_FL          ; parallel flush P3-P2-P1-P3
299       X:000058                     DC  %000001001000010010000011
300       X:000059                     DC  %000011011000111111100011
301       X:00005A                     DC  %000010010000111111100011
302       X:00005B                     DC  %000010110100111111100011
303       X:00005C                     DC  %000000100100111111100011
304       X:00005D                     DC  %000001101100010010000011
305    
306                        ; ....................................................................
307    
308       X:000060                     ORG X:INT_L             ; reset and first integration
309       X:000060                     DC  %000000000000010010100011   ; RG ON  FRST ON
310       X:000061                     DC  %000000000000010010000011   ; RG OFF
311       X:000062                     DC  %000000000000010010000001   ; FRST OFF
312       X:000063                     DC  %000000000000010010001001   ; FINT+ ON
313       X:000064                     DC  %000000000000010010000001   ; FINT+ OFF
314    
315       X:000068                     ORG X:INT_H             ; second integration and A to D
316       X:000068                     DC  %000000000000010010000101   ; FINT- ON
317       X:000069                     DC  %000000000000010010000001   ; FINT- OFF
318       X:00006A                     DC  %000000000000010010000000   ; /CONVST ON
319       X:00006B                     DC  %000000000000010010000001   ; /CONVST OFF
320       X:00006C                     DC  %000000000000010010100011   ; FRST ON RG ON
321    
322       X:000070                     ORG X:SCLKS_R           ; serial shift (right) S2-S3-S1-S2
323    
324       X:000070                     DC  %000000000000110110000001   ; right


Motorola DSP56300 Assembler  Version 6.3.4   07-12-14  11:55:19  gcam_512ft.asm  Page 7



325       X:000071                     DC  %000000000000100100000001
326       X:000072                     DC  %000000000000101101000001
327       X:000073                     DC  %000000000000001001000001
328       X:000074                     DC  %000000000000011011000001
329       X:000075                     DC  %000000000000010010000001
330    
331                        ;            DC  %000000000000011011000001  ;left
332                        ;            DC  %000000000000001001000001
333                        ;            DC  %000000000000101101000001
334                        ;            DC  %000000000000100100000001
335                        ;            DC  %000000000000110110000001
336                        ;            DC  %000000000000010010000001
337    
338       X:000080                     ORG X:SCLKS_FLR         ; serial flush (right) S2-S3-S1-S2
339       X:000080                     DC  %000000000000110110100011
340       X:000081                     DC  %000000000000100100100011
341       X:000082                     DC  %000000000000101101100011
342       X:000083                     DC  %000000000000001001100011
343       X:000084                     DC  %000000000000011011100011
344       X:000085                     DC  %000000000000010010100011
345    
346       X:000078                     ORG X:SCLKS_L           ; serial shift (left) S2-S1-S3-S2
347    
348                        ;            DC  %000000000000011011000001  ;left
349                        ;            DC  %000000000000001001000001
350                        ;            DC  %000000000000101101000001
351                        ;            DC  %000000000000100100000001
352                        ;            DC  %000000000000110110000001
353                        ;            DC  %000000000000010010000001
354    
355    
356       X:000078                     DC  %000000000000110110000001   ; right
357       X:000079                     DC  %000000000000100100000001
358       X:00007A                     DC  %000000000000101101000001
359       X:00007B                     DC  %000000000000001001000001
360       X:00007C                     DC  %000000000000011011000001
361       X:00007D                     DC  %000000000000010010000001
362    
363       X:000088                     ORG X:SCLKS_FLL         ; serial flush (left) S2-S1-S3-S2
364       X:000088                     DC  %000000000000011011100011
365       X:000089                     DC  %000000000000001001100011
366       X:00008A                     DC  %000000000000101101100011
367       X:00008B                     DC  %000000000000100100100011
368       X:00008C                     DC  %000000000000110110100011
369       X:00008D                     DC  %000000000000010010000011
370    
371       X:000090                     ORG X:SCLKS_B           ; serial shift (both)
372       X:000090                     DC  %000000000000110011000001
373       X:000091                     DC  %000000000000100001000001
374       X:000092                     DC  %000000000000101101000001
375       X:000093                     DC  %000000000000001100000001
376       X:000094                     DC  %000000000000011110000001
377       X:000095                     DC  %000000000000010010000001
378    


Motorola DSP56300 Assembler  Version 6.3.4   07-12-14  11:55:19  gcam_512ft.asm  Page 8



379       X:000098                     ORG X:SCLKS_FLB         ; serial flush (both)
380       X:000098                     DC  %000000000000110011100011
381       X:000099                     DC  %000000000000100001100011
382       X:00009A                     DC  %000000000000101101100011
383       X:00009B                     DC  %000000000000001100100011
384       X:00009C                     DC  %000000000000011110100011
385       X:00009D                     DC  %000000000000010010100011
386    
387       X:0000A0                     ORG X:SCLKS_FF          ; serial flush (fast) DG
388       X:0000A0                     DC  %000000000000010010100011
389       X:0000A1                     DC  %000000000000111111100011
390       X:0000A2                     DC  %000000000000111111100011
391       X:0000A3                     DC  %000000000000111111100011
392       X:0000A4                     DC  %000000000000111111100011   ; dummy code
393       X:0000A5                     DC  %000000000000010010100011   ; dummy code
394    
395    
396                        ;*******************************************************************************
397                        ;   GENERAL COMMENTS
398                        ;*******************************************************************************
399                        ; Hardware RESET causes download from serial port (code in EPROM)
400                        ; R0 is a pointer to sequence fragments
401                        ; R1 is a pointer used by send/receive routines
402                        ; R2 is a pointer to the current data location
403                        ; See dspdvr.h for command and opflag definitions
404                        ;*******************************************************************************
405                        ;   INITIALIZE INTERRUPT VECTORS
406                        ;*******************************************************************************
407       P:000000                     ORG     P:$0000
408       P:000000 0C0100              JMP     START
409                        ;*******************************************************************************
410                        ;   MAIN PROGRAM
411                        ;*******************************************************************************
412       P:000100                     ORG     P:START
413       P:000100 0003F8  SET_MODE    ORI     #$3,MR                  ; mask all interrupts
414       P:000101 08F4B6              MOVEP   #$FFFC21,X:AAR3         ; PERIPH $FFF000--$FFFFFF
                   FFFC21
415       P:000103 08F4B8              MOVEP   #$D00909,X:AAR1         ; EEPROM $D00000--$D07FFF 32K
                   D00909
416       P:000105 08F4B9              MOVEP   #$000811,X:AAR0         ; SRAM X $000000--$00FFFF 64K
                   000811
417       P:000107 08F4BB              MOVEP   #WS,X:BCR               ; Set periph wait states
                   073FE1
418       P:000109 0505A0              MOVE    #SEQ-1,M0               ; Set sequencer address modulus
419    
420                        PORTB_SETUP
421       P:00010A 08F484  PORTB_SETUP MOVEP   #>$1,X:PCRB             ; set PB[15..0] GPIO
                   000001
422    
423                        PORTD_SETUP
424       P:00010C 07F42F  PORTD_SETUP MOVEP   #>$0,X:PCRD             ; GPIO PD0=TM PD1=GAIN
                   000000
425       P:00010E 07F42E              MOVEP   #>$3,X:PRRD             ; PD2=/ENRX PD3=/ENTX
                   000003


Motorola DSP56300 Assembler  Version 6.3.4   07-12-14  11:55:19  gcam_512ft.asm  Page 9



426       P:000110 07F42D              MOVEP   #>$0,X:PDRD             ; PD4=RXRDY
                   000000
427    
428       P:000112 07F436  SSI_SETUP   MOVEP   #>$032070,X:CRB         ; async, LSB, enable TE RE
                   032070
429       P:000114 07F435              MOVEP   #>$140803,X:CRA         ; 10 Mbps, 16 bit word
                   140803
430       P:000116 07F43F              MOVEP   #>$3F,X:PCRC            ; enable ESSI
                   00003F
431    
432                        PORTE_SETUP
433       P:000118 07F41F  PORTE_SETUP MOVEP   #$0,X:PCRE              ; enable GPIO, disable SCI
                   000000
434       P:00011A 07F41E              MOVEP   #>$1,X:PRRE             ; PE0=SHUTTER
                   000001
435       P:00011C 07F41D              MOVEP   #>$0,X:PDRE             ;
                   000000
436    
437       P:00011E 07F40F  SET_TIMER   MOVEP   #$300A10,X:TCSR0        ; Pulse mode, no prescale
                   300A10
438       P:000120 07F40E              MOVEP   #$0,X:TLR0              ; timer reload value
                   000000
439       P:000122 07F00D              MOVEP   X:USEC,X:TCPR0          ; timer compare value
                   000013
440       P:000124 07F40B              MOVEP   #$308A10,X:TCSR1        ; Pulse mode, prescaled
                   308A10
441       P:000126 07F40A              MOVEP   #$0,X:TLR1              ; timer reload value
                   000000
442       P:000128 07F009              MOVEP   X:EXP_TIME,X:TCPR1      ; timer compare value
                   000010
443       P:00012A 07F403              MOVEP   #>$9C3F,X:TPLR          ; timer prescale ($9C3F=1ms 80MHz)
                   009C3F
444    
445       P:00012C 08F4AF  DMA_SETUP   MOVEP   #PIX,X:DSR0             ; set DMA source
                   000300
446       P:00012E 08F4AD              MOVEP   #$0,X:DCO0              ; set DMA counter
                   000000
447       P:000130 0A1680  FIBER       JCLR    #$0,X:LINK,RS485        ; set up optical
                   000136
448       P:000132 08F4AE              MOVEP   #>TXREG,X:DDR0          ; set DMA destination
                   FFFF85
449       P:000134 08F4AC              MOVEP   #>$080255,X:DCR0        ; DMA word xfer, /IRQA, src+1
                   080255
450       P:000136 0A16A0  RS485       JSET    #$0,X:LINK,ENDDP        ; set up RS485
                   00013C
451       P:000138 08F4AE              MOVEP   #>TXD,X:DDR0            ; DMA destination
                   FFFFBC
452       P:00013A 08F4AC              MOVEP   #>$085A51,X:DCR0        ; DMA word xfer, TDE0, src+1
                   085A51
453       P:00013C 000000  ENDDP       NOP                             ;
454    
455       P:00013D 0BF080  INIT_SETUP  JSR     MPPHOLD                 ;
                   0001C3
456       P:00013F 0BF080              JSR     SET_GAIN                ;


Motorola DSP56300 Assembler  Version 6.3.4   07-12-14  11:55:19  gcam_512ft.asm  Page 10



                   000332
457       P:000141 0BF080              JSR     SET_DACS                ;
                   0002DA
458       P:000143 0BF080              JSR     SET_SCLKS               ;
                   00033C
459    
460       P:000145 0A1680  WAIT_CMD    JCLR    #$0,X:LINK,WAITB        ; check for cmd ready
                   000149
461       P:000147 01AD84              JCLR    #$4,X:PDRD,ECHO         ; fiber link (single-fiber)
                   000153
462       P:000149 0A16A0  WAITB       JSET    #$0,X:LINK,ENDW         ;
                   00014D
463       P:00014B 01B787              JCLR    #7,X:SSISR,ECHO         ; wire link
                   000153
464       P:00014D 000000  ENDW        NOP                             ;
465    
466       P:00014E 0BF080              JSR     READ16                  ; wait for command word
                   000275
467       P:000150 540000              MOVE    A1,X:CMD                ; cmd in X:CMD
468       P:000151 0BF080              JSR     CMD_FIX                 ; interpret command word
                   000367
469    
470       P:000153 0A0081  ECHO        JCLR    #$1,X:CMD,GET           ; test for DSP_ECHO command
                   00015A
471       P:000155 0BF080              JSR     READ16                  ;
                   000275
472       P:000157 0BF080              JSR     WRITE16                 ;
                   000285
473       P:000159 0A0001              BCLR    #$1,X:CMD               ;
474    
475       P:00015A 0A0082  GET         JCLR    #$2,X:CMD,PUT           ; test for DSP_GET command
                   00015F
476       P:00015C 0BF080              JSR     MEM_SEND                ;
                   0002CD
477       P:00015E 0A0002              BCLR    #$2,X:CMD               ;
478    
479       P:00015F 0A0083  PUT         JCLR    #$3,X:CMD,EXP_START     ; test for DSP_PUT command
                   000164
480       P:000161 0BF080              JSR     MEM_LOAD                ;
                   0002C1
481       P:000163 0A0003              BCLR    #$3,X:CMD               ;
482    
483       P:000164 0A0086  EXP_START   JCLR    #$6,X:CMD,FASTFLUSH     ; test for EXPOSE command
                   000171
484       P:000166 0BF080              JSR     MPPHOLD                 ;
                   0001C3
485       P:000168 62F400              MOVE    #PIX,R2                 ; set data pointer
                   000300
486       P:00016A 07F009              MOVEP   X:EXP_TIME,X:TCPR1      ; timer compare value
                   000010
487       P:00016C 0A012F              BSET    #$F,X:OPFLAGS           ; set exp_in_progress flag
488       P:00016D 0A0006              BCLR    #$6,X:CMD               ;
489    
490       P:00016E 0A0181              JCLR    #$1,X:OPFLAGS,FASTFLUSH ; check for AUTO_FLUSH


Motorola DSP56300 Assembler  Version 6.3.4   07-12-14  11:55:19  gcam_512ft.asm  Page 11



                   000171
491       P:000170 0A0024              BSET    #$4,X:CMD               ;
492    
493       P:000171 0A0084  FASTFLUSH   JCLR    #$4,X:CMD,BEAM_ON       ; test for FLUSH command
                   00017A
494       P:000173 0BF080              JSR     FLUSHFRAME              ; fast FLUSH
                   0001EB
495       P:000175 0BF080              JSR     FLUSHFRAME              ; fast FLUSH
                   0001EB
496       P:000177 0BF080              JSR     FLUSHLINE               ; clear serial register
                   0001D0
497       P:000179 0A0004              BCLR    #$4,X:CMD               ;
498    
499       P:00017A 0A0085  BEAM_ON     JCLR    #$5,X:CMD,EXPOSE        ; test for open shutter
                   00017E
500       P:00017C 011D20              BSET    #$0,X:PDRE              ; set SHUTTER
501       P:00017D 0A0005              BCLR    #$5,X:CMD               ;
502    
503       P:00017E 0A018F  EXPOSE      JCLR    #$F,X:OPFLAGS,BEAM_OFF  ; check exp_in_progress flag
                   00018B
504    
505       P:000180 0BF080              JSR     MPPHOLD                 ;
                   0001C3
506       P:000182 0BF080              JSR     M_TIMER                 ;
                   00032C
507       P:000184 0A010F              BCLR    #$F,X:OPFLAGS           ; clear exp_in_progress flag
508    
509       P:000185 0A0182  OPT_A       JCLR    #$2,X:OPFLAGS,OPT_B     ; check for AUTO_SHUTTER
                   000188
510       P:000187 0A0027              BSET    #$7,X:CMD               ; prep to close shutter
511       P:000188 0A0184  OPT_B       JCLR    #$4,X:OPFLAGS,BEAM_OFF  ; check for AUTO_READ
                   00018B
512       P:00018A 0A0028              BSET    #$8,X:CMD               ; prep for full readout
513    
514       P:00018B 0A0087  BEAM_OFF    JCLR    #$7,X:CMD,READ_CCD      ; test for shutter close
                   00018F
515       P:00018D 011D00              BCLR    #$0,X:PDRE              ; clear SHUTTER
516       P:00018E 0A0007              BCLR    #$7,X:CMD               ;
517    
518       P:00018F 0A0088  READ_CCD    JCLR    #$8,X:CMD,AUTO_WIPE     ; test for READCCD command
                   0001A5
519       P:000191 0BF080              JSR     FRAME                   ; frame transfer
                   000201
520                        ;           JSR     IPC_CLAMP               ; discharge ac coupling cap
521       P:000193 0BF080              JSR     FLUSHROWS               ; vskip
                   0001E1
522       P:000195 060200              DO      X:NROWS,END_READ        ; read the array
                   0001A2
523       P:000197 0BF080              JSR     FLUSHLINE               ;
                   0001D0
524       P:000199 0BF080              JSR     PARALLEL                ;
                   0001F5
525       P:00019B 0BF080              JSR     FLUSHPIX                ; hskip
                   0001D7


Motorola DSP56300 Assembler  Version 6.3.4   07-12-14  11:55:19  gcam_512ft.asm  Page 12



526       P:00019D 0A0120              BSET    #$0,X:OPFLAGS           ; set first pixel flag
527       P:00019E 0BF080              JSR     READPIX                 ;
                   000213
528       P:0001A0 0A0100              BCLR    #$0,X:OPFLAGS           ; clear first pixel flag
529       P:0001A1 0BF080              JSR     READLINE                ;
                   000211
530       P:0001A3 000000  END_READ    NOP                             ;
531       P:0001A4 0A0008              BCLR    #$8,X:CMD               ;
532    
533       P:0001A5 0A0089  AUTO_WIPE   JCLR    #$9,X:CMD,HH_DACS       ; test for AUTOWIPE command
                   0001A7
534                        ;            BSET    #$E,X:OPFLAGS           ;
535                        ;            BSET    #$5,X:OPFLAGS           ;
536                        ;            JSR     FL_CLOCKS               ; flush one parallel row
537                        ;            JSR     READLINE                ;
538                        ;            BCLR    #$9,X:CMD               ;
539    
540       P:0001A7 0A008A  HH_DACS     JCLR    #$A,X:CMD,HH_TEMP       ; test for HH_SYNC command
                   0001AC
541       P:0001A9 0BF080              JSR     SET_DACS                ;
                   0002DA
542       P:0001AB 0A000A              BCLR    #$A,X:CMD               ;
543    
544       P:0001AC 0A008B  HH_TEMP     JCLR    #$B,X:CMD,HH_TEC        ; test for HH_TEMP command
                   0001B1
545       P:0001AE 0BF080              JSR     TEMP_READ               ; perform housekeeping chores
                   0002F7
546       P:0001B0 0A000B              BCLR    #$B,X:CMD               ;
547    
548       P:0001B1 0A008C  HH_TEC      JCLR    #$C,X:CMD,HH_OTHER      ; test for HH_TEC command
                   0001B6
549       P:0001B3 0BF080              JSR     TEMP_SET                ; set the TEC value
                   000319
550       P:0001B5 0A000C              BCLR    #$C,X:CMD               ;
551    
552       P:0001B6 0A008D  HH_OTHER    JCLR    #$D,X:CMD,END_CODE      ; test for HH_OTHER command
                   0001BF
553       P:0001B8 0BF080              JSR     SET_GAIN                ;
                   000332
554       P:0001BA 0BF080              JSR     SET_SCLKS               ;
                   00033C
555       P:0001BC 0BF080              JSR     SET_USEC                ;
                   000339
556       P:0001BE 0A000D              BCLR    #$D,X:CMD               ;
557    
558       P:0001BF 0A0185  END_CODE    JCLR    #$5,X:OPFLAGS,WAIT_CMD  ; check for AUTO_WIPE
                   000145
559       P:0001C1 0A0029              BSET    #$9,X:CMD               ;
560       P:0001C2 0C0145              JMP     WAIT_CMD                ; Get next command
561    
562                        ;*****************************************************************************
563                        ;   HOLD (MPP MODE)
564                        ;*****************************************************************************
565       P:0001C3 07B080  MPPHOLD     MOVEP   X:MPP,Y:<<SEQREG        ;


Motorola DSP56300 Assembler  Version 6.3.4   07-12-14  11:55:19  gcam_512ft.asm  Page 13



                   000040
566       P:0001C5 00000C              RTS                             ;
567    
568                        ;*****************************************************************************
569                        ;   INPUT CLAMP
570                        ;*****************************************************************************
571       P:0001C6 07B080  IPC_CLAMP   MOVEP   X:IPCLKS,Y:<<SEQREG     ;
                   000042
572       P:0001C8 44F400              MOVE    #>HOLD_IPC,X0           ;
                   001F40
573       P:0001CA 06C420              REP     X0                      ; $1F4O=100 us
574       P:0001CB 000000              NOP                             ;
575       P:0001CC 07B080              MOVEP   X:(IPCLKS+1),Y:<<SEQREG ;
                   000043
576       P:0001CE 000000              NOP                             ;
577       P:0001CF 00000C              RTS                             ;
578    
579                        ;*****************************************************************************
580                        ;   FLUSHLINE  (FAST FLUSH)
581                        ;*****************************************************************************
582       P:0001D0 30A000  FLUSHLINE   MOVE    #SCLKS_FF,R0            ; initialize pointer
583       P:0001D1 060680              DO      #SEQ,ENDFF              ;
                   0001D5
584       P:0001D3 079880              MOVEP   X:(R0)+,Y:<<SEQREG      ;
585       P:0001D4 0620A0              REP     #HOLD_FF                ;
586       P:0001D5 000000              NOP                             ;
587       P:0001D6 00000C  ENDFF       RTS                             ;
588    
589                        ;*****************************************************************************
590                        ;   FLUSHPIX (HSKIP)
591                        ;*****************************************************************************
592       P:0001D7 060B00  FLUSHPIX    DO      X:HSKIP,ENDFP           ;
                   0001DF
593       P:0001D9 60B100              MOVE    X:SCLKS_FL,R0           ; initialize pointer
594       P:0001DA 060680              DO      #SEQ,ENDHCLK            ;
                   0001DE
595       P:0001DC 079880              MOVEP   X:(R0)+,Y:<<SEQREG      ;
596       P:0001DD 0605A0              REP     #HOLD_S                 ;
597       P:0001DE 000000              NOP                             ;
598       P:0001DF 000000  ENDHCLK     NOP                             ;
599       P:0001E0 00000C  ENDFP       RTS                             ;
600    
601                        ;*****************************************************************************
602                        ;   FLUSHROWS (VSKIP)
603                        ;*****************************************************************************
604       P:0001E1 060A00  FLUSHROWS   DO      X:VSKIP,ENDVSKIP        ;
                   0001E9
605       P:0001E3 305000              MOVE    #PCLKS_RD,R0            ; initialize pointer
606       P:0001E4 060680              DO      #SEQ,ENDVCLK            ;
                   0001E8
607       P:0001E6 079880              MOVEP   X:(R0)+,Y:<<SEQREG      ;
608       P:0001E7 067CA0              REP     #HOLD_FL                ;
609       P:0001E8 000000              NOP                             ;
610       P:0001E9 000000  ENDVCLK     NOP                             ;


Motorola DSP56300 Assembler  Version 6.3.4   07-12-14  11:55:19  gcam_512ft.asm  Page 14



611       P:0001EA 00000C  ENDVSKIP    RTS                             ;
612    
613                        ;*****************************************************************************
614                        ;   FLUSHFRAME
615                        ;*****************************************************************************
616       P:0001EB 060500  FLUSHFRAME  DO      X:NFLUSH,ENDFLFR           ;
                   0001F3
617       P:0001ED 305800  FL_CLOCKS   MOVE    #PCLKS_FL,R0            ; initialize pointer
618       P:0001EE 060680              DO      #SEQ,ENDFLCLK           ;
                   0001F2
619       P:0001F0 079880              MOVEP   X:(R0)+,Y:<<SEQREG      ;
620       P:0001F1 067CA0              REP     #HOLD_FL                ;
621       P:0001F2 000000              NOP                             ;
622       P:0001F3 000000  ENDFLCLK    NOP                             ;
623       P:0001F4 00000C  ENDFLFR     RTS                             ;
624    
625                        ;*****************************************************************************
626                        ;   PARALLEL TRANSFER (READOUT)
627                        ;*****************************************************************************
628       P:0001F5 060800  PARALLEL    DO      X:VBIN,ENDPT            ;
                   0001FF
629       P:0001F7 305000  P_CLOCKS    MOVE    #PCLKS_RD,R0            ; initialize pointer
630       P:0001F8 060680              DO      #SEQ,ENDPCLK            ;
                   0001FE
631       P:0001FA 079880              MOVEP   X:(R0)+,Y:<<SEQREG      ;
632       P:0001FB 44F400              MOVE    #>HOLD_P,X0             ;
                   00020A
633       P:0001FD 06C420              REP     X0                      ; $317=10us per phase
634       P:0001FE 000000              NOP                             ;
635       P:0001FF 000000  ENDPCLK     NOP                             ;
636       P:000200 00000C  ENDPT       RTS                             ;
637    
638                        ;*****************************************************************************
639                        ;   PARALLEL TRANSFER (FRAME TRANSFER)
640                        ;*****************************************************************************
641       P:000201 07B080  FRAME       MOVEP   X:(PCLKS_FT),Y:<<SEQREG ; 100 us CCD47 pause
                   000048
642       P:000203 44F400              MOVE    #>$1F40,X0              ;
                   001F40
643       P:000205 06C420              REP     X0                      ; $1F40=100 usec
644       P:000206 000000              NOP                             ;
645       P:000207 060400              DO      X:NFT,ENDFT             ;
                   00020F
646       P:000209 304800  FT_CLOCKS   MOVE    #PCLKS_FT,R0            ; initialize seq pointer
647       P:00020A 060680              DO      #SEQ,ENDFTCLK           ;
                   00020E
648       P:00020C 079880              MOVEP   X:(R0)+,Y:<<SEQREG      ;
649       P:00020D 067CA0              REP     #HOLD_FT                ;
650       P:00020E 000000              NOP                             ;
651       P:00020F 000000  ENDFTCLK    NOP                             ;
652       P:000210 00000C  ENDFT       RTS                             ;
653    
654                        ;*****************************************************************************
655                        ;   READLINE SUBROUTINE


Motorola DSP56300 Assembler  Version 6.3.4   07-12-14  11:55:19  gcam_512ft.asm  Page 15



656                        ;*****************************************************************************
657       P:000211 060300  READLINE    DO      X:NCOLS,ENDRL           ;
                   000273
658       P:000213 07B080  READPIX     MOVEP   X:(INT_L),Y:<<SEQREG    ; FRST=ON RG=ON
                   000060
659                                    DUP     HOLD_RG                 ; macro
660  m                                 NOP                             ;
661  m                                 ENDM                            ; end macro
668       P:00021B 07B080              MOVEP   X:(INT_L+1),Y:<<SEQREG  ; RG=OFF
                   000061
669       P:00021D 07B080              MOVEP   X:(INT_L+2),Y:<<SEQREG  ; FRST=OFF
                   000062
670       P:00021F 060FA0              REP     #HOLD_SIG               ; preamp settling time
671                        ;           REP     #$F                     ; preamp settling
672       P:000220 000000              NOP                             ;
673       P:000221 07B080  INT1        MOVEP   X:(INT_L+3),Y:<<SEQREG  ; FINT+=ON
                   000063
674       P:000223 449300  SLEEP1      MOVE    X:USEC,X0               ; sleep USEC * 12.5ns
675       P:000224 06C420              REP     X0                      ;
676       P:000225 000000              NOP                             ;
677       P:000226 07B080              MOVEP   X:(INT_L+4),Y:<<SEQREG  ; FINT+=OFF
                   000064
678       P:000228 60B000  SERIAL      MOVE    X:SCLKS,R0              ; serial transfer
679       P:000229 060900              DO      X:HBIN,ENDSCLK          ;
                   00024E
680                        S_CLOCKS    DUP     SEQ                     ;    macro
681  m                                 MOVEP   X:(R0)+,Y:<<SEQREG      ;
682  m                                 DUP     HOLD_S                  ;    macro
683  m                                 NOP                             ;
684  m                                 ENDM                            ;
685  m                                 ENDM                            ;
740       P:00024F 060FA0  ENDSCLK     REP     #HOLD_SIG               ; preamp settling time
741       P:000250 000000              NOP                             ; (adjust with o'scope)
742       P:000251 08F4BB  GET_DATA    MOVEP   #WS5,X:BCR              ;
                   07BFE1
743       P:000253 000000              NOP                             ;
744       P:000254 000000              NOP                             ;
745       P:000255 044E21              MOVEP   Y:<<ADC_A,A             ; read ADC
746       P:000256 044F22              MOVEP   Y:<<ADC_B,B             ; read ADC
747       P:000257 08F4BB              MOVEP   #WS,X:BCR               ;
                   073FE1
748       P:000259 000000              NOP                             ;
749       P:00025A 07B080  INT2        MOVEP   X:(INT_H),Y:<<SEQREG    ; FINT-=ON
                   000068
750       P:00025C 449300  SLEEP2      MOVE    X:USEC,X0               ; sleep USEC * 20ns
751       P:00025D 06C420              REP     X0                      ;
752       P:00025E 000000              NOP                             ;
753       P:00025F 07B080              MOVEP   X:(INT_H+1),Y:<<SEQREG  ; FINT-=OFF
                   000069
754       P:000261 5C7000              MOVE    A1,Y:(PIX)              ;
                   000300
755       P:000263 5D7000              MOVE    B1,Y:(PIX+1)            ;
                   000301
756       P:000265 060FA0              REP     #HOLD_ADC               ; settling time


Motorola DSP56300 Assembler  Version 6.3.4   07-12-14  11:55:19  gcam_512ft.asm  Page 16



757       P:000266 000000              NOP                             ; (adjust for best noise)
758       P:000267 07B080  CONVST      MOVEP   X:(INT_H+2),Y:<<SEQREG  ; /CONVST=ON
                   00006A
759       P:000269 08DD2F              MOVEP   N5,X:DSR0               ; set DMA source
760       P:00026A 000000              NOP                             ;
761       P:00026B 000000              NOP                             ;
762       P:00026C 07B080              MOVEP   X:(INT_H+3),Y:<<SEQREG  ; /CONVST=OFF MIN 40 NS
                   00006B
763       P:00026E 07B080              MOVEP   X:(INT_H+4),Y:<<SEQREG  ; FRST=ON
                   00006C
764       P:000270 0A01A0              JSET    #$0,X:OPFLAGS,ENDCHK    ; check for first pixel
                   000273
765       P:000272 0AAC37              BSET    #$17,X:DCR0             ; enable DMA
766       P:000273 000000  ENDCHK      NOP                             ;
767       P:000274 00000C  ENDRL       RTS                             ;
768    
769                        ;*******************************************************************************
770                        ;   READ AND WRITE 16-BIT AND 24-BIT DATA
771                        ;*******************************************************************************
772       P:000275 0A1680  READ16      JCLR    #$0,X:LINK,RD16B        ; check RS485 or fiber
                   00027D
773       P:000277 01AD84              JCLR    #$4,X:PDRD,*            ; wait for data in RXREG
                   000277
774       P:000279 5EF000              MOVE    Y:RXREG,A               ; bits 15..0
                   FFFF86
775       P:00027B 0140C6              AND     #>$FFFF,A               ;
                   00FFFF
776       P:00027D 0A16A0  RD16B       JSET    #$0,X:LINK,ENDRD16      ; check RS485 or fiber
                   000284
777       P:00027F 01B787              JCLR    #7,X:SSISR,*            ; wait for RDRF to go high
                   00027F
778       P:000281 54F000              MOVE    X:RXD,A1                ; read from ESSI
                   FFFFB8
779       P:000283 000000              NOP                             ;
780       P:000284 00000C  ENDRD16     RTS                             ; 16-bit word in A1
781    
782       P:000285 0A1680  WRITE16     JCLR    #$0,X:LINK,WR16B        ; check RS485 or fiber
                   000289
783       P:000287 5C7000              MOVE    A1,Y:TXREG              ; write bits 15..0
                   FFFF85
784       P:000289 0A16A0  WR16B       JSET    #$0,X:LINK,ENDWR16      ;
                   00028F
785       P:00028B 01B786              JCLR    #6,X:SSISR,*            ; wait for TDE
                   00028B
786       P:00028D 547000              MOVE    A1,X:TXD                ;
                   FFFFBC
787       P:00028F 00000C  ENDWR16     RTS                             ;
788    
789       P:000290 0A1680  READ24      JCLR    #$0,X:LINK,RD24B        ; check RS485 or fiber
                   00029E
790       P:000292 01AD84              JCLR    #$4,X:PDRD,*            ; wait for data in RXREG
                   000292
791       P:000294 5EF000              MOVE    Y:RXREG,A               ; bits 15..0
                   FFFF86


Motorola DSP56300 Assembler  Version 6.3.4   07-12-14  11:55:19  gcam_512ft.asm  Page 17



792       P:000296 0140C6              AND     #>$FFFF,A               ;
                   00FFFF
793       P:000298 0C1C20              ASR     #$10,A,A                ; shift right 16 bits
794       P:000299 01AD84              JCLR    #$4,X:PDRD,*            ; wait for data in RXREG
                   000299
795       P:00029B 5CF000              MOVE    Y:RXREG,A1              ; bits 15..0
                   FFFF86
796       P:00029D 0C1D20              ASL     #$10,A,A                ; shift left 16 bits
797       P:00029E 0A16A0  RD24B       JSET    #$0,X:LINK,ENDRD24      ;
                   0002AA
798       P:0002A0 01B787              JCLR    #7,X:SSISR,*            ; wait for RDRF to go high
                   0002A0
799       P:0002A2 56F000              MOVE    X:RXD,A                 ; read from ESSI
                   FFFFB8
800       P:0002A4 0C1C20              ASR     #$10,A,A                ; shift right 16 bits
801       P:0002A5 01B787              JCLR    #7,X:SSISR,*            ; wait for RDRF to go high
                   0002A5
802       P:0002A7 54F000              MOVE    X:RXD,A1                ;
                   FFFFB8
803       P:0002A9 0C1D20              ASL     #$10,A,A                ; shift left 16 bits
804       P:0002AA 00000C  ENDRD24     RTS                             ; 24-bit word in A1
805    
806       P:0002AB 0A1680  WRITE24     JCLR    #$0,X:LINK,WR24B        ; check RS485 or fiber
                   0002B4
807       P:0002AD 5C7000              MOVE    A1,Y:TXREG              ; send bits 15..0
                   FFFF85
808       P:0002AF 0C1C20              ASR     #$10,A,A                ; right shift 16 bits
809       P:0002B0 0610A0              REP     #$10                    ; wait for data sent
810       P:0002B1 000000              NOP                             ;
811       P:0002B2 5C7000              MOVE    A1,Y:TXREG              ; send bits 23..16
                   FFFF85
812       P:0002B4 0A16A0  WR24B       JSET    #$0,X:LINK,ENDWR24      ;
                   0002C0
813       P:0002B6 01B786              JCLR    #6,X:SSISR,*            ; wait for TDE
                   0002B6
814       P:0002B8 547000              MOVE    A1,X:TXD                ; send bits 15..0
                   FFFFBC
815       P:0002BA 0C1C20              ASR     #$10,A,A                ; right shift 16 bits
816       P:0002BB 000000              NOP                             ; wait for flag update
817       P:0002BC 01B786              JCLR    #6,X:SSISR,*            ; wait for TDE
                   0002BC
818       P:0002BE 547000              MOVE    A1,X:TXD                ; send bits 23..16
                   FFFFBC
819       P:0002C0 00000C  ENDWR24     RTS                             ;
820    
821                        ;*****************************************************************************
822                        ;   LOAD NEW DATA VIA SSI PORT
823                        ;*****************************************************************************
824       P:0002C1 0D0290  MEM_LOAD    JSR     READ24                  ; get memspace/address
825       P:0002C2 219100              MOVE    A1,R1                   ; load address into R1
826       P:0002C3 218400              MOVE    A1,X0                   ; store memspace code
827       P:0002C4 0D0290              JSR     READ24                  ; get data
828       P:0002C5 0AD157              BCLR    #$17,R1                 ; clear memspace bit
829       P:0002C6 0AC437  X_LOAD      JSET    #$17,X0,Y_LOAD          ;


Motorola DSP56300 Assembler  Version 6.3.4   07-12-14  11:55:19  gcam_512ft.asm  Page 18



                   0002C9
830       P:0002C8 546100              MOVE    A1,X:(R1)               ; load x memory
831       P:0002C9 0AC417  Y_LOAD      JCLR    #$17,X0,END_LOAD        ;
                   0002CC
832       P:0002CB 5C6100              MOVE    A1,Y:(R1)               ; load y memory
833       P:0002CC 00000C  END_LOAD    RTS                             ;
834    
835                        ;*****************************************************************************
836                        ;   SEND MEMORY CONTENTS VIA SSI PORT
837                        ;*****************************************************************************
838       P:0002CD 0D0290  MEM_SEND    JSR     READ24                  ; get memspace/address
839       P:0002CE 219100              MOVE    A1,R1                   ; load address into R1
840       P:0002CF 218400              MOVE    A1,X0                   ; save memspace code
841       P:0002D0 0AD157              BCLR    #$17,R1                 ; clear memspace bit
842       P:0002D1 0AC437  X_SEND      JSET    #$17,X0,Y_SEND          ;
                   0002D4
843       P:0002D3 54E100              MOVE    X:(R1),A1               ; send x memory
844       P:0002D4 0AC417  Y_SEND      JCLR    #$17,X0,WRITE24         ;
                   0002AB
845       P:0002D6 5CE100              MOVE    Y:(R1),A1               ; send y memory
846       P:0002D7 0D02AB  SEND24      JSR     WRITE24                 ;
847       P:0002D8 000000              NOP                             ;
848       P:0002D9 00000C              RTS                             ;
849    
850                        ;*****************************************************************************
851                        ;   CCID37 SET DAC VOLTAGES  DEFAULTS:  OD=18V  RD=10V  OG=-2V
852                        ;   PCLKS=+4V -6V SCLKS=+4V -4V RG=+8V -2V
853                        ;*****************************************************************************
854       P:0002DA 0BF080  SET_DACS    JSR     SET_VBIAS               ;
                   0002DF
855       P:0002DC 0BF080              JSR     SET_VCLKS               ;
                   0002EB
856       P:0002DE 00000C              RTS                             ;
857    
858       P:0002DF 08F4BB  SET_VBIAS   MOVEP   #WS5,X:BCR              ; add wait states
                   07BFE1
859       P:0002E1 331800              MOVE    #VBIAS,R3               ; bias voltages
860       P:0002E2 64F400              MOVE    #SIG_AB,R4              ; bias DAC registers
                   FFFF88
861       P:0002E4 060880              DO      #$8,ENDSETB             ; set bias voltages
                   0002E7
862       P:0002E6 44DB00              MOVE    X:(R3)+,X0              ;
863       P:0002E7 4C5C00              MOVE    X0,Y:(R4)+              ;
864       P:0002E8 08F4BB  ENDSETB     MOVEP   #WS,X:BCR               ;
                   073FE1
865       P:0002EA 00000C              RTS                             ;
866    
867       P:0002EB 08F4BB  SET_VCLKS   MOVEP   #WS5,X:BCR              ; add wait states
                   07BFE1
868       P:0002ED 332000              MOVE    #VCLK,R3                ; clock voltages
869       P:0002EE 64F400              MOVE    #CLK_AB,R4              ; clock DAC registers
                   FFFF90
870       P:0002F0 061080              DO      #$10,ENDSETV            ; set clock voltages
                   0002F3


Motorola DSP56300 Assembler  Version 6.3.4   07-12-14  11:55:19  gcam_512ft.asm  Page 19



871       P:0002F2 44DB00              MOVE    X:(R3)+,X0              ;
872       P:0002F3 4C5C00              MOVE    X0,Y:(R4)+              ;
873       P:0002F4 08F4BB  ENDSETV     MOVEP   #WS,X:BCR               ; re-set wait states
                   073FE1
874       P:0002F6 00000C              RTS
875    
876                        ;*****************************************************************************
877                        ;   TEMP MONITOR ADC START AND CONVERT
878                        ;*****************************************************************************
879       P:0002F7 012D20  TEMP_READ   BSET    #$0,X:PDRD              ; turn on temp sensor
880    
881                        ; -------------------------------------------------------------------
882                        ; test  - 30 oct 07 RAT
883                        ; set OFFSET_R to zero during idle periods.
884    
885       P:0002F8 08F4BB              MOVEP   #WS5,X:BCR              ; add wait states
                   07BFE1
886       P:0002FA 44F400              MOVE    #DZ+0200,X0             ; temperature bias voltage (OFFSET_R is
 first)
                   0010C8
887       P:0002FC 64F400              MOVE    #SIG_AB,R4              ; bias DAC registers
                   FFFF88
**** 888 [gcam_512ft.asm 824]: WARNING --- Pipeline stall reading register written in instruction at address: 
P:0002FC (X data move field)
888       P:0002FE 4C6400              MOVE    X0,Y:(R4)               ;
889       P:0002FF 08F4BB              MOVEP   #WS,X:BCR               ; re-set wait states
                   073FE1
890    
891                        ;--------------------------------------------------------------------
892    
893       P:000301 07F409              MOVEP   #$20,X:TCPR1            ; set timer compare value
                   000020
894       P:000303 0BF080              JSR     M_TIMER                 ; wait for output to settle
                   00032C
895    
896       P:000305 08F4BB              MOVEP   #WS3,X:BCR              ; set wait states for ADC
                   077FE1
897       P:000307 07B080              MOVEP   X:TCLKS,Y:<<SEQREG      ; assert /CONVST
                   000044
898       P:000309 0604A0              REP     #$4                     ;
899       P:00030A 000000              NOP                             ;
900       P:00030B 07B080              MOVEP   X:(TCLKS+1),Y:<<SEQREG  ; deassert /CONVST and wait
                   000045
901       P:00030D 0650A0              REP     #$50                    ;
902       P:00030E 000000              NOP                             ;
903    
904       P:00030F 044C22              MOVEP   Y:<<ADC_B,A1            ; read ADC2
905       P:000310 45F400              MOVE    #>$FFFF,X1              ; prepare 16-bit mask   - RAT
                   00FFFF
906       P:000312 200066              AND     X1,A1                   ; get all 16 bits
907       P:000313 012D00              BCLR    #$0,X:PDRD              ; turn off temp sensor
908       P:000314 0BCC4D              BCHG    #$D,A1                  ; 2complement to binary
909       P:000315 08F4BB              MOVEP   #WS,X:BCR               ; re-set wait states
                   073FE1


Motorola DSP56300 Assembler  Version 6.3.4   07-12-14  11:55:19  gcam_512ft.asm  Page 20



910       P:000317 541100              MOVE    A1,X:TEMP               ;
911       P:000318 00000C              RTS                             ;
912    
913       P:000319 08F4BB  TEMP_SET    MOVEP   #WS5,X:BCR              ; add wait states
                   07BFE1
914       P:00031B 000000              NOP                             ;
915    
916                        ; -------------------------------------------------------------------
917                        ; test  - 23 oct 07 RAT
918                        ; restore OFFSET_R value during imaging
919    
920       P:00031C 331800              MOVE    #VBIAS,R3               ; bias voltages (OFFSET_R is first)
921       P:00031D 64F400              MOVE    #SIG_AB,R4              ; bias DAC registers
                   FFFF88
**** 922 [gcam_512ft.asm 858]: WARNING --- Pipeline stall reading register written in instruction at address: 
P:00031C (X data move field)
922       P:00031F 44E300              MOVE    X:(R3),X0               ;
923       P:000320 4C6400              MOVE    X0,Y:(R4)               ;
924    
925                        ;--------------------------------------------------------------------
926    
927    
928       P:000321 07B08A              MOVEP   X:TEC,Y:<<TEC_REG       ; set TEC DAC
                   00001A
929       P:000323 08F4BB              MOVEP   #WS,X:BCR               ; re-set wait states
                   073FE1
930       P:000325 00000C              RTS
931    
932                        ;*****************************************************************************
933                        ;   MILLISECOND AND MICROSECOND TIMER MODULE
934                        ;*****************************************************************************
935       P:000326 010F20  U_TIMER     BSET    #$0,X:TCSR0             ; start timer
936       P:000327 014F20              BTST    #$0,X:TCSR0             ; delay for flag update
937    
938       P:000328 018F95              JCLR    #$15,X:TCSR0,*          ; wait for TCF flag
                   000328
939       P:00032A 010F00              BCLR    #$0,X:TCSR0             ; stop timer, clear flag
940       P:00032B 00000C              RTS                             ; flags update during RTS
941    
942       P:00032C 010B20  M_TIMER     BSET    #$0,X:TCSR1             ; start timer
943       P:00032D 014F20              BTST    #$0,X:TCSR0             ; delay for flag update
944    
945       P:00032E 018B95              JCLR    #$15,X:TCSR1,*          ; wait for TCF flag
                   00032E
946       P:000330 010B00              BCLR    #$0,X:TCSR1             ; stop timer, clear flag
947       P:000331 00000C              RTS                             ; flags update during RTS
948    
949                        ;*****************************************************************************
950                        ;   SIGNAL-PROCESSING GAIN MODULE
951                        ;*****************************************************************************
952       P:000332 0A12A0  SET_GAIN    JSET    #$0,X:GAIN,HI_GAIN      ;
                   000335
953       P:000334 012D01              BCLR    #$1,X:PDRD              ; set gain=0
954       P:000335 0A1280  HI_GAIN     JCLR    #$0,X:GAIN,END_GAIN     ;


Motorola DSP56300 Assembler  Version 6.3.4   07-12-14  11:55:19  gcam_512ft.asm  Page 21



                   000338
955       P:000337 012D21              BSET    #$1,X:PDRD              ; set gain=1
956       P:000338 00000C  END_GAIN    RTS                             ;
957    
958                        ;*****************************************************************************
959                        ;   SIGNAL-PROCESSING DUAL-SLOPE TIME MODULE
960                        ;*****************************************************************************
961       P:000339 07F00D  SET_USEC    MOVEP   X:USEC,X:TCPR0          ; timer compare value
                   000013
962       P:00033B 00000C  END_USEC    RTS                             ;
963    
964                        ;*****************************************************************************
965                        ;   SELECT SERIAL CLOCK SEQUENCE (IE OUTPUT AMPLIFIER)
966                        ;*****************************************************************************
967       P:00033C 569400  SET_SCLKS   MOVE    X:OPCH,A                ; 0x1=right 0x2=left
968       P:00033D 44F400  RIGHT_AMP   MOVE    #>$1,X0                 ; 0x3=both  0x4=all
                   000001
969       P:00033F 200045              CMP     X0,A                    ;
970       P:000340 0AF0A2              JNE     LEFT_AMP                ;
                   00034A
971       P:000342 46F400              MOVE    #>SCLKS_R,Y0            ; serial clock sequences
                   000070
972       P:000344 47F400              MOVE    #>SCLKS_FLR,Y1          ; serial flush sequences
                   000080
973       P:000346 75F400              MOVE    #PIX+1,N5               ; pointer to start of data
                   000301
974       P:000348 08F4AD              MOVEP   #>$0,X:DCO0             ; DMA counter
                   000000
975       P:00034A 44F400  LEFT_AMP    MOVE    #>$2,X0                 ;
                   000002
976       P:00034C 200045              CMP     X0,A                    ;
977       P:00034D 0AF0A2              JNE     BOTH_AMP                ;
                   000357
978       P:00034F 46F400              MOVE    #>SCLKS_L,Y0            ;
                   000078
979       P:000351 47F400              MOVE    #>SCLKS_FLL,Y1          ;
                   000088
980       P:000353 75F400              MOVE    #PIX,N5                 ;
                   000300
981       P:000355 08F4AD              MOVEP   #>$0,X:DCO0             ;
                   000000
982       P:000357 44F400  BOTH_AMP    MOVE    #>$3,X0                 ;
                   000003
983       P:000359 200045              CMP     X0,A                    ;
984       P:00035A 0AF0A2              JNE     END_AMP                 ;
                   000364
985       P:00035C 46F400              MOVE    #>SCLKS_B,Y0            ;
                   000090
986       P:00035E 47F400              MOVE    #>SCLKS_FLB,Y1          ;
                   000098
987       P:000360 75F400              MOVE    #PIX,N5                 ;
                   000300
988       P:000362 08F4AD              MOVEP   #>$1,X:DCO0             ;
                   000001


Motorola DSP56300 Assembler  Version 6.3.4   07-12-14  11:55:19  gcam_512ft.asm  Page 22



989       P:000364 463000  END_AMP     MOVE    Y0,X:SCLKS              ;
990       P:000365 473100              MOVE    Y1,X:SCLKS_FL           ;
991       P:000366 00000C              RTS                             ;
992    
993                        ;*****************************************************************************
994                        ;   CMD.ASM -- ROUTINE TO INTERPRET AN 8-BIT COMMAND + COMPLEMENT
995                        ;*****************************************************************************
996                        ; Each command word is sent as two bytes -- the LSB has the command
997                        ; and the MSB has the complement.
998    
999       P:000367 568000  CMD_FIX     MOVE    X:CMD,A                 ; extract cmd[7..0]
1000      P:000368 0140C6              AND     #>$FF,A                 ; and put in X1
                   0000FF
1001      P:00036A 218500              MOVE    A1,X1                   ;
1002      P:00036B 568000              MOVE    X:CMD,A                 ; extract cmd[15..8]
1003      P:00036C 0C1ED0              LSR     #$8,A                   ; complement
1004      P:00036D 57F417              NOT     A   #>$1,B              ; and put in A1
                   000001
1005      P:00036F 0140C6              AND     #>$FF,A                 ;
                   0000FF
1006      P:000371 0C1E5D              ASL     X1,B,B                  ;
1007      P:000372 200065              CMP     X1,A                    ; compare X1 and A1
1008      P:000373 0AF0AA              JEQ     CMD_OK                  ;
                   000377
1009      P:000375 20001B  CMD_NG      CLR     B                       ; cmd word no good
1010      P:000376 000000              NOP                             ;
1011      P:000377 550000  CMD_OK      MOVE    B1,X:CMD                ; cmd word OK
1012      P:000378 000000              NOP                             ;
1013      P:000379 00000C  END_CMD     RTS                             ;
1014   
1015                                   END

0    Errors
2    Warnings


