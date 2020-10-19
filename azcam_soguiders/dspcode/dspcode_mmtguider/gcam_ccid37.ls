
Motorola DSP56300 Assembler  Version 6.3.4   08-09-10  15:22:59  gcam_ccid37.asm  Page 1



1                          ;*****************************************************************************
2                          ;   GCAM.ASM -- DSP-BASED CCD CONTROLLER PROGRAM
3                          ;*****************************************************************************
4                              PAGE    110,60,1,1
5                              TABS    4
6                          ;*****************************************************************************
7                          ;   Code modified for the CCID-37 22 August 2006 - R. Tucker
8                          ;*****************************************************************************
9      
10                         ;
11                         ;*****************************************************************************
12                         ;   DEFINITIONS & POINTERS
13                         ;*****************************************************************************
14        000100           START       EQU     $000100             ; program start location
15        000006           SEQ         EQU     $000006             ; seq fragment length
16        001000           DZ          EQU     $001000             ; DAC zero volt offset
17     
18        073FE1           WS          EQU     $073FE1             ; periph wait states
19        073FE1           WS1         EQU     $073FE1             ; 1 PERIPH 1 SRAM 31 EPROM
20        077FE1           WS3         EQU     $077FE1             ; 3 PERIPH 1 SRAM 31 EPROM
21        07BFE1           WS5         EQU     $07BFE1             ; 5 PERIPH 1 SRAM 31 EPROM
22     
23                         ;*****************************************************************************
24                         ;   COMPILE-TIME OPTIONS
25                         ;*****************************************************************************
26     
27        000001           VERSION         EQU     $1              ;
28        000000           RDMODE          EQU     $0              ;
29        00020A           HOLD_P          EQU     $020A           ; P clock timing $20A=40us
30        00007C           HOLD_FT         EQU     $007C           ; FT clock timing $7C=10us xfer
31        00007C           HOLD_FL         EQU     $007C           ; FL clock timimg
32        000005           HOLD_S          EQU     $0005           ; S clock timing (was 5)
33        000006           HOLD_RG         EQU     $0006           ; RG timing
34        001F40           HOLD_PL         EQU     $1F40           ; pre-line settling (1F40=100us)
35        000020           HOLD_FF         EQU     $0020           ; FF clock timimg
36        001F40           HOLD_IPC        EQU     $1F40           ; IPC clock timing ($1F40=100us)
37        00000F           HOLD_SIG        EQU     $000F           ; preamp settling time
38        00000F           HOLD_ADC        EQU     $000F           ; pre-sample settling (was F)
39        000213           INIT_NROWS      EQU     $213            ; $200=(512)
40        000238           INIT_NCOLS      EQU     $238            ; $204=(512)+4
41        000400           INIT_NFT        EQU     $400            ; $400=1024
42                         INIT_NFLUSH
43        000400           INIT_NFLUSH     EQU     $400            ; $400=1024
44        000001           INIT_NCH        EQU     $1              ;
45        000002           INIT_VBIN       EQU     $2              ;
46        000002           INIT_HBIN       EQU     $2              ;
47        000000           INIT_VSKIP      EQU     $0              ;
48        000000           INIT_HSKIP      EQU     $0              ;
49        000000           INIT_GAIN       EQU     $0              ; 0=LOW 1=HIGH
50        0000C8           INIT_USEC       EQU     $C8             ;
51        000002           INIT_OPCH       EQU     $2              ; 0=CH_A 1=CH_B
52        000002           INIT_SCLKS      EQU     $2              ; 1=LEFT 2=RIGHT
53        000000           INIT_PID        EQU     $0              ; FLAG $0=OFF $1=ON
54        000000           INIT_LINK       EQU     $0              ; 0=wire 1=single_fiber


Motorola DSP56300 Assembler  Version 6.3.4   08-09-10  15:22:59  gcam_ccid37.asm  Page 2



55     
56                         ;*****************************************************************************
57                         ;   EXTERNAL PERIPHERAL DEFINITIONS (GUIDER CAMERA)
58                         ;*****************************************************************************
59        FFFF80           SEQREG      EQU     $FFFF80             ; external CCD clock register
60        FFFF81           ADC_A       EQU     $FFFF81             ; A/D converter #1
61        FFFF82           ADC_B       EQU     $FFFF82             ; A/D converter #2
62        FFFF85           TXREG       EQU     $FFFF85             ; Transmit Data Register
63        FFFF86           RXREG       EQU     $FFFF86             ; Receive Data register
64        FFFF88           SIG_AB      EQU     $FFFF88             ; bias voltages A+B
65        FFFF90           CLK_AB      EQU     $FFFF90             ; clock voltages A+B
66        FFFF8A           TEC_REG     EQU     $FFFF8A             ; TEC register
67     
68                         ;*****************************************************************************
69                         ;   INTERNAL PERIPHERAL DEFINITIONS (DSP563000)
70                         ;*****************************************************************************
71        FFFFFF           IPRC        EQU     $FFFFFF             ; Interrupt priority register (core)
72        FFFFFE           IPRP        EQU     $FFFFFE             ; Interrupt priority register (periph)
73        FFFFFD           PCTL        EQU     $FFFFFD             ; PLL control register
74        FFFFFB           BCR         EQU     $FFFFFB             ; Bus control register (wait states)
75        FFFFF9           AAR0        EQU     $FFFFF9             ; Address attribute register 0
76        FFFFF8           AAR1        EQU     $FFFFF8             ; Address attribute register 1
77        FFFFF7           AAR2        EQU     $FFFFF7             ; Address attribute register 2
78        FFFFF6           AAR3        EQU     $FFFFF6             ; Address attribute register 3
79        FFFFF5           IDR         EQU     $FFFFF5             ; ID Register
80        FFFFC9           PDRB        EQU     $FFFFC9             ; Port B (HOST) GPIO data
81        FFFFC8           PRRB        EQU     $FFFFC8             ; Port B (HOST) GPIO direction
82        FFFFC4           PCRB        EQU     $FFFFC4             ; Port B (HOST) control register
83        FFFFBF           PCRC        EQU     $FFFFBF             ; Port C (ESSI_0) control register
84        FFFFBE           PRRC        EQU     $FFFFBE             ; Port C (ESSI_0) direction
85        FFFFBD           PDRC        EQU     $FFFFBD             ; Port C (ESSI_0) data
86        FFFFBC           TXD         EQU     $FFFFBC             ; ESSI0 Transmit Data Register 0
87        FFFFB8           RXD         EQU     $FFFFB8             ; ESSI0 Receive Data Register
88        FFFFB7           SSISR       EQU     $FFFFB7             ; ESSI0 Status Register
89        FFFFB6           CRB         EQU     $FFFFB6             ; ESSI0 Control Register B
90        FFFFB5           CRA         EQU     $FFFFB5             ; ESSI0 Control Register A
91        FFFFAF           PCRD        EQU     $FFFFAF             ; Port D (ESSI_1) control register
92        FFFFAE           PRRD        EQU     $FFFFAE             ; Port D (ESSI_1) direction
93        FFFFAD           PDRD        EQU     $FFFFAD             ; Port D (ESSI_1) data
94        FFFF9F           PCRE        EQU     $FFFF9F             ; Port E (SCI) control register
95        FFFF9E           PRRE        EQU     $FFFF9E             ; Port E (SCI) data direction
96        FFFF9D           PDRE        EQU     $FFFF9D             ; Port E (SCI) data
97        FFFF8F           TCSR0       EQU     $FFFF8F             ; TIMER0 Control/Status Register
98        FFFF8E           TLR0        EQU     $FFFF8E             ; TIMER0 Load Reg
99        FFFF8D           TCPR0       EQU     $FFFF8D             ; TIMER0 Compare Register
100       FFFF8C           TCR0        EQU     $FFFF8C             ; TIMER0 Count Register
101       FFFF8B           TCSR1       EQU     $FFFF8B             ; TIMER1 Control/Status Register
102       FFFF8A           TLR1        EQU     $FFFF8A             ; TIMER1 Load Reg
103       FFFF89           TCPR1       EQU     $FFFF89             ; TIMER1 Compare Register
104       FFFF88           TCR1        EQU     $FFFF88             ; TIMER1 Count Register
105       FFFF87           TCSR2       EQU     $FFFF87             ; TIMER2 Control/Status Register
106       FFFF86           TLR2        EQU     $FFFF86             ; TIMER2 Load Reg
107       FFFF85           TCPR2       EQU     $FFFF85             ; TIMER2 Compare Register
108       FFFF84           TCR2        EQU     $FFFF84             ; TIMER2 Count Register


Motorola DSP56300 Assembler  Version 6.3.4   08-09-10  15:22:59  gcam_ccid37.asm  Page 3



109       FFFF83           TPLR        EQU     $FFFF83             ; TIMER Prescaler Load Register
110       FFFF82           TPCR        EQU     $FFFF82             ; TIMER Prescalar Count Register
111       FFFFEF           DSR0        EQU     $FFFFEF             ; DMA source address
112       FFFFEE           DDR0        EQU     $FFFFEE             ; DMA dest address
113       FFFFED           DCO0        EQU     $FFFFED             ; DMA counter
114       FFFFEC           DCR0        EQU     $FFFFEC             ; DMA control register
115    
116                        ;*****************************************************************************
117                        ;   REGISTER DEFINITIONS (GUIDER CAMERA)
118                        ;*****************************************************************************
119       000000           CMD         EQU     $000000             ; command word/flags from host
120       000001           OPFLAGS     EQU     $000001             ; operational flags
121       000002           NROWS       EQU     $000002             ; number of rows to read
122       000003           NCOLS       EQU     $000003             ; number of columns to read
123       000004           NFT         EQU     $000004             ; number of rows for frame transfer
124       000005           NFLUSH      EQU     $000005             ; number of columns to flush
125       000006           NCH         EQU     $000006             ; number of output channels (amps)
126       000007           NPIX        EQU     $000007             ; (not used)
127       000008           VBIN        EQU     $000008             ; vertical (parallel) binning
128       000009           HBIN        EQU     $000009             ; horizontal (serial) binning
129       00000A           VSKIP       EQU     $00000A             ; V prescan or offset (rows)
130       00000B           HSKIP       EQU     $00000B             ; H prescan or offset (columns)
131       00000C           VSUB        EQU     $00000C             ; V subraster size
132       00000D           HSUB        EQU     $00000D             ; H subraster size
133       00000E           NEXP        EQU     $00000E             ; number of exposures (not used)
134       00000F           NSHUFFLE    EQU     $00000F             ; (not used)
135    
136       000010           EXP_TIME    EQU     $000010             ; CCD integration time(r)
137       000011           TEMP        EQU     $000011             ; Temperature sensor reading(s)
138       000012           GAIN        EQU     $000012             ; Sig_proc gain
139       000013           USEC        EQU     $000013             ; Sig_proc sample time
140       000014           OPCH        EQU     $000014             ; Output channel
141       000015           HDIR        EQU     $000015             ; serial clock direction
142       000016           LINK        EQU     $000016             ; 0=wire 1=single_fiber
143    
144       000030           SCLKS       EQU     $000030             ; serial clocks
145       000031           SCLKS_FL    EQU     $000031             ; serial clocks flush
146       000032           INT_X       EQU     $000032             ; reset and integrate clocks
147       000033           NDMA        EQU     $000033             ; (not used)
148    
149       000018           VBIAS       EQU     $000018             ; bias voltages
150       000020           VCLK        EQU     $000020             ; clock voltages
151       00001A           TEC         EQU     $00001A             ; TEC current
152       000300           PIX         EQU     $000300             ; start address for data storage
153    
154                        ;*****************************************************************************
155                        ;   SEQUENCE FRAGMENT STARTING ADDRESSES (& OTHER POINTERS)
156                        ;*****************************************************************************
157       000040           MPP         EQU     $0040               ; MPP/hold state
158       000042           IPCLKS      EQU     $0042               ; input clamp
159       000044           TCLKS       EQU     $0044               ; Temperature monitor clocks
160       000048           PCLKS_FT    EQU     $0048               ; parallel frame transfer
161       000050           PCLKS_RD    EQU     $0050               ; parallel read-out transfer
162       000058           PCLKS_FL    EQU     $0058               ; parallel flush transfer


Motorola DSP56300 Assembler  Version 6.3.4   08-09-10  15:22:59  gcam_ccid37.asm  Page 4



163       000060           INT_L       EQU     $0060               ; reset and first integration
164       000068           INT_H       EQU     $0068               ; second integration and A/D
165       000070           SCLKS_R     EQU     $0070               ; serial clocks shift right
166       000080           SCLKS_FLR   EQU     $0080               ; serial clocks flush right
167       000078           SCLKS_L     EQU     $0078               ; serial clocks shift left
168       000088           SCLKS_FLL   EQU     $0088               ; serial clocks flush left
169       000090           SCLKS_B     EQU     $0090               ; serial clocks both
170       000098           SCLKS_FLB   EQU     $0098               ; serial clocks flush both
171       0000A0           SCLKS_FF    EQU     $00A0               ; serial clocks fast flush
172    
173                        ;*******************************************************************************
174                        ;   INITIALIZE X MEMORY AND DEFINE PERIPHERALS
175                        ;*******************************************************************************
176       X:000000                     ORG     X:CMD               ; CCD control information
177       X:000000                     DC      $0                  ; CMD/FLAGS
178       X:000001                     DC      $0                  ; OPFLAGS
179       X:000002                     DC      INIT_NROWS          ; NROWS
180       X:000003                     DC      INIT_NCOLS          ; NCOLS
181       X:000004                     DC      INIT_NFT            ; NFT
182       X:000005                     DC      INIT_NFLUSH         ; NFLUSH
183       X:000006                     DC      INIT_NCH            ; NCH
184       X:000007                     DC      $1                  ; NPIX (not used)
185       X:000008                     DC      INIT_VBIN           ; VBIN
186       X:000009                     DC      INIT_HBIN           ; HBIN
187       X:00000A                     DC      INIT_VSKIP          ; VSKIP ($0)
188       X:00000B                     DC      INIT_HSKIP          ; HSKIP ($0)
189       X:00000C                     DC      $0                  ; VSUB
190       X:00000D                     DC      $0                  ; HSUB
191       X:00000E                     DC      $1                  ; NEXP (not used)
192       X:00000F                     DC      $0                  ; (not used)
193    
194       X:000010                     ORG     X:EXP_TIME
195       X:000010                     DC      $3E8                ; EXP_TIME
196       X:000011                     DC      $0                  ; TEMP
197       X:000012                     DC      INIT_GAIN           ; GAIN
198       X:000013                     DC      INIT_USEC           ; USEC SAMPLE TIME
199       X:000014                     DC      INIT_OPCH           ; OUTPUT CHANNEL
200       X:000015                     DC      INIT_SCLKS          ; HORIZ DIRECTION
201       X:000016                     DC      INIT_LINK           ; SERIAL LINK
202    
203                        ;*****************************************************************************
204                        ;   CCD57 SET DAC VOLTAGES  DEFAULTS:  OD=20V  RD=8V  OG=ABG=-6V
205                        ;   PCLKS=+3V -9V SCLKS=+2V -8V RG=+3V -9V
206                        ;   CCID37 SET DAC VOLTAGES  DEFAULTS:  OD=18V  RD=10V  OG=-2V
207                        ;   PCLKS=+4V -6V SCLKS=+4V -4V RG=+8V -2V
208                        ;*****************************************************************************
209    
210       X:000018                     ORG     X:VBIAS
211       X:000018                     DC      (DZ-0050)           ; OFFSET_R (5mV/DN)
212       X:000019                     DC      (DZ-0050)           ; OFFSET_L
213       X:00001A                     DC      (DZ+0010)           ; B7
214       X:00001B                     DC      (DZ-0400)           ; OG  voltage
215       X:00001C                     DC      (DZ+1000)           ; B5 (10 mV/DN)
216       X:00001D                     DC      (DZ+1000)           ; RD


Motorola DSP56300 Assembler  Version 6.3.4   08-09-10  15:22:59  gcam_ccid37.asm  Page 5



217       X:00001E                     DC      (DZ+1800)           ; OD_R
218       X:00001F                     DC      (DZ+1800)           ; OD_L
219    
220       X:000020                     ORG     X:VCLK
221       X:000020                     DC      (DZ-0000)           ; IPC- [V0] voltage (5mV/DN)    (0v)
222       X:000021                     DC      (DZ+1000)           ; IPC+ [V1]         (+5v)
223       X:000022                     DC      (DZ-0400)           ; RG-  [V2]         (-2v)
224       X:000023                     DC      (DZ+1600)           ; RG+  [V3]         (+8v)
225       X:000024                     DC      (DZ-0800)           ; S-   [V4]         (-4v)
226       X:000025                     DC      (DZ+0800)           ; S+   [V5]         (+4v)
227       X:000026                     DC      (DZ-1800)           ; DG-  [V6]         (-9v)
228       X:000027                     DC      (DZ+0600)           ; DG+  [V7]         (+3v)
229       X:000028                     DC      (DZ-1800)           ; TG-  [V8]         (-9v)
230       X:000029                     DC      (DZ+0600)           ; TG+  [V9]         (+3v)
231       X:00002A                     DC      (DZ-1200)           ; P1-  [V10]            (-6v)
232       X:00002B                     DC      (DZ+0800)           ; P1+  [V11]            (+4v)
233       X:00002C                     DC      (DZ-1200)           ; P2-  [V12]            (-6v)
234       X:00002D                     DC      (DZ+0800)           ; P2+  [V13]            (+4v)
235       X:00002E                     DC      (DZ-1200)           ; P3-  [V14]            (-6v)
236       X:00002F                     DC      (DZ+0800)           ; P3+  [V15]            (+4v)
237    
238                        ;*****************************************************************************
239                        ;   INITIALIZE X MEMORY
240                        ;*****************************************************************************
241                        ;        R2L   _______________  ________________ R1L
242                        ;        R3L   ______________ || _______________ R3R
243                        ;        DG    _____________ |||| ______________ R2R
244                        ;        SPARE ____________ |||||| _____________ R1R
245                        ;        ST1   ___________ |||||||| ____________ RG
246                        ;        ST2   __________ |||||||||| ___________ IPC
247                        ;        ST3   _________ |||||||||||| __________ FINT+
248                        ;        IM1   ________ |||||||||||||| _________ FINT-
249                        ;        IM2   _______ |||||||||||||||| ________ FRST
250                        ;        IM3   ______ |||||||||||||||||| _______ CONVST
251                        ;                    ||||||||||||||||||||
252    
253       X:000040                      ORG X:MPP              ; reset/hold state (no MPP mode for CCID-37)
254       X:000040                     DC  %000001001000011011000011
255    
256       X:000042                     ORG X:IPCLKS            ; input clamp
257       X:000042                     DC  %000001001000011011010011
258       X:000043                     DC  %000001001000011011000011
259    
260       X:000044                     ORG X:TCLKS             ; read temp monitor
261       X:000044                     DC  %000001001000011011000010
262       X:000045                     DC  %000001001000011011000011
263    
264       X:000048                     ORG X:PCLKS_FT          ; frame transfer P3-P2-P1-P3
265       X:000048                     DC  %000001001000011011000011
266       X:000049                     DC  %000011011000011011000011
267       X:00004A                     DC  %000010010000011011000011
268       X:00004B                     DC  %000010110100011011000011
269       X:00004C                     DC  %000000100100011011000011
270       X:00004D                     DC  %000001101100011011000011


Motorola DSP56300 Assembler  Version 6.3.4   08-09-10  15:22:59  gcam_ccid37.asm  Page 6



271    
272       X:000050                     ORG X:PCLKS_RD          ; parallel transfer P3-P2-P1-P3
273       X:000050                     DC  %000001001000011011010011
274       X:000051                     DC  %000001011000011011010011
275       X:000052                     DC  %000001010000011011000011
276       X:000053                     DC  %000001010100011011000011
277       X:000054                     DC  %000001000100011011000011
278       X:000055                     DC  %000001001100011011000011
279    
280                        ; ....................................................................
281                        ; original
282    
283                        ;            ORG X:PCLKS_FL          ; parallel flush P3-P2-P1-P3
284                        ;            DC  %000001001000011011000011
285                        ;            DC  %000011011000011011000011
286                        ;            DC  %000010010000011011000011
287                        ;            DC  %000010110100011011000011
288                        ;            DC  %000000100100011011000011
289                        ;            DC  %000001101100011011000011
290    
291                        ; ....................................................................
292                        ; test
293    
294       X:000058                     ORG X:PCLKS_FL          ; parallel flush P3-P2-P1-P3
295       X:000058                     DC  %000001001000011011000011
296       X:000059                     DC  %000011011000011111100011
297       X:00005A                     DC  %000010010000011111100011
298       X:00005B                     DC  %000010110100011111100011
299       X:00005C                     DC  %000000100100011111100011
300       X:00005D                     DC  %000001101100011011000011
301    
302    
303                        ; ....................................................................
304    
305       X:000060                     ORG X:INT_L             ; reset and first integration
306       X:000060                     DC  %000001001000011011100011   ; RG ON  FRST ON
307       X:000061                     DC  %000001001000011011000011   ; RG OFF
308       X:000062                     DC  %000001001000011011000001   ; FRST OFF
309       X:000063                     DC  %000001001000011011001001   ; FINT+ ON
310       X:000064                     DC  %000001001000011011000001   ; FINT+ OFF
311    
312       X:000068                     ORG X:INT_H             ; second integration and A to D
313       X:000068                     DC  %000001001000011011000101   ; FINT- ON
314       X:000069                     DC  %000001001000011011000001   ; FINT- OFF
315       X:00006A                     DC  %000001001000011011000000   ; /CONVST ON
316       X:00006B                     DC  %000001001000011011000001   ; /CONVST OFF
317       X:00006C                     DC  %000001001000011011100011   ; FRST ON RG ON
318    
319       X:000070                     ORG X:SCLKS_R           ; serial shift (right) S1-S2-S3-S1
320       X:000070                     DC  %000001001000011011000001
321       X:000071                     DC  %000001001000010010000001
322       X:000072                     DC  %000001001000110110000001
323       X:000073                     DC  %000001001000100100000001
324       X:000074                     DC  %000001001000101101000001


Motorola DSP56300 Assembler  Version 6.3.4   08-09-10  15:22:59  gcam_ccid37.asm  Page 7



325       X:000075                     DC  %000001001000001001000001
326    
327       X:000080                     ORG X:SCLKS_FLR         ; serial flush (right) S1-S2-S3-S1
328       X:000080                     DC  %000001001000011011100011
329       X:000081                     DC  %000001001000010010100011
330       X:000082                     DC  %000001001000110110100011
331       X:000083                     DC  %000001001000100100100011
332       X:000084                     DC  %000001001000101101100011
333       X:000085                     DC  %000001001000001001100011
334    
335       X:000078                     ORG X:SCLKS_L           ; serial shift (left) S1-S3-S2-S1
336       X:000078                     DC  %000001001000101101000001
337       X:000079                     DC  %000001001000100100000001
338       X:00007A                     DC  %000001001000110110000001
339       X:00007B                     DC  %000001001000010010000001
340       X:00007C                     DC  %000001001000011011000001
341       X:00007D                     DC  %000001001000001001000001
342    
343       X:000088                     ORG X:SCLKS_FLL         ; serial flush (left) S1-S3-S2-S1
344       X:000088                     DC  %000001001000101101100011
345       X:000089                     DC  %000001001000100100100011
346       X:00008A                     DC  %000001001000110110100011
347       X:00008B                     DC  %000001001000010010100011
348       X:00008C                     DC  %000001001000011011100011
349       X:00008D                     DC  %000001001000001001100011
350    
351       X:000090                     ORG X:SCLKS_B           ; serial shift (both)
352       X:000090                     DC  %000001001000101011000001
353       X:000091                     DC  %000001001000100010000001
354       X:000092                     DC  %000001001000110110000001
355       X:000093                     DC  %000001001000010100000001
356       X:000094                     DC  %000001001000011101000001
357       X:000095                     DC  %000001001000001001000001
358    
359       X:000098                     ORG X:SCLKS_FLB         ; serial flush (both)
360       X:000098                     DC  %000001001000101011100011
361       X:000099                     DC  %000001001000100010100011
362       X:00009A                     DC  %000001001000110110100011
363       X:00009B                     DC  %000001001000010100100011
364       X:00009C                     DC  %000001001000011101100011
365       X:00009D                     DC  %000001001000001001100011
366    
367       X:0000A0                     ORG X:SCLKS_FF          ; serial flush (fast) DG
368       X:0000A0                     DC  %000001001001011011100011
369       X:0000A1                     DC  %000001001001000000100011
370       X:0000A2                     DC  %000001001000000000100011
371       X:0000A3                     DC  %000001001000011011100011
372       X:0000A4                     DC  %000001001000011011100011   ; dummy code
373       X:0000A5                     DC  %000001001000011011100011   ; dummy code
374    
375    
376                        ;*******************************************************************************
377                        ;   GENERAL COMMENTS
378                        ;*******************************************************************************


Motorola DSP56300 Assembler  Version 6.3.4   08-09-10  15:22:59  gcam_ccid37.asm  Page 8



379                        ; Hardware RESET causes download from serial port (code in EPROM)
380                        ; R0 is a pointer to sequence fragments
381                        ; R1 is a pointer used by send/receive routines
382                        ; R2 is a pointer to the current data location
383                        ; See dspdvr.h for command and opflag definitions
384                        ;*******************************************************************************
385                        ;   INITIALIZE INTERRUPT VECTORS
386                        ;*******************************************************************************
387       P:000000                     ORG     P:$0000
388       P:000000 0C0100              JMP     START
389                        ;*******************************************************************************
390                        ;   MAIN PROGRAM
391                        ;*******************************************************************************
392       P:000100                     ORG     P:START
393       P:000100 0003F8  SET_MODE    ORI     #$3,MR                  ; mask all interrupts
394       P:000101 08F4B6              MOVEP   #$FFFC21,X:AAR3         ; PERIPH $FFF000--$FFFFFF
                   FFFC21
395       P:000103 08F4B8              MOVEP   #$D00909,X:AAR1         ; EEPROM $D00000--$D07FFF 32K
                   D00909
396       P:000105 08F4B9              MOVEP   #$000811,X:AAR0         ; SRAM X $000000--$00FFFF 64K
                   000811
397       P:000107 08F4BB              MOVEP   #WS,X:BCR               ; Set periph wait states
                   073FE1
398       P:000109 0505A0              MOVE    #SEQ-1,M0               ; Set sequencer address modulus
399    
400                        PORTB_SETUP
401       P:00010A 08F484  PORTB_SETUP MOVEP   #>$1,X:PCRB             ; set PB[15..0] GPIO
                   000001
402    
403                        PORTD_SETUP
404       P:00010C 07F42F  PORTD_SETUP MOVEP   #>$0,X:PCRD             ; GPIO PD0=TM PD1=GAIN
                   000000
405       P:00010E 07F42E              MOVEP   #>$3,X:PRRD             ; PD2=/ENRX PD3=/ENTX
                   000003
406       P:000110 07F42D              MOVEP   #>$0,X:PDRD             ; PD4=RXRDY
                   000000
407    
408       P:000112 07F436  SSI_SETUP   MOVEP   #>$032070,X:CRB         ; async, LSB, enable TE RE
                   032070
409       P:000114 07F435              MOVEP   #>$140803,X:CRA         ; 10 Mbps, 16 bit word
                   140803
410       P:000116 07F43F              MOVEP   #>$3F,X:PCRC            ; enable ESSI
                   00003F
411    
412                        PORTE_SETUP
413       P:000118 07F41F  PORTE_SETUP MOVEP   #$0,X:PCRE              ; enable GPIO, disable SCI
                   000000
414       P:00011A 07F41E              MOVEP   #>$1,X:PRRE             ; PE0=SHUTTER
                   000001
415       P:00011C 07F41D              MOVEP   #>$0,X:PDRE             ;
                   000000
416    
417       P:00011E 07F40F  SET_TIMER   MOVEP   #$300A10,X:TCSR0        ; Pulse mode, no prescale
                   300A10


Motorola DSP56300 Assembler  Version 6.3.4   08-09-10  15:22:59  gcam_ccid37.asm  Page 9



418       P:000120 07F40E              MOVEP   #$0,X:TLR0              ; timer reload value
                   000000
419       P:000122 07F00D              MOVEP   X:USEC,X:TCPR0          ; timer compare value
                   000013
420       P:000124 07F40B              MOVEP   #$308A10,X:TCSR1        ; Pulse mode, prescaled
                   308A10
421       P:000126 07F40A              MOVEP   #$0,X:TLR1              ; timer reload value
                   000000
422       P:000128 07F009              MOVEP   X:EXP_TIME,X:TCPR1      ; timer compare value
                   000010
423       P:00012A 07F403              MOVEP   #>$9C3F,X:TPLR          ; timer prescale ($9C3F=1ms 80MHz)
                   009C3F
424    
425       P:00012C 08F4AF  DMA_SETUP   MOVEP   #PIX,X:DSR0             ; set DMA source
                   000300
426       P:00012E 08F4AD              MOVEP   #$0,X:DCO0              ; set DMA counter
                   000000
427       P:000130 0A1680  FIBER       JCLR    #$0,X:LINK,RS485        ; set up optical
                   000136
428       P:000132 08F4AE              MOVEP   #>TXREG,X:DDR0          ; set DMA destination
                   FFFF85
429       P:000134 08F4AC              MOVEP   #>$080255,X:DCR0        ; DMA word xfer, /IRQA, src+1
                   080255
430       P:000136 0A16A0  RS485       JSET    #$0,X:LINK,ENDDP        ; set up RS485
                   00013C
431       P:000138 08F4AE              MOVEP   #>TXD,X:DDR0            ; DMA destination
                   FFFFBC
432       P:00013A 08F4AC              MOVEP   #>$085A51,X:DCR0        ; DMA word xfer, TDE0, src+1
                   085A51
433       P:00013C 000000  ENDDP       NOP                             ;
434    
435       P:00013D 0BF080  INIT_SETUP  JSR     MPPHOLD                 ;
                   0001C3
436       P:00013F 0BF080              JSR     SET_GAIN                ;
                   000335
437       P:000141 0BF080              JSR     SET_DACS                ;
                   0002DA
438       P:000143 0BF080              JSR     SET_SCLKS               ;
                   00033F
439    
440       P:000145 0A1680  WAIT_CMD    JCLR    #$0,X:LINK,WAITB        ; check for cmd ready
                   000149
441       P:000147 01AD84              JCLR    #$4,X:PDRD,ECHO         ; fiber link (single-fiber)
                   000153
442       P:000149 0A16A0  WAITB       JSET    #$0,X:LINK,ENDW         ;
                   00014D
443       P:00014B 01B787              JCLR    #7,X:SSISR,ECHO         ; wire link
                   000153
444       P:00014D 000000  ENDW        NOP                             ;
445    
446       P:00014E 0BF080              JSR     READ16                  ; wait for command word
                   000275
447       P:000150 540000              MOVE    A1,X:CMD                ; cmd in X:CMD
448       P:000151 0BF080              JSR     CMD_FIX                 ; interpret command word


Motorola DSP56300 Assembler  Version 6.3.4   08-09-10  15:22:59  gcam_ccid37.asm  Page 10



                   00036A
449    
450       P:000153 0A0081  ECHO        JCLR    #$1,X:CMD,GET           ; test for DSP_ECHO command
                   00015A
451       P:000155 0BF080              JSR     READ16                  ;
                   000275
452       P:000157 0BF080              JSR     WRITE16                 ;
                   000285
453       P:000159 0A0001              BCLR    #$1,X:CMD               ;
454    
455       P:00015A 0A0082  GET         JCLR    #$2,X:CMD,PUT           ; test for DSP_GET command
                   00015F
456       P:00015C 0BF080              JSR     MEM_SEND                ;
                   0002CD
457       P:00015E 0A0002              BCLR    #$2,X:CMD               ;
458    
459       P:00015F 0A0083  PUT         JCLR    #$3,X:CMD,EXP_START     ; test for DSP_PUT command
                   000164
460       P:000161 0BF080              JSR     MEM_LOAD                ;
                   0002C1
461       P:000163 0A0003              BCLR    #$3,X:CMD               ;
462    
463       P:000164 0A0086  EXP_START   JCLR    #$6,X:CMD,FASTFLUSH     ; test for EXPOSE command
                   000171
464       P:000166 0BF080              JSR     MPPHOLD                 ;
                   0001C3
465       P:000168 62F400              MOVE    #PIX,R2                 ; set data pointer
                   000300
466       P:00016A 07F009              MOVEP   X:EXP_TIME,X:TCPR1      ; timer compare value
                   000010
467       P:00016C 0A012F              BSET    #$F,X:OPFLAGS           ; set exp_in_progress flag
468       P:00016D 0A0006              BCLR    #$6,X:CMD               ;
469    
470       P:00016E 0A0181              JCLR    #$1,X:OPFLAGS,FASTFLUSH ; check for AUTO_FLUSH
                   000171
471       P:000170 0A0024              BSET    #$4,X:CMD               ;
472    
473       P:000171 0A0084  FASTFLUSH   JCLR    #$4,X:CMD,BEAM_ON       ; test for FLUSH command
                   00017A
474       P:000173 0BF080              JSR     FLUSHFRAME              ; fast FLUSH
                   0001EB
475       P:000175 0BF080              JSR     FLUSHFRAME              ; fast FLUSH
                   0001EB
476       P:000177 0BF080              JSR     FLUSHLINE               ; clear serial register
                   0001D0
477       P:000179 0A0004              BCLR    #$4,X:CMD               ;
478    
479       P:00017A 0A0085  BEAM_ON     JCLR    #$5,X:CMD,EXPOSE        ; test for open shutter
                   00017E
480       P:00017C 011D20              BSET    #$0,X:PDRE              ; set SHUTTER
481       P:00017D 0A0005              BCLR    #$5,X:CMD               ;
482    
483       P:00017E 0A018F  EXPOSE      JCLR    #$F,X:OPFLAGS,BEAM_OFF  ; check exp_in_progress flag
                   00018B


Motorola DSP56300 Assembler  Version 6.3.4   08-09-10  15:22:59  gcam_ccid37.asm  Page 11



484       P:000180 0BF080              JSR     MPPHOLD                 ;
                   0001C3
485       P:000182 0BF080              JSR     M_TIMER                 ;
                   00032F
486       P:000184 0A010F              BCLR    #$F,X:OPFLAGS           ; clear exp_in_progress flag
487    
488       P:000185 0A0182  OPT_A       JCLR    #$2,X:OPFLAGS,OPT_B     ; check for AUTO_SHUTTER
                   000188
489       P:000187 0A0027              BSET    #$7,X:CMD               ; prep to close shutter
490       P:000188 0A0184  OPT_B       JCLR    #$4,X:OPFLAGS,BEAM_OFF  ; check for AUTO_READ
                   00018B
491       P:00018A 0A0028              BSET    #$8,X:CMD               ; prep for full readout
492    
493       P:00018B 0A0087  BEAM_OFF    JCLR    #$7,X:CMD,READ_CCD      ; test for shutter close
                   00018F
494       P:00018D 011D00              BCLR    #$0,X:PDRE              ; clear SHUTTER
495       P:00018E 0A0007              BCLR    #$7,X:CMD               ;
496    
497       P:00018F 0A0088  READ_CCD    JCLR    #$8,X:CMD,AUTO_WIPE     ; test for READCCD command
                   0001A5
498       P:000191 0BF080              JSR     FRAME                   ; frame transfer
                   000201
499                        ;           JSR     IPC_CLAMP               ; discharge ac coupling cap
500       P:000193 0BF080              JSR     FLUSHROWS               ; vskip
                   0001E1
501       P:000195 060200              DO      X:NROWS,END_READ        ; read the array
                   0001A2
502       P:000197 0BF080              JSR     FLUSHLINE               ;
                   0001D0
503       P:000199 0BF080              JSR     PARALLEL                ;
                   0001F5
504       P:00019B 0BF080              JSR     FLUSHPIX                ; hskip
                   0001D7
505       P:00019D 0A0120              BSET    #$0,X:OPFLAGS           ; set first pixel flag
506       P:00019E 0BF080              JSR     READPIX                 ;
                   000213
507       P:0001A0 0A0100              BCLR    #$0,X:OPFLAGS           ; clear first pixel flag
508       P:0001A1 0BF080              JSR     READLINE                ;
                   000211
509       P:0001A3 000000  END_READ    NOP                             ;
510       P:0001A4 0A0008              BCLR    #$8,X:CMD               ;
511    
512       P:0001A5 0A0089  AUTO_WIPE   JCLR    #$9,X:CMD,HH_DACS       ; test for AUTOWIPE command
                   0001A7
513                        ;           BSET    #$E,X:OPFLAGS           ;
514                        ;           BSET    #$5,X:OPFLAGS           ;
515                        ;           JSR     FL_CLOCKS               ; flush one parallel row
516                        ;           JSR     READLINE                ;
517                        ;           BCLR    #$9,X:CMD               ;
518    
519       P:0001A7 0A008A  HH_DACS     JCLR    #$A,X:CMD,HH_TEMP       ; test for HH_SYNC command
                   0001AC
520       P:0001A9 0BF080              JSR     SET_DACS                ;
                   0002DA


Motorola DSP56300 Assembler  Version 6.3.4   08-09-10  15:22:59  gcam_ccid37.asm  Page 12



521       P:0001AB 0A000A              BCLR    #$A,X:CMD               ;
522    
523       P:0001AC 0A008B  HH_TEMP     JCLR    #$B,X:CMD,HH_TEC        ; test for HH_TEMP command
                   0001B1
524       P:0001AE 0BF080              JSR     TEMP_READ               ; perform housekeeping chores
                   0002F7
525       P:0001B0 0A000B              BCLR    #$B,X:CMD               ;
526    
527       P:0001B1 0A008C  HH_TEC      JCLR    #$C,X:CMD,HH_OTHER      ; test for HH_TEC command
                   0001B6
528       P:0001B3 0BF080              JSR     TEMP_SET                ; set the TEC value
                   00031B
529       P:0001B5 0A000C              BCLR    #$C,X:CMD               ;
530    
531       P:0001B6 0A008D  HH_OTHER    JCLR    #$D,X:CMD,END_CODE      ; test for HH_OTHER command
                   0001BF
532       P:0001B8 0BF080              JSR     SET_GAIN                ;
                   000335
533       P:0001BA 0BF080              JSR     SET_SCLKS               ;
                   00033F
534       P:0001BC 0BF080              JSR     SET_USEC                ;
                   00033C
535       P:0001BE 0A000D              BCLR    #$D,X:CMD               ;
536    
537       P:0001BF 0A0185  END_CODE    JCLR    #$5,X:OPFLAGS,WAIT_CMD  ; check for AUTO_WIPE
                   000145
538       P:0001C1 0A0029              BSET    #$9,X:CMD               ;
539       P:0001C2 0C0145              JMP     WAIT_CMD                ; Get next command
540    
541                        ;*****************************************************************************
542                        ;   HOLD (MPP MODE)
543                        ;*****************************************************************************
544       P:0001C3 07B080  MPPHOLD     MOVEP   X:MPP,Y:<<SEQREG        ;
                   000040
545       P:0001C5 00000C              RTS                             ;
546    
547                        ;*****************************************************************************
548                        ;   INPUT CLAMP
549                        ;*****************************************************************************
550       P:0001C6 07B080  IPC_CLAMP   MOVEP   X:IPCLKS,Y:<<SEQREG     ;
                   000042
551       P:0001C8 44F400              MOVE    #>HOLD_IPC,X0           ;
                   001F40
552       P:0001CA 06C420              REP     X0                      ; $1F4O=100 us
553       P:0001CB 000000              NOP                             ;
554       P:0001CC 07B080              MOVEP   X:(IPCLKS+1),Y:<<SEQREG ;
                   000043
555       P:0001CE 000000              NOP                             ;
556       P:0001CF 00000C              RTS                             ;
557    
558                        ;*****************************************************************************
559                        ;   FLUSHLINE  (FAST FLUSH)
560                        ;*****************************************************************************
561       P:0001D0 30A000  FLUSHLINE   MOVE    #SCLKS_FF,R0            ; initialize pointer


Motorola DSP56300 Assembler  Version 6.3.4   08-09-10  15:22:59  gcam_ccid37.asm  Page 13



562       P:0001D1 060680              DO      #SEQ,ENDFF              ;
                   0001D5
563       P:0001D3 079880              MOVEP   X:(R0)+,Y:<<SEQREG      ;
564       P:0001D4 0620A0              REP     #HOLD_FF                ;
565       P:0001D5 000000              NOP                             ;
566       P:0001D6 00000C  ENDFF       RTS                             ;
567    
568                        ;*****************************************************************************
569                        ;   FLUSHPIX (HSKIP)
570                        ;*****************************************************************************
571       P:0001D7 060B00  FLUSHPIX    DO      X:HSKIP,ENDFP           ;
                   0001DF
572       P:0001D9 60B100              MOVE    X:SCLKS_FL,R0           ; initialize pointer
573       P:0001DA 060680              DO      #SEQ,ENDHCLK            ;
                   0001DE
574       P:0001DC 079880              MOVEP   X:(R0)+,Y:<<SEQREG      ;
575       P:0001DD 0605A0              REP     #HOLD_S                 ;
576       P:0001DE 000000              NOP                             ;
577       P:0001DF 000000  ENDHCLK     NOP                             ;
578       P:0001E0 00000C  ENDFP       RTS                             ;
579    
580                        ;*****************************************************************************
581                        ;   FLUSHROWS (VSKIP)
582                        ;*****************************************************************************
583       P:0001E1 060A00  FLUSHROWS   DO      X:VSKIP,ENDVSKIP        ;
                   0001E9
584       P:0001E3 305000              MOVE    #PCLKS_RD,R0            ; initialize pointer
585       P:0001E4 060680              DO      #SEQ,ENDVCLK            ;
                   0001E8
586       P:0001E6 079880              MOVEP   X:(R0)+,Y:<<SEQREG      ;
587       P:0001E7 067CA0              REP     #HOLD_FL                ;
588       P:0001E8 000000              NOP                             ;
589       P:0001E9 000000  ENDVCLK     NOP                             ;
590       P:0001EA 00000C  ENDVSKIP    RTS                             ;
591    
592                        ;*****************************************************************************
593                        ;   FLUSHFRAME
594                        ;*****************************************************************************
595       P:0001EB 060400  FLUSHFRAME  DO      X:NFT,ENDFLFR           ;
                   0001F3
596       P:0001ED 305800  FL_CLOCKS   MOVE    #PCLKS_FL,R0            ; initialize pointer
597       P:0001EE 060680              DO      #SEQ,ENDFLCLK           ;
                   0001F2
598       P:0001F0 079880              MOVEP   X:(R0)+,Y:<<SEQREG      ;
599       P:0001F1 067CA0              REP     #HOLD_FL                ;
600       P:0001F2 000000              NOP                             ;
601       P:0001F3 000000  ENDFLCLK    NOP                             ;
602       P:0001F4 00000C  ENDFLFR     RTS                             ;
603    
604                        ;*****************************************************************************
605                        ;   PARALLEL TRANSFER (READOUT)
606                        ;*****************************************************************************
607       P:0001F5 060800  PARALLEL    DO      X:VBIN,ENDPT            ;
                   0001FF


Motorola DSP56300 Assembler  Version 6.3.4   08-09-10  15:22:59  gcam_ccid37.asm  Page 14



608       P:0001F7 305000  P_CLOCKS    MOVE    #PCLKS_RD,R0            ; initialize pointer
609       P:0001F8 060680              DO      #SEQ,ENDPCLK            ;
                   0001FE
610       P:0001FA 079880              MOVEP   X:(R0)+,Y:<<SEQREG      ;
611       P:0001FB 44F400              MOVE    #>HOLD_P,X0             ;
                   00020A
612       P:0001FD 06C420              REP     X0                      ; $317=10us per phase
613       P:0001FE 000000              NOP                             ;
614       P:0001FF 000000  ENDPCLK     NOP                             ;
615       P:000200 00000C  ENDPT       RTS                             ;
616    
617                        ;*****************************************************************************
618                        ;   PARALLEL TRANSFER (FRAME TRANSFER)
619                        ;*****************************************************************************
620       P:000201 07B080  FRAME       MOVEP   X:(PCLKS_FT),Y:<<SEQREG ; 100 us CCD47 pause
                   000048
621       P:000203 44F400              MOVE    #>$1F40,X0              ;
                   001F40
622       P:000205 06C420              REP     X0                      ; $1F40=100 usec
623       P:000206 000000              NOP                             ;
624       P:000207 060400              DO      X:NFT,ENDFT             ;
                   00020F
625       P:000209 304800  FT_CLOCKS   MOVE    #PCLKS_FT,R0            ; initialize seq pointer
626       P:00020A 060680              DO      #SEQ,ENDFTCLK           ;
                   00020E
627       P:00020C 079880              MOVEP   X:(R0)+,Y:<<SEQREG      ;
628       P:00020D 067CA0              REP     #HOLD_FT                ;
629       P:00020E 000000              NOP                             ;
630       P:00020F 000000  ENDFTCLK    NOP                             ;
631       P:000210 00000C  ENDFT       RTS                             ;
632    
633                        ;*****************************************************************************
634                        ;   READLINE SUBROUTINE
635                        ;*****************************************************************************
636       P:000211 060300  READLINE    DO      X:NCOLS,ENDRL           ;
                   000273
637       P:000213 07B080  READPIX     MOVEP   X:(INT_L),Y:<<SEQREG    ; FRST=ON RG=ON
                   000060
638                                    DUP     HOLD_RG                 ; macro
639  m                                 NOP                             ;
640  m                                 ENDM                            ; end macro
647       P:00021B 07B080              MOVEP   X:(INT_L+1),Y:<<SEQREG  ; RG=OFF
                   000061
648       P:00021D 07B080              MOVEP   X:(INT_L+2),Y:<<SEQREG  ; FRST=OFF
                   000062
649       P:00021F 060FA0              REP     #HOLD_SIG               ; preamp settling time
650                        ;           REP     #$F                     ; preamp settling
651       P:000220 000000              NOP                             ;
652       P:000221 07B080  INT1        MOVEP   X:(INT_L+3),Y:<<SEQREG  ; FINT+=ON
                   000063
653       P:000223 449300  SLEEP1      MOVE    X:USEC,X0               ; sleep USEC * 12.5ns
654       P:000224 06C420              REP     X0                      ;
655       P:000225 000000              NOP                             ;
656       P:000226 07B080              MOVEP   X:(INT_L+4),Y:<<SEQREG  ; FINT+=OFF


Motorola DSP56300 Assembler  Version 6.3.4   08-09-10  15:22:59  gcam_ccid37.asm  Page 15



                   000064
657       P:000228 60B000  SERIAL      MOVE    X:SCLKS,R0              ; serial transfer
658       P:000229 060900              DO      X:HBIN,ENDSCLK          ;
                   00024E
659                        S_CLOCKS    DUP     SEQ                     ;    macro
660  m                                 MOVEP   X:(R0)+,Y:<<SEQREG      ;
661  m                                 DUP     HOLD_S                  ;    macro
662  m                                 NOP                             ;
663  m                                 ENDM                            ;
664  m                                 ENDM                            ;
719       P:00024F 060FA0  ENDSCLK     REP     #HOLD_SIG               ; preamp settling time
720       P:000250 000000              NOP                             ; (adjust with o'scope)
721       P:000251 08F4BB  GET_DATA    MOVEP   #WS5,X:BCR              ;
                   07BFE1
722       P:000253 000000              NOP                             ;
723       P:000254 000000              NOP                             ;
724       P:000255 044E21              MOVEP   Y:<<ADC_A,A             ; read ADC
725       P:000256 044F22              MOVEP   Y:<<ADC_B,B             ; read ADC
726       P:000257 08F4BB              MOVEP   #WS,X:BCR               ;
                   073FE1
727       P:000259 000000              NOP                             ;
728       P:00025A 07B080  INT2        MOVEP   X:(INT_H),Y:<<SEQREG    ; FINT-=ON
                   000068
729       P:00025C 449300  SLEEP2      MOVE    X:USEC,X0               ; sleep USEC * 20ns
730       P:00025D 06C420              REP     X0                      ;
731       P:00025E 000000              NOP                             ;
732       P:00025F 07B080              MOVEP   X:(INT_H+1),Y:<<SEQREG  ; FINT-=OFF
                   000069
733       P:000261 5C7000              MOVE    A1,Y:(PIX)              ;
                   000300
734       P:000263 5D7000              MOVE    B1,Y:(PIX+1)            ;
                   000301
735       P:000265 060FA0              REP     #HOLD_ADC               ; settling time
736       P:000266 000000              NOP                             ; (adjust for best noise)
737       P:000267 07B080  CONVST      MOVEP   X:(INT_H+2),Y:<<SEQREG  ; /CONVST=ON
                   00006A
738       P:000269 08DD2F              MOVEP   N5,X:DSR0               ; set DMA source
739       P:00026A 000000              NOP                             ;
740       P:00026B 000000              NOP                             ;
741       P:00026C 07B080              MOVEP   X:(INT_H+3),Y:<<SEQREG  ; /CONVST=OFF MIN 40 NS
                   00006B
742       P:00026E 07B080              MOVEP   X:(INT_H+4),Y:<<SEQREG  ; FRST=ON
                   00006C
743       P:000270 0A01A0              JSET    #$0,X:OPFLAGS,ENDCHK    ; check for first pixel
                   000273
744       P:000272 0AAC37              BSET    #$17,X:DCR0             ; enable DMA
745       P:000273 000000  ENDCHK      NOP                             ;
746       P:000274 00000C  ENDRL       RTS                             ;
747    
748                        ;*******************************************************************************
749                        ;   READ AND WRITE 16-BIT AND 24-BIT DATA
750                        ;*******************************************************************************
751       P:000275 0A1680  READ16      JCLR    #$0,X:LINK,RD16B        ; check RS485 or fiber
                   00027D


Motorola DSP56300 Assembler  Version 6.3.4   08-09-10  15:22:59  gcam_ccid37.asm  Page 16



752       P:000277 01AD84              JCLR    #$4,X:PDRD,*            ; wait for data in RXREG
                   000277
753       P:000279 5EF000              MOVE    Y:RXREG,A               ; bits 15..0
                   FFFF86
754       P:00027B 0140C6              AND     #>$FFFF,A               ;
                   00FFFF
755       P:00027D 0A16A0  RD16B       JSET    #$0,X:LINK,ENDRD16      ; check RS485 or fiber
                   000284
756       P:00027F 01B787              JCLR    #7,X:SSISR,*            ; wait for RDRF to go high
                   00027F
757       P:000281 54F000              MOVE    X:RXD,A1                ; read from ESSI
                   FFFFB8
758       P:000283 000000              NOP                             ;
759       P:000284 00000C  ENDRD16     RTS                             ; 16-bit word in A1
760    
761       P:000285 0A1680  WRITE16     JCLR    #$0,X:LINK,WR16B        ; check RS485 or fiber
                   000289
762       P:000287 5C7000              MOVE    A1,Y:TXREG              ; write bits 15..0
                   FFFF85
763       P:000289 0A16A0  WR16B       JSET    #$0,X:LINK,ENDWR16      ;
                   00028F
764       P:00028B 01B786              JCLR    #6,X:SSISR,*            ; wait for TDE
                   00028B
765       P:00028D 547000              MOVE    A1,X:TXD                ;
                   FFFFBC
766       P:00028F 00000C  ENDWR16     RTS                             ;
767    
768       P:000290 0A1680  READ24      JCLR    #$0,X:LINK,RD24B        ; check RS485 or fiber
                   00029E
769       P:000292 01AD84              JCLR    #$4,X:PDRD,*            ; wait for data in RXREG
                   000292
770       P:000294 5EF000              MOVE    Y:RXREG,A               ; bits 15..0
                   FFFF86
771       P:000296 0140C6              AND     #>$FFFF,A               ;
                   00FFFF
772       P:000298 0C1C20              ASR     #$10,A,A                ; shift right 16 bits
773       P:000299 01AD84              JCLR    #$4,X:PDRD,*            ; wait for data in RXREG
                   000299
774       P:00029B 5CF000              MOVE    Y:RXREG,A1              ; bits 15..0
                   FFFF86
775       P:00029D 0C1D20              ASL     #$10,A,A                ; shift left 16 bits
776       P:00029E 0A16A0  RD24B       JSET    #$0,X:LINK,ENDRD24      ;
                   0002AA
777       P:0002A0 01B787              JCLR    #7,X:SSISR,*            ; wait for RDRF to go high
                   0002A0
778       P:0002A2 56F000              MOVE    X:RXD,A                 ; read from ESSI
                   FFFFB8
779       P:0002A4 0C1C20              ASR     #$10,A,A                ; shift right 16 bits
780       P:0002A5 01B787              JCLR    #7,X:SSISR,*            ; wait for RDRF to go high
                   0002A5
781       P:0002A7 54F000              MOVE    X:RXD,A1                ;
                   FFFFB8
782       P:0002A9 0C1D20              ASL     #$10,A,A                ; shift left 16 bits
783       P:0002AA 00000C  ENDRD24     RTS                             ; 24-bit word in A1


Motorola DSP56300 Assembler  Version 6.3.4   08-09-10  15:22:59  gcam_ccid37.asm  Page 17



784    
785       P:0002AB 0A1680  WRITE24     JCLR    #$0,X:LINK,WR24B        ; check RS485 or fiber
                   0002B4
786       P:0002AD 5C7000              MOVE    A1,Y:TXREG              ; send bits 15..0
                   FFFF85
787       P:0002AF 0C1C20              ASR     #$10,A,A                ; right shift 16 bits
788       P:0002B0 0610A0              REP     #$10                    ; wait for data sent
789       P:0002B1 000000              NOP                             ;
790       P:0002B2 5C7000              MOVE    A1,Y:TXREG              ; send bits 23..16
                   FFFF85
791       P:0002B4 0A16A0  WR24B       JSET    #$0,X:LINK,ENDWR24      ;
                   0002C0
792       P:0002B6 01B786              JCLR    #6,X:SSISR,*            ; wait for TDE
                   0002B6
793       P:0002B8 547000              MOVE    A1,X:TXD                ; send bits 15..0
                   FFFFBC
794       P:0002BA 0C1C20              ASR     #$10,A,A                ; right shift 16 bits
795       P:0002BB 000000              NOP                             ; wait for flag update
796       P:0002BC 01B786              JCLR    #6,X:SSISR,*            ; wait for TDE
                   0002BC
797       P:0002BE 547000              MOVE    A1,X:TXD                ; send bits 23..16
                   FFFFBC
798       P:0002C0 00000C  ENDWR24     RTS                             ;
799    
800                        ;*****************************************************************************
801                        ;   LOAD NEW DATA VIA SSI PORT
802                        ;*****************************************************************************
803       P:0002C1 0D0290  MEM_LOAD    JSR     READ24                  ; get memspace/address
804       P:0002C2 219100              MOVE    A1,R1                   ; load address into R1
805       P:0002C3 218400              MOVE    A1,X0                   ; store memspace code
806       P:0002C4 0D0290              JSR     READ24                  ; get data
807       P:0002C5 0AD157              BCLR    #$17,R1                 ; clear memspace bit
808       P:0002C6 0AC437  X_LOAD      JSET    #$17,X0,Y_LOAD          ;
                   0002C9
809       P:0002C8 546100              MOVE    A1,X:(R1)               ; load x memory
810       P:0002C9 0AC417  Y_LOAD      JCLR    #$17,X0,END_LOAD        ;
                   0002CC
811       P:0002CB 5C6100              MOVE    A1,Y:(R1)               ; load y memory
812       P:0002CC 00000C  END_LOAD    RTS                             ;
813    
814                        ;*****************************************************************************
815                        ;   SEND MEMORY CONTENTS VIA SSI PORT
816                        ;*****************************************************************************
817       P:0002CD 0D0290  MEM_SEND    JSR     READ24                  ; get memspace/address
818       P:0002CE 219100              MOVE    A1,R1                   ; load address into R1
819       P:0002CF 218400              MOVE    A1,X0                   ; save memspace code
820       P:0002D0 0AD157              BCLR    #$17,R1                 ; clear memspace bit
821       P:0002D1 0AC437  X_SEND      JSET    #$17,X0,Y_SEND          ;
                   0002D4
822       P:0002D3 54E100              MOVE    X:(R1),A1               ; send x memory
823       P:0002D4 0AC417  Y_SEND      JCLR    #$17,X0,WRITE24         ;
                   0002AB
824       P:0002D6 5CE100              MOVE    Y:(R1),A1               ; send y memory
825       P:0002D7 0D02AB  SEND24      JSR     WRITE24                 ;


Motorola DSP56300 Assembler  Version 6.3.4   08-09-10  15:22:59  gcam_ccid37.asm  Page 18



826       P:0002D8 000000              NOP                             ;
827       P:0002D9 00000C              RTS                             ;
828    
829                        ;*****************************************************************************
830                        ;   CCID37 SET DAC VOLTAGES  DEFAULTS:  OD=18V  RD=10V  OG=-2V
831                        ;   PCLKS=+4V -6V SCLKS=+4V -4V RG=+8V -2V
832                        ;*****************************************************************************
833       P:0002DA 0BF080  SET_DACS    JSR     SET_VBIAS               ;
                   0002DF
834       P:0002DC 0BF080              JSR     SET_VCLKS               ;
                   0002EB
835       P:0002DE 00000C              RTS                             ;
836    
837       P:0002DF 08F4BB  SET_VBIAS   MOVEP   #WS5,X:BCR              ; add wait states
                   07BFE1
838       P:0002E1 331800              MOVE    #VBIAS,R3               ; bias voltages
839       P:0002E2 64F400              MOVE    #SIG_AB,R4              ; bias DAC registers
                   FFFF88
840       P:0002E4 060880              DO      #$8,ENDSETB             ; set bias voltages
                   0002E7
841       P:0002E6 44DB00              MOVE    X:(R3)+,X0              ;
842       P:0002E7 4C5C00              MOVE    X0,Y:(R4)+              ;
843       P:0002E8 08F4BB  ENDSETB     MOVEP   #WS,X:BCR               ;
                   073FE1
844       P:0002EA 00000C              RTS                             ;
845    
846       P:0002EB 08F4BB  SET_VCLKS   MOVEP   #WS5,X:BCR              ; add wait states
                   07BFE1
847       P:0002ED 332000              MOVE    #VCLK,R3                ; clock voltages
848       P:0002EE 64F400              MOVE    #CLK_AB,R4              ; clock DAC registers
                   FFFF90
849       P:0002F0 061080              DO      #$10,ENDSETV            ; set clock voltages
                   0002F3
850       P:0002F2 44DB00              MOVE    X:(R3)+,X0              ;
851       P:0002F3 4C5C00              MOVE    X0,Y:(R4)+              ;
852       P:0002F4 08F4BB  ENDSETV     MOVEP   #WS,X:BCR               ; re-set wait states
                   073FE1
853       P:0002F6 00000C              RTS
854    
855                        ;*****************************************************************************
856                        ;   TEMP MONITOR ADC START AND CONVERT
857                        ;*****************************************************************************
858       P:0002F7 012D20  TEMP_READ   BSET    #$0,X:PDRD              ; turn on temp sensor
859    
860                        ; -------------------------------------------------------------------
861                        ; test  - 30 oct 07 RAT
862                        ; set OFFSET_R to zero during idle periods.
863    
864       P:0002F8 08F4BB              MOVEP   #WS5,X:BCR              ; add wait states
                   07BFE1
865       P:0002FA 44F400              MOVE    #DZ-1000,X0             ; temperature bias voltage (OFFSET_R is
 first)
                   000C18
866       P:0002FC 64F400              MOVE    #SIG_AB,R4              ; bias DAC registers


Motorola DSP56300 Assembler  Version 6.3.4   08-09-10  15:22:59  gcam_ccid37.asm  Page 19



                   FFFF88
867       P:0002FE 000000          NOP                   ; -RAT 2 sep 08
868       P:0002FF 000000          NOP                   ; -RAT 2 sep 08
869       P:000300 4C6400              MOVE    X0,Y:(R4)               ;
870       P:000301 08F4BB              MOVEP   #WS,X:BCR               ; re-set wait states
                   073FE1
871    
872                        ;--------------------------------------------------------------------
873    
874       P:000303 07F409              MOVEP   #$20,X:TCPR1            ; set timer compare value
                   000020
875       P:000305 0BF080              JSR     M_TIMER                 ; wait for output to settle
                   00032F
876    
877       P:000307 08F4BB              MOVEP   #WS3,X:BCR              ; set wait states for ADC
                   077FE1
878       P:000309 07B080              MOVEP   X:TCLKS,Y:<<SEQREG      ; assert /CONVST
                   000044
879       P:00030B 0604A0              REP     #$4                     ;
880       P:00030C 000000              NOP                             ;
881       P:00030D 07B080              MOVEP   X:(TCLKS+1),Y:<<SEQREG  ; deassert /CONVST and wait
                   000045
882       P:00030F 0650A0              REP     #$50                    ;
883       P:000310 000000              NOP                             ;
884    
885       P:000311 044C22              MOVEP   Y:<<ADC_B,A1            ; read ADC2
886       P:000312 45F400              MOVE    #>$3FFF,X1              ; prepare 14-bit mask
                   003FFF
887       P:000314 200066              AND     X1,A1                   ; get 14 LSBs
888       P:000315 012D00              BCLR    #$0,X:PDRD              ; turn off temp sensor
889       P:000316 0BCC4D              BCHG    #$D,A1                  ; 2complement to binary
890       P:000317 08F4BB              MOVEP   #WS,X:BCR               ; re-set wait states
                   073FE1
891       P:000319 541100              MOVE    A1,X:TEMP               ;
892       P:00031A 00000C              RTS                             ;
893    
894       P:00031B 08F4BB  TEMP_SET    MOVEP   #WS5,X:BCR              ; add wait states
                   07BFE1
895       P:00031D 000000              NOP                             ;
896    
897                        ; -------------------------------------------------------------------
898                        ; test  - 23 oct 07 RAT
899                        ; restore OFFSET_R value during imaging
900    
901       P:00031E 331800              MOVE    #VBIAS,R3               ; bias voltages (OFFSET_R is first)
902       P:00031F 64F400              MOVE    #SIG_AB,R4              ; bias DAC registers
                   FFFF88
903       P:000321 000000          NOP                   ; -RAT 2 sep 08
904       P:000322 44E300              MOVE    X:(R3),X0               ;
905       P:000323 4C6400              MOVE    X0,Y:(R4)               ;
906    
907                        ;--------------------------------------------------------------------
908    
909       P:000324 07B08A              MOVEP   X:TEC,Y:<<TEC_REG       ; set TEC DAC


Motorola DSP56300 Assembler  Version 6.3.4   08-09-10  15:22:59  gcam_ccid37.asm  Page 20



                   00001A
910       P:000326 08F4BB              MOVEP   #WS,X:BCR               ; re-set wait states
                   073FE1
911       P:000328 00000C              RTS
912    
913                        ;*****************************************************************************
914                        ;   MILLISECOND AND MICROSECOND TIMER MODULE
915                        ;*****************************************************************************
916       P:000329 010F20  U_TIMER     BSET    #$0,X:TCSR0             ; start timer
917       P:00032A 014F20              BTST    #$0,X:TCSR0             ; delay for flag update
918    
919       P:00032B 018F95              JCLR    #$15,X:TCSR0,*          ; wait for TCF flag
                   00032B
920       P:00032D 010F00              BCLR    #$0,X:TCSR0             ; stop timer, clear flag
921       P:00032E 00000C              RTS                             ; flags update during RTS
922    
923       P:00032F 010B20  M_TIMER     BSET    #$0,X:TCSR1             ; start timer
924       P:000330 014F20              BTST    #$0,X:TCSR0             ; delay for flag update
925    
926       P:000331 018B95              JCLR    #$15,X:TCSR1,*          ; wait for TCF flag
                   000331
927       P:000333 010B00              BCLR    #$0,X:TCSR1             ; stop timer, clear flag
928       P:000334 00000C              RTS                             ; flags update during RTS
929    
930                        ;*****************************************************************************
931                        ;   SIGNAL-PROCESSING GAIN MODULE
932                        ;*****************************************************************************
933       P:000335 0A12A0  SET_GAIN    JSET    #$0,X:GAIN,HI_GAIN      ;
                   000338
934       P:000337 012D01              BCLR    #$1,X:PDRD              ; set gain=0
935       P:000338 0A1280  HI_GAIN     JCLR    #$0,X:GAIN,END_GAIN     ;
                   00033B
936       P:00033A 012D21              BSET    #$1,X:PDRD              ; set gain=1
937       P:00033B 00000C  END_GAIN    RTS                             ;
938    
939                        ;*****************************************************************************
940                        ;   SIGNAL-PROCESSING DUAL-SLOPE TIME MODULE
941                        ;*****************************************************************************
942       P:00033C 07F00D  SET_USEC    MOVEP   X:USEC,X:TCPR0          ; timer compare value
                   000013
943       P:00033E 00000C  END_USEC    RTS                             ;
944    
945                        ;*****************************************************************************
946                        ;   SELECT SERIAL CLOCK SEQUENCE (IE OUTPUT AMPLIFIER)
947                        ;*****************************************************************************
948       P:00033F 569400  SET_SCLKS   MOVE    X:OPCH,A                ; 0x1=right 0x2=left
949       P:000340 44F400  RIGHT_AMP   MOVE    #>$1,X0                 ; 0x3=both  0x4=all
                   000001
950       P:000342 200045              CMP     X0,A                    ;
951       P:000343 0AF0A2              JNE     LEFT_AMP                ;
                   00034D
952       P:000345 46F400              MOVE    #>SCLKS_R,Y0            ; serial clock sequences
                   000070
953       P:000347 47F400              MOVE    #>SCLKS_FLR,Y1          ; serial flush sequences


Motorola DSP56300 Assembler  Version 6.3.4   08-09-10  15:22:59  gcam_ccid37.asm  Page 21



                   000080
954       P:000349 75F400              MOVE    #PIX+1,N5               ; pointer to start of data
                   000301
955       P:00034B 08F4AD              MOVEP   #>$0,X:DCO0             ; DMA counter
                   000000
956       P:00034D 44F400  LEFT_AMP    MOVE    #>$2,X0                 ;
                   000002
957       P:00034F 200045              CMP     X0,A                    ;
958       P:000350 0AF0A2              JNE     BOTH_AMP                ;
                   00035A
959       P:000352 46F400              MOVE    #>SCLKS_L,Y0            ;
                   000078
960       P:000354 47F400              MOVE    #>SCLKS_FLL,Y1          ;
                   000088
961       P:000356 75F400              MOVE    #PIX,N5                 ;
                   000300
962       P:000358 08F4AD              MOVEP   #>$0,X:DCO0             ;
                   000000
963       P:00035A 44F400  BOTH_AMP    MOVE    #>$3,X0                 ;
                   000003
964       P:00035C 200045              CMP     X0,A                    ;
965       P:00035D 0AF0A2              JNE     END_AMP                 ;
                   000367
966       P:00035F 46F400              MOVE    #>SCLKS_B,Y0            ;
                   000090
967       P:000361 47F400              MOVE    #>SCLKS_FLB,Y1          ;
                   000098
968       P:000363 75F400              MOVE    #PIX,N5                 ;
                   000300
969       P:000365 08F4AD              MOVEP   #>$1,X:DCO0             ;
                   000001
970       P:000367 463000  END_AMP     MOVE    Y0,X:SCLKS              ;
971       P:000368 473100              MOVE    Y1,X:SCLKS_FL           ;
972       P:000369 00000C              RTS                             ;
973    
974                        ;*****************************************************************************
975                        ;   CMD.ASM -- ROUTINE TO INTERPRET AN 8-BIT COMMAND + COMPLEMENT
976                        ;*****************************************************************************
977                        ; Each command word is sent as two bytes -- the LSB has the command
978                        ; and the MSB has the complement.
979    
980       P:00036A 568000  CMD_FIX     MOVE    X:CMD,A                 ; extract cmd[7..0]
981       P:00036B 0140C6              AND     #>$FF,A                 ; and put in X1
                   0000FF
982       P:00036D 218500              MOVE    A1,X1                   ;
983       P:00036E 568000              MOVE    X:CMD,A                 ; extract cmd[15..8]
984       P:00036F 0C1ED0              LSR     #$8,A                   ; complement
985       P:000370 57F417              NOT     A   #>$1,B              ; and put in A1
                   000001
986       P:000372 0140C6              AND     #>$FF,A                 ;
                   0000FF
987       P:000374 0C1E5D              ASL     X1,B,B                  ;
988       P:000375 200065              CMP     X1,A                    ; compare X1 and A1
989       P:000376 0AF0AA              JEQ     CMD_OK                  ;


Motorola DSP56300 Assembler  Version 6.3.4   08-09-10  15:22:59  gcam_ccid37.asm  Page 22



                   00037A
990       P:000378 20001B  CMD_NG      CLR     B                       ; cmd word no good
991       P:000379 000000              NOP                             ;
992       P:00037A 550000  CMD_OK      MOVE    B1,X:CMD                ; cmd word OK
993       P:00037B 000000              NOP                             ;
994       P:00037C 00000C  END_CMD     RTS                             ;
995    
996                                    END

0    Errors
0    Warnings


