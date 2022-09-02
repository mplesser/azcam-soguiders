
Motorola DSP56300 Assembler  Version 6.3.4   12-01-12  18:29:00  gcam_ccid-21.asm  Page 1



1                          ;*****************************************************************************
2                          ;   GCAM.ASM -- DSP-BASED CCD CONTROLLER PROGRAM
3                          ;*****************************************************************************
4                              PAGE    110,60,1,1
5                              TABS    4
6                          ;*****************************************************************************
7                          ;   Code modified for the CCID-21 29 June 2007 - R. Tucker
8                          ;   waveform code for driving SW and no TG
9                          ;   Changes to parallel and serial clocking.
10                         ;   parallel clocking in one direction, two serial patterns
11                         ;*****************************************************************************
12     
13                         ;
14                         ;*****************************************************************************
15                         ;   DEFINITIONS & POINTERS
16                         ;*****************************************************************************
17        000100           START       EQU     $000100             ; program start location
18        000006           SEQ         EQU     $000006             ; seq fragment length
19        001000           DZ          EQU     $001000             ; DAC zero volt offset
20     
21        073FE1           WS          EQU     $073FE1             ; periph wait states
22        073FE1           WS1         EQU     $073FE1             ; 1 PERIPH 1 SRAM 31 EPROM
23        077FE1           WS3         EQU     $077FE1             ; 3 PERIPH 1 SRAM 31 EPROM
24        07BFE1           WS5         EQU     $07BFE1             ; 5 PERIPH 1 SRAM 31 EPROM
25     
26                         ;*****************************************************************************
27                         ;   COMPILE-TIME OPTIONS
28                         ;*****************************************************************************
29     
30        000001           VERSION         EQU     $1              ;
31        000000           RDMODE          EQU     $0              ;
32        00020A           HOLD_P          EQU     $020A           ; P clock timing $20A=40us
33        00007C           HOLD_FT         EQU     $007C           ; FT clock timing $7C=10us xfer
34        00007C           HOLD_FL         EQU     $007C           ; FL clock timimg
35        00000F           HOLD_S          EQU     $000F           ; S clock timing (leave at $000F)
36        000008           HOLD_RG         EQU     $0008           ; RG timing
37        001F40           HOLD_PL         EQU     $1F40           ; pre-line settling (1F40=100us)
38        000020           HOLD_FF         EQU     $0020           ; FF clock timimg
39        001F40           HOLD_IPC        EQU     $1F40           ; IPC clock timing ($1F40=100us)
40        00001F           HOLD_SIG        EQU     $001F           ; preamp settling time
41        0000AF           HOLD_ADC        EQU     $00AF           ; pre-sample settling
42        00020A           INIT_NROWS      EQU     $20A            ; $20A=(512+10)
43        000204           INIT_NCOLS      EQU     $204            ; $204=(512+4)
44        000200           INIT_NFT        EQU     $200            ; $200-(512) frame-transfer device
45                         INIT_NFLUSH
46        000200           INIT_NFLUSH     EQU     $200            ; $200=(512)
47        000002           INIT_NCH        EQU     $2              ;
48        000002           INIT_VBIN       EQU     $2              ;
49        000002           INIT_HBIN       EQU     $2              ;
50        000000           INIT_VSKIP      EQU     $0              ;
51        000000           INIT_HSKIP      EQU     $0              ;
52        000000           INIT_GAIN       EQU     $0              ; 0=LOW 1=HIGH
53        0000C8           INIT_USEC       EQU     $C8             ;
54        000001           INIT_OPCH       EQU     $1              ; 0x1=right 0x2=left 0x3=both  0x4=all


Motorola DSP56300 Assembler  Version 6.3.4   12-01-12  18:29:00  gcam_ccid-21.asm  Page 2



55        000002           INIT_SCLKS      EQU     $2              ; 1=right amp, 2=left amp
56        000000           INIT_PID        EQU     $0              ; FLAG $0=OFF $1=ON
57        000000           INIT_LINK       EQU     $0              ; 0=wire 1=single_fiber
58        000002           INIT_PDIR       EQU     $2              ; parallel clocking direction
59                                             ; 0=toward serial register 1=away
60     
61                         ;*****************************************************************************
62                         ;   EXTERNAL PERIPHERAL DEFINITIONS (GUIDER CAMERA)
63                         ;*****************************************************************************
64        FFFF80           SEQREG      EQU     $FFFF80             ; external CCD clock register
65        FFFF81           ADC_A       EQU     $FFFF81             ; A/D converter #1
66        FFFF82           ADC_B       EQU     $FFFF82             ; A/D converter #2
67        FFFF85           TXREG       EQU     $FFFF85             ; Transmit Data Register
68        FFFF86           RXREG       EQU     $FFFF86             ; Receive Data register
69        FFFF88           SIG_AB      EQU     $FFFF88             ; bias voltages A+B
70        FFFF90           CLK_AB      EQU     $FFFF90             ; clock voltages A+B
71        FFFF8A           TEC_REG     EQU     $FFFF8A             ; TEC register
72     
73                         ;*****************************************************************************
74                         ;   INTERNAL PERIPHERAL DEFINITIONS (DSP563000)
75                         ;*****************************************************************************
76        FFFFFF           IPRC        EQU     $FFFFFF             ; Interrupt priority register (core)
77        FFFFFE           IPRP        EQU     $FFFFFE             ; Interrupt priority register (periph)
78        FFFFFD           PCTL        EQU     $FFFFFD             ; PLL control register
79        FFFFFB           BCR         EQU     $FFFFFB             ; Bus control register (wait states)
80        FFFFF9           AAR0        EQU     $FFFFF9             ; Address attribute register 0
81        FFFFF8           AAR1        EQU     $FFFFF8             ; Address attribute register 1
82        FFFFF7           AAR2        EQU     $FFFFF7             ; Address attribute register 2
83        FFFFF6           AAR3        EQU     $FFFFF6             ; Address attribute register 3
84        FFFFF5           IDR         EQU     $FFFFF5             ; ID Register
85        FFFFC9           PDRB        EQU     $FFFFC9             ; Port B (HOST) GPIO data
86        FFFFC8           PRRB        EQU     $FFFFC8             ; Port B (HOST) GPIO direction
87        FFFFC4           PCRB        EQU     $FFFFC4             ; Port B (HOST) control register
88        FFFFBF           PCRC        EQU     $FFFFBF             ; Port C (ESSI_0) control register
89        FFFFBE           PRRC        EQU     $FFFFBE             ; Port C (ESSI_0) direction
90        FFFFBD           PDRC        EQU     $FFFFBD             ; Port C (ESSI_0) data
91        FFFFBC           TXD         EQU     $FFFFBC             ; ESSI0 Transmit Data Register 0
92        FFFFB8           RXD         EQU     $FFFFB8             ; ESSI0 Receive Data Register
93        FFFFB7           SSISR       EQU     $FFFFB7             ; ESSI0 Status Register
94        FFFFB6           CRB         EQU     $FFFFB6             ; ESSI0 Control Register B
95        FFFFB5           CRA         EQU     $FFFFB5             ; ESSI0 Control Register A
96        FFFFAF           PCRD        EQU     $FFFFAF             ; Port D (ESSI_1) control register
97        FFFFAE           PRRD        EQU     $FFFFAE             ; Port D (ESSI_1) direction
98        FFFFAD           PDRD        EQU     $FFFFAD             ; Port D (ESSI_1) data
99        FFFF9F           PCRE        EQU     $FFFF9F             ; Port E (SCI) control register
100       FFFF9E           PRRE        EQU     $FFFF9E             ; Port E (SCI) data direction
101       FFFF9D           PDRE        EQU     $FFFF9D             ; Port E (SCI) data
102       FFFF8F           TCSR0       EQU     $FFFF8F             ; TIMER0 Control/Status Register
103       FFFF8E           TLR0        EQU     $FFFF8E             ; TIMER0 Load Reg
104       FFFF8D           TCPR0       EQU     $FFFF8D             ; TIMER0 Compare Register
105       FFFF8C           TCR0        EQU     $FFFF8C             ; TIMER0 Count Register
106       FFFF8B           TCSR1       EQU     $FFFF8B             ; TIMER1 Control/Status Register
107       FFFF8A           TLR1        EQU     $FFFF8A             ; TIMER1 Load Reg
108       FFFF89           TCPR1       EQU     $FFFF89             ; TIMER1 Compare Register


Motorola DSP56300 Assembler  Version 6.3.4   12-01-12  18:29:00  gcam_ccid-21.asm  Page 3



109       FFFF88           TCR1        EQU     $FFFF88             ; TIMER1 Count Register
110       FFFF87           TCSR2       EQU     $FFFF87             ; TIMER2 Control/Status Register
111       FFFF86           TLR2        EQU     $FFFF86             ; TIMER2 Load Reg
112       FFFF85           TCPR2       EQU     $FFFF85             ; TIMER2 Compare Register
113       FFFF84           TCR2        EQU     $FFFF84             ; TIMER2 Count Register
114       FFFF83           TPLR        EQU     $FFFF83             ; TIMER Prescaler Load Register
115       FFFF82           TPCR        EQU     $FFFF82             ; TIMER Prescalar Count Register
116       FFFFEF           DSR0        EQU     $FFFFEF             ; DMA source address
117       FFFFEE           DDR0        EQU     $FFFFEE             ; DMA dest address
118       FFFFED           DCO0        EQU     $FFFFED             ; DMA counter
119       FFFFEC           DCR0        EQU     $FFFFEC             ; DMA control register
120    
121                        ;*****************************************************************************
122                        ;   REGISTER DEFINITIONS (GUIDER CAMERA)
123                        ;*****************************************************************************
124       000000           CMD         EQU     $000000             ; command word/flags from host
125       000001           OPFLAGS     EQU     $000001             ; operational flags
126       000002           NROWS       EQU     $000002             ; number of rows to read
127       000003           NCOLS       EQU     $000003             ; number of columns to read
128       000004           NFT         EQU     $000004             ; number of rows for frame transfer
129       000005           NFLUSH      EQU     $000005             ; number of columns to flush
130       000006           NCH         EQU     $000006             ; number of output channels (amps)
131       000007           NPIX        EQU     $000007             ; (not used)
132       000008           VBIN        EQU     $000008             ; vertical (parallel) binning
133       000009           HBIN        EQU     $000009             ; horizontal (serial) binning
134       00000A           VSKIP       EQU     $00000A             ; V prescan or offset (rows)
135       00000B           HSKIP       EQU     $00000B             ; H prescan or offset (columns)
136       00000C           VSUB        EQU     $00000C             ; V subraster size
137       00000D           HSUB        EQU     $00000D             ; H subraster size
138       00000E           NEXP        EQU     $00000E             ; number of exposures (not used)
139       00000F           NSHUFFLE    EQU     $00000F             ; (not used)
140    
141       000010           EXP_TIME    EQU     $000010             ; CCD integration time(r)
142       000011           TEMP        EQU     $000011             ; Temperature sensor reading(s)
143       000012           GAIN        EQU     $000012             ; Sig_proc gain
144       000013           USEC        EQU     $000013             ; Sig_proc sample time
145       000014           OPCH        EQU     $000014             ; Output channel
146       000015           HDIR        EQU     $000015             ; serial clock direction
147       000016           LINK        EQU     $000016             ; 0=wire 1=single_fiber
148       000017           PDIR        EQU     $000017             ; parallel direction
149    
150       000030           SCLKS       EQU     $000030             ; serial clocks
151       000031           SCLKS_FL    EQU     $000031             ; serial clocks flush
152       000032           INT_X       EQU     $000032             ; reset and integrate clocks
153       000033           NDMA        EQU     $000033             ; (not used)
154       000034           PCLKS       EQU     $000034             ; parallel clocks
155    
156       000018           VBIAS       EQU     $000018             ; bias voltages
157       000020           VCLK        EQU     $000020             ; clock voltages
158       00001A           TEC         EQU     $00001A             ; TEC current
159       000300           PIX         EQU     $000300             ; start address for data storage
160    
161                        ;*****************************************************************************
162                        ;   SEQUENCE FRAGMENT STARTING ADDRESSES (& OTHER POINTERS)


Motorola DSP56300 Assembler  Version 6.3.4   12-01-12  18:29:00  gcam_ccid-21.asm  Page 4



163                        ;*****************************************************************************
164       000040           MPP         EQU     $0040               ; MPP/hold state
165       000042           IPCLKS      EQU     $0042               ; input clamp
166       000044           TCLKS       EQU     $0044               ; Temperature monitor clocks
167       000048           PCLKS_FTU   EQU     $0048               ; parallel frame transfer, upper
168       000050           PCLKS_RDU   EQU     $0050               ; parallel read-out transfer, upper
169       000058           PCLKS_FLU   EQU     $0058               ; parallel flush transfer, upper
170       000060           PCLKS_FTL   EQU     $0060               ; parallel frame transfer, lower
171       000068           PCLKS_RDL   EQU     $0068               ; parallel read-out transfer, lower
172       000070           PCLKS_FLL   EQU     $0070               ; parallel flush transfer, lower
173       000078           PCLKS_FLB   EQU     $0078               ; parallel flush transfer, both
174       000080           INT_L       EQU     $0080               ; reset and first integration
175       000088           INT_H       EQU     $0088               ; second integration and A/D
176       000090           SCLKS_R     EQU     $0090               ; serial clocks shift right
177       000098           SCLKS_FLR   EQU     $0098               ; serial clocks flush right
178       0000A0           SCLKS_L     EQU     $00A0               ; serial clocks shift left
179       0000A8           SCLKS_FLL   EQU     $00A8               ; serial clocks flush left
180       0000B0           SCLKS_B     EQU     $00B0               ; serial clocks both
181       0000B8           SCLKS_FLB   EQU     $00B8               ; serial clocks flush both
182       0000C0           SCLKS_FF    EQU     $00C0               ; serial clocks fast flush
183    
184                        ;*******************************************************************************
185                        ;   INITIALIZE X MEMORY AND DEFINE PERIPHERALS
186                        ;*******************************************************************************
187       X:000000                     ORG     X:CMD               ; CCD control information
188       X:000000                     DC      $0                  ; CMD/FLAGS
189       X:000001                     DC      $0                  ; OPFLAGS
190       X:000002                     DC      INIT_NROWS          ; NROWS
191       X:000003                     DC      INIT_NCOLS          ; NCOLS
192       X:000004                     DC      INIT_NFT            ; NFT
193       X:000005                     DC      INIT_NFLUSH         ; NFLUSH
194       X:000006                     DC      INIT_NCH            ; NCH
195       X:000007                     DC      $1                  ; NPIX (not used)
196       X:000008                     DC      INIT_VBIN           ; VBIN
197       X:000009                     DC      INIT_HBIN           ; HBIN
198       X:00000A                     DC      INIT_VSKIP          ; VSKIP ($0)
199       X:00000B                     DC      INIT_HSKIP          ; HSKIP ($0)
200       X:00000C                     DC      $0                  ; VSUB
201       X:00000D                     DC      $0                  ; HSUB
202       X:00000E                     DC      $1                  ; NEXP (not used)
203       X:00000F                     DC      $0                  ; (not used)
204    
205       X:000010                     ORG     X:EXP_TIME
206       X:000010                     DC      $3E8                ; EXP_TIME
207       X:000011                     DC      $0                  ; TEMP
208       X:000012                     DC      INIT_GAIN           ; GAIN
209       X:000013                     DC      INIT_USEC           ; USEC SAMPLE TIME
210       X:000014                     DC      INIT_OPCH           ; OUTPUT CHANNEL
211       X:000015                     DC      INIT_SCLKS          ; HORIZ DIRECTION
212       X:000016                     DC      INIT_LINK           ; SERIAL LINK
213       X:000017                     DC      INIT_PDIR           ; VERTICAL DIRECTION
214    
215                        ;*****************************************************************************
216                        ;   CCD57 SET DAC VOLTAGES  DEFAULTS:  OD=20V  RD=8V  OG=ABG=-6V


Motorola DSP56300 Assembler  Version 6.3.4   12-01-12  18:29:00  gcam_ccid-21.asm  Page 5



217                        ;   PCLKS=+3V -9V SCLKS=+2V -8V RG=+3V -9V
218                        ;
219                        ;   CCID37 SET DAC VOLTAGES  DEFAULTS:  OD=18V  RD=10V  OG=-2V
220                        ;   PCLKS=+4V -6V SCLKS=+4V -4V RG=+8V -2V
221                        ;
222                        ;   STA1220A SET DAC VOLTAGES  DEFAULTS:  OD=24V  RD=15V  OG=-1V
223                        ;   PCLKS=+4V -9V SCLKS=+5V -5V RG=+8V 0V SW=+5V -5V TG=+4V -9V
224                        ;
225                        ;   CCID-21 SET DAC VOLTAGES  DEFAULTS:  OD=18V  RD=10V  OG=-2V
226                        ;   PCLKS=+4V -6V SCLKS=+4V -4V SW=+5 -5V RG=+8V -2V B7=-6V  B5=+12 to +15V
227                        ;*****************************************************************************
228    
229       X:000018                     ORG     X:VBIAS
230       X:000018                     DC      (DZ-0000)           ; OFFSET_R (5mV/DN) (0480)
231       X:000019                     DC      (DZ-0000)           ; OFFSET_L
232       X:00001A                     DC      (DZ-1600)           ; B7
233       X:00001B                     DC      (DZ-0200)           ; OG  voltage
234       X:00001C                     DC      (DZ+1200)           ; B5 (10 mV/DN)
235       X:00001D                     DC      (DZ+1000)           ; RD 1400
236       X:00001E                     DC      (DZ+1800)           ; OD_R  2200
237       X:00001F                     DC      (DZ+1800)           ; OD_L  2200
238    
239       X:000020                     ORG     X:VCLK
240       X:000020                     DC      (DZ-0000)           ; IPC- [V0] voltage (5mV/DN)    (0v)
241       X:000021                     DC      (DZ+1000)           ; IPC+ [V1]         (+5v)
242       X:000022                     DC      (DZ-0400)           ; RG-  [V2]         (0v)
243       X:000023                     DC      (DZ+1600)           ; RG+  [V3]         (+8v)
244       X:000024                     DC      (DZ-0800)           ; S-   [V4]         (-5v)
245       X:000025                     DC      (DZ+1000)           ; S+   [V5]         (+5v)
246       X:000026                     DC      (DZ-1200)           ; SW-  [V6]         (-9v)
247       X:000027                     DC      (DZ+0600)           ; SW+  [V7]         (+4v)
248       X:000028                     DC      (DZ-0000)           ; TG-  [V8]         (-9v)
249       X:000029                     DC      (DZ+0000)           ; TG+  [V9]         (+4v)
250       X:00002A                     DC      (DZ-1200)           ; P1-  [V10]            (-9v)
251       X:00002B                     DC      (DZ+0800)           ; P1+  [V11]            (+4v)
252       X:00002C                     DC      (DZ-1200)           ; P2-  [V12]            (-9v)
253       X:00002D                     DC      (DZ+0800)           ; P2+  [V13]            (+4v)
254       X:00002E                     DC      (DZ-1200)           ; P3-  [V14]            (-9v)
255       X:00002F                     DC      (DZ+0800)           ; P3+  [V15]            (+4v)
256    
257                        ;*****************************************************************************
258                        ;   INITIALIZE X MEMORY
259                        ;*****************************************************************************
260                        ;        R2L   _______________  ________________ R1L
261                        ;        R3L   ______________ || _______________ R3R
262                        ;        SW    _____________ |||| ______________ R2R
263                        ;        TG    ____________ |||||| _____________ R1R
264                        ;        ST1   ___________ |||||||| ____________ RG
265                        ;        ST2   __________ |||||||||| ___________ IPC
266                        ;        ST3   _________ |||||||||||| __________ FINT+
267                        ;        IM1   ________ |||||||||||||| _________ FINT-
268                        ;        IM2   _______ |||||||||||||||| ________ FRST
269                        ;        IM3   ______ |||||||||||||||||| _______ CONVST
270                        ;                    ||||||||||||||||||||


Motorola DSP56300 Assembler  Version 6.3.4   12-01-12  18:29:00  gcam_ccid-21.asm  Page 6



271    
272       X:000040                      ORG X:MPP              ; reset/hold state
273       X:000040                     DC  %000001001001011011000011
274    
275       X:000042                     ORG X:IPCLKS            ; input clamp
276       X:000042                     DC  %000001001001011011010011
277       X:000043                     DC  %000001001001011011000011
278    
279       X:000044                     ORG X:TCLKS             ; read temp monitor
280       X:000044                     DC  %000001001001011011000010
281       X:000045                     DC  %000001001001011011000011
282    
283       X:000048                     ORG X:PCLKS_FTU         ; frame transfer upper P2-P1-P3-P2
284       X:000048                     DC  %000001101101011011000011   ; reverse direction
285       X:000049                     DC  %000000100101011011000011
286       X:00004A                     DC  %000010110101011011000011
287       X:00004B                     DC  %000010010001011011000011
288       X:00004C                     DC  %000011011001011011000011
289       X:00004D                     DC  %000001001001011011000011
290    
291       X:000050                     ORG X:PCLKS_RDU         ; parallel transfer upper P2-P1-P3-P2
292       X:000050                     DC  %000001001101011011010011   ; reverse direction
293       X:000051                     DC  %000001000101011011010011
294       X:000052                     DC  %000001010101011011010011
295       X:000053                     DC  %000001010001011011000011
296       X:000054                     DC  %000001011001011011010011
297       X:000055                     DC  %000001001001011011010011
298    
299       X:000058                     ORG X:PCLKS_FLU         ; parallel flush upper P2-P1-P3-P2
300       X:000058                     DC  %000001101101011011000011   ; reverse direction
301       X:000059                     DC  %000000100101011011000011
302       X:00005A                     DC  %000010110101011011000011
303       X:00005B                     DC  %000010010001011011000011
304       X:00005C                     DC  %000011011001011011000011
305       X:00005D                     DC  %000001001001011011000011
306    
307       X:000060                     ORG X:PCLKS_FTL         ; frame transfer lower P2-P3-P1-P2
308       X:000060                     DC  %000011011001011011000011   ; normal direction
309       X:000061                     DC  %000010010001011011000011
310       X:000062                     DC  %000010110101011011000011
311       X:000063                     DC  %000000100101011011000011
312       X:000064                     DC  %000001101101011011000011
313       X:000065                     DC  %000001001001011011000011
314    
315       X:000068                     ORG X:PCLKS_RDL         ; parallel transfer lower P2-P3-P1-P2
316       X:000068                     DC  %000001011001011011010011   ; normal direction
317       X:000069                     DC  %000001010001011011010011
318       X:00006A                     DC  %000001010101011011010011
319       X:00006B                     DC  %000001000101011011010011
320       X:00006C                     DC  %000001001101011011010011
321       X:00006D                     DC  %000001001001011011000011
322    
323       X:000070                     ORG X:PCLKS_FLL         ; parallel flush lower P2-P3-P1-P2
324       X:000070                     DC  %000011011001011011000011   ; normal direction


Motorola DSP56300 Assembler  Version 6.3.4   12-01-12  18:29:00  gcam_ccid-21.asm  Page 7



325       X:000071                     DC  %000010010001011011000011
326       X:000072                     DC  %000010110101011011000011
327       X:000073                     DC  %000000100101011011000011
328       X:000074                     DC  %000001101101011011000011
329       X:000075                     DC  %000001001001011011000011
330    
331       X:000078                     ORG X:PCLKS_FLB         ; parallel flush both
332       X:000078                     DC  %000001111001011011000011   ; place-holder
333       X:000079                     DC  %000000110001011011000011
334       X:00007A                     DC  %000010110101011011000011
335       X:00007B                     DC  %000010000101011011000011
336       X:00007C                     DC  %000011001101011011000011
337       X:00007D                     DC  %000001001001011011000011
338    
339       X:000080                     ORG X:INT_L             ; reset and first integration
340       X:000080                     DC  %000001001001011011100011   ; RG ON  FRST ON
341       X:000081                     DC  %000001001001011011000011   ; RG OFF
342       X:000082                     DC  %000001001001011011000001   ; FRST OFF
343       X:000083                     DC  %000001001001011011001001   ; FINT+ ON
344       X:000084                     DC  %000001001001011011000001   ; FINT+ OFF
345    
346       X:000088                     ORG X:INT_H             ; second integration and A to D
347       X:000088                     DC  %000001001000011011000101   ; FINT- ON
348       X:000089                     DC  %000001001000011011000001   ; FINT- OFF
349       X:00008A                     DC  %000001001000011011000000   ; /CONVST ON
350       X:00008B                     DC  %000001001000011011000001   ; /CONVST OFF
351       X:00008C                     DC  %000001001001011011100011   ; FRST ON RG ON
352    
353       X:000090                     ORG X:SCLKS_R           ; serial shift (right) S2-S1-S3-S2
354       X:000090                     DC  %000001001001001001000001
355       X:000091                     DC  %000001001001101101000001
356       X:000092                     DC  %000001001001100100000001
357       X:000093                     DC  %000001001001110110000001
358       X:000094                     DC  %000001001001010010000001
359       X:000095                     DC  %000001001001011011000001
360    
361       X:000098                     ORG X:SCLKS_FLR         ; serial flush (right) S2-S1-S3-S2
362       X:000098                     DC  %000001001001001001100011
363       X:000099                     DC  %000001001001101101100011
364       X:00009A                     DC  %000001001001100100100011
365       X:00009B                     DC  %000001001001110110100011
366       X:00009C                     DC  %000001001001010010100011
367       X:00009D                     DC  %000001001001011011100011
368    
369       X:0000A0                     ORG X:SCLKS_L           ; serial shift (left) S2-S3-S1-S2
370       X:0000A0                     DC  %000001001001010010000001
371       X:0000A1                     DC  %000001001001110110000001
372       X:0000A2                     DC  %000001001001100100000001
373       X:0000A3                     DC  %000001001001101101000001
374       X:0000A4                     DC  %000001001001001001000001
375       X:0000A5                     DC  %000001001001011011000001
376    
377       X:0000A8                     ORG X:SCLKS_FLL         ; serial flush (left) S2-S3-S1-S2
378       X:0000A8                     DC  %000001001001010010100011


Motorola DSP56300 Assembler  Version 6.3.4   12-01-12  18:29:00  gcam_ccid-21.asm  Page 8



379       X:0000A9                     DC  %000001001001110110100011
380       X:0000AA                     DC  %000001001001100100100011
381       X:0000AB                     DC  %000001001001101101100011
382       X:0000AC                     DC  %000001001001001001100011
383       X:0000AD                     DC  %000001001001011011100011
384    
385       X:0000B0                     ORG X:SCLKS_B           ; serial shift (both)   not used, not changed
386       X:0000B0                     DC  %000001001001010001000001
387       X:0000B1                     DC  %000001001001110101000001
388       X:0000B2                     DC  %000001001001100100000001
389       X:0000B3                     DC  %000001001001101110000001
390       X:0000B4                     DC  %000001001001001010000001
391       X:0000B5                     DC  %000001001001011011000001
392    
393       X:0000B8                     ORG X:SCLKS_FLB         ; serial flush (both)   not used, not changed
394       X:0000B8                     DC  %000001001001010001100011
395       X:0000B9                     DC  %000001001001110101100011
396       X:0000BA                     DC  %000001001001100100100011
397       X:0000BB                     DC  %000001001001101110100011
398       X:0000BC                     DC  %000001001001001010100011
399       X:0000BD                     DC  %000001001001011011100011
400    
401       X:0000C0                     ORG X:SCLKS_FF          ; serial flush (fast)
402       X:0000C0                     DC  %000001001001111111100011
403       X:0000C1                     DC  %000001001001111111100011
404       X:0000C2                     DC  %000001001001111111100011
405       X:0000C3                     DC  %000001001001011011000011
406       X:0000C4                     DC  %000001001001011011000011   ; dummy code
407       X:0000C5                     DC  %000001001001011011000011   ; dummy code
408    
409    
410                        ;*******************************************************************************
411                        ;   GENERAL COMMENTS
412                        ;*******************************************************************************
413                        ; Hardware RESET causes download from serial port (code in EPROM)
414                        ; R0 is a pointer to sequence fragments
415                        ; R1 is a pointer used by send/receive routines
416                        ; R2 is a pointer to the current data location
417                        ; See dspdvr.h for command and opflag definitions
418                        ;*******************************************************************************
419                        ;   INITIALIZE INTERRUPT VECTORS
420                        ;*******************************************************************************
421       P:000000                     ORG     P:$0000
422       P:000000 0C0100              JMP     START
423                        ;*******************************************************************************
424                        ;   MAIN PROGRAM
425                        ;*******************************************************************************
426       P:000100                     ORG     P:START
427       P:000100 0003F8  SET_MODE    ORI     #$3,MR                  ; mask all interrupts
428       P:000101 08F4B6              MOVEP   #$FFFC21,X:AAR3         ; PERIPH $FFF000--$FFFFFF
                   FFFC21
429       P:000103 08F4B8              MOVEP   #$D00909,X:AAR1         ; EEPROM $D00000--$D07FFF 32K
                   D00909
430       P:000105 08F4B9              MOVEP   #$000811,X:AAR0         ; SRAM X $000000--$00FFFF 64K


Motorola DSP56300 Assembler  Version 6.3.4   12-01-12  18:29:00  gcam_ccid-21.asm  Page 9



                   000811
431       P:000107 08F4BB              MOVEP   #WS,X:BCR               ; Set periph wait states
                   073FE1
432       P:000109 0505A0              MOVE    #SEQ-1,M0               ; Set sequencer address modulus
433    
434                        PORTB_SETUP
435       P:00010A 08F484  PORTB_SETUP MOVEP   #>$1,X:PCRB             ; set PB[15..0] GPIO
                   000001
436    
437                        PORTD_SETUP
438       P:00010C 07F42F  PORTD_SETUP MOVEP   #>$0,X:PCRD             ; GPIO PD0=TM PD1=GAIN
                   000000
439       P:00010E 07F42E              MOVEP   #>$3,X:PRRD             ; PD2=/ENRX PD3=/ENTX
                   000003
440       P:000110 07F42D              MOVEP   #>$0,X:PDRD             ; PD4=RXRDY
                   000000
441    
442       P:000112 07F436  SSI_SETUP   MOVEP   #>$032070,X:CRB         ; async, LSB, enable TE RE
                   032070
443       P:000114 07F435              MOVEP   #>$140803,X:CRA         ; 10 Mbps, 16 bit word
                   140803
444       P:000116 07F43F              MOVEP   #>$3F,X:PCRC            ; enable ESSI
                   00003F
445    
446                        PORTE_SETUP
447       P:000118 07F41F  PORTE_SETUP MOVEP   #$0,X:PCRE              ; enable GPIO, disable SCI
                   000000
448       P:00011A 07F41E              MOVEP   #>$1,X:PRRE             ; PE0=SHUTTER
                   000001
449       P:00011C 07F41D              MOVEP   #>$0,X:PDRE             ;
                   000000
450    
451       P:00011E 07F40F  SET_TIMER   MOVEP   #$300A10,X:TCSR0        ; Pulse mode, no prescale
                   300A10
452       P:000120 07F40E              MOVEP   #$0,X:TLR0              ; timer reload value
                   000000
453       P:000122 07F00D              MOVEP   X:USEC,X:TCPR0          ; timer compare value
                   000013
454       P:000124 07F40B              MOVEP   #$308A10,X:TCSR1        ; Pulse mode, prescaled
                   308A10
455       P:000126 07F40A              MOVEP   #$0,X:TLR1              ; timer reload value
                   000000
456       P:000128 07F009              MOVEP   X:EXP_TIME,X:TCPR1      ; timer compare value
                   000010
457       P:00012A 07F403              MOVEP   #>$9C3F,X:TPLR          ; timer prescale ($9C3F=1ms 80MHz)
                   009C3F
458    
459       P:00012C 08F4AF  DMA_SETUP   MOVEP   #PIX,X:DSR0             ; set DMA source
                   000300
460       P:00012E 08F4AD              MOVEP   #$0,X:DCO0              ; set DMA counter
                   000000
461       P:000130 0A1680  FIBER       JCLR    #$0,X:LINK,RS485        ; set up optical
                   000136
462       P:000132 08F4AE              MOVEP   #>TXREG,X:DDR0          ; set DMA destination


Motorola DSP56300 Assembler  Version 6.3.4   12-01-12  18:29:00  gcam_ccid-21.asm  Page 10



                   FFFF85
463       P:000134 08F4AC              MOVEP   #>$080255,X:DCR0        ; DMA word xfer, /IRQA, src+1
                   080255
464       P:000136 0A16A0  RS485       JSET    #$0,X:LINK,ENDDP        ; set up RS485
                   00013C
465       P:000138 08F4AE              MOVEP   #>TXD,X:DDR0            ; DMA destination
                   FFFFBC
466       P:00013A 08F4AC              MOVEP   #>$085A51,X:DCR0        ; DMA word xfer, TDE0, src+1
                   085A51
467       P:00013C 000000  ENDDP       NOP                             ;
468    
469       P:00013D 0BF080  INIT_SETUP  JSR     MPPHOLD                 ;
                   0001C7
470       P:00013F 0BF080              JSR     SET_GAIN                ;
                   000388
471       P:000141 0BF080              JSR     SET_DACS                ;
                   00033E
472       P:000143 0BF080              JSR     SET_SCLKS               ;
                   000392
473    
474       P:000145 0BF080  WAIT_CMD    JSR     FLUSHROWS               ; added 30 Mar 07 - RAT
                   0001E6
475       P:000147 0A1680              JCLR    #$0,X:LINK,WAITB        ; check for cmd ready
                   00014B
476       P:000149 01AD84              JCLR    #$4,X:PDRD,ECHO         ; fiber link (single-fiber)
                   000155
477       P:00014B 0A16A0  WAITB       JSET    #$0,X:LINK,ENDW         ;
                   00014F
478       P:00014D 01B787              JCLR    #7,X:SSISR,ECHO         ; wire link
                   000155
479       P:00014F 000000  ENDW        NOP                             ;
480    
481       P:000150 0BF080              JSR     READ16                  ; wait for command word
                   0002D9
482       P:000152 540000              MOVE    A1,X:CMD                ; cmd in X:CMD
483       P:000153 0BF080              JSR     CMD_FIX                 ; interpret command word
                   0003BD
484    
485       P:000155 0A0081  ECHO        JCLR    #$1,X:CMD,GET           ; test for DSP_ECHO command
                   00015C
486       P:000157 0BF080              JSR     READ16                  ;
                   0002D9
487       P:000159 0BF080              JSR     WRITE16                 ;
                   0002E9
488       P:00015B 0A0001              BCLR    #$1,X:CMD               ;
489    
490       P:00015C 0A0082  GET         JCLR    #$2,X:CMD,PUT           ; test for DSP_GET command
                   000161
491       P:00015E 0BF080              JSR     MEM_SEND                ;
                   000331
492       P:000160 0A0002              BCLR    #$2,X:CMD               ;
493    
494       P:000161 0A0083  PUT         JCLR    #$3,X:CMD,EXP_START     ; test for DSP_PUT command
                   000166


Motorola DSP56300 Assembler  Version 6.3.4   12-01-12  18:29:00  gcam_ccid-21.asm  Page 11



495       P:000163 0BF080              JSR     MEM_LOAD                ;
                   000325
496       P:000165 0A0003              BCLR    #$3,X:CMD               ;
497    
498       P:000166 0A0086  EXP_START   JCLR    #$6,X:CMD,FASTFLUSH     ; test for EXPOSE command
                   000173
499       P:000168 0BF080              JSR     MPPHOLD                 ;
                   0001C7
500       P:00016A 62F400              MOVE    #PIX,R2                 ; set data pointer
                   000300
501       P:00016C 07F009              MOVEP   X:EXP_TIME,X:TCPR1      ; timer compare value
                   000010
502       P:00016E 0A012F              BSET    #$F,X:OPFLAGS           ; set exp_in_progress flag
503       P:00016F 0A0006              BCLR    #$6,X:CMD               ;
504    
505       P:000170 0A0181              JCLR    #$1,X:OPFLAGS,FASTFLUSH ; check for AUTO_FLUSH
                   000173
506       P:000172 0A0024              BSET    #$4,X:CMD               ;
507    
508       P:000173 0A0084  FASTFLUSH   JCLR    #$4,X:CMD,BEAM_ON       ; test for FLUSH command
                   00017E
509       P:000175 0BF080              JSR     FLUSHFRAME              ; fast FLUSH
                   0001F5
510       P:000177 0BF080              JSR     FLUSHFRAME              ; fast FLUSH
                   0001F5
511       P:000179 0BF080              JSR     FLUSHFRAME              ; fast FLUSH
                   0001F5
512       P:00017B 0BF080              JSR     FLUSHLINE               ; clear serial register
                   0001D4
513       P:00017D 0A0004              BCLR    #$4,X:CMD               ;
514    
515       P:00017E 0A0085  BEAM_ON     JCLR    #$5,X:CMD,EXPOSE        ; test for open shutter
                   000182
516       P:000180 011D20              BSET    #$0,X:PDRE              ; set SHUTTER
517       P:000181 0A0005              BCLR    #$5,X:CMD               ;
518    
519       P:000182 0A018F  EXPOSE      JCLR    #$F,X:OPFLAGS,BEAM_OFF  ; check exp_in_progress flag
                   00018F
520       P:000184 0BF080              JSR     MPPHOLD                 ;
                   0001C7
521       P:000186 0BF080              JSR     M_TIMER                 ;
                   000382
522       P:000188 0A010F              BCLR    #$F,X:OPFLAGS           ; clear exp_in_progress flag
523    
524       P:000189 0A0182  OPT_A       JCLR    #$2,X:OPFLAGS,OPT_B     ; check for AUTO_SHUTTER
                   00018C
525       P:00018B 0A0027              BSET    #$7,X:CMD               ; prep to close shutter
526       P:00018C 0A0184  OPT_B       JCLR    #$4,X:OPFLAGS,BEAM_OFF  ; check for AUTO_READ
                   00018F
527       P:00018E 0A0028              BSET    #$8,X:CMD               ; prep for full readout
528    
529       P:00018F 0A0087  BEAM_OFF    JCLR    #$7,X:CMD,READ_CCD      ; test for shutter close
                   000193
530       P:000191 011D00              BCLR    #$0,X:PDRE              ; clear SHUTTER


Motorola DSP56300 Assembler  Version 6.3.4   12-01-12  18:29:00  gcam_ccid-21.asm  Page 12



531       P:000192 0A0007              BCLR    #$7,X:CMD               ;
532    
533       P:000193 0A0088  READ_CCD    JCLR    #$8,X:CMD,AUTO_WIPE     ; test for READCCD command
                   0001A9
534       P:000195 0BF080              JSR     FRAME                   ; frame transfer
                   000215
535                        ;           JSR     IPC_CLAMP               ; discharge ac coupling cap
536       P:000197 0BF080              JSR     FLUSHROWS               ; vskip
                   0001E6
537       P:000199 060200              DO      X:NROWS,END_READ        ; read the array
                   0001A6
538       P:00019B 0BF080              JSR     FLUSHLINE               ;
                   0001D4
539       P:00019D 0BF080              JSR     PARALLEL                ;
                   000204
540       P:00019F 0BF080              JSR     FLUSHPIX                ; hskip
                   0001DB
541       P:0001A1 0A0120              BSET    #$0,X:OPFLAGS           ; set first pixel flag
542       P:0001A2 0BF080              JSR     READPIX                 ;
                   000239
543       P:0001A4 0A0100              BCLR    #$0,X:OPFLAGS           ; clear first pixel flag
544       P:0001A5 0BF080              JSR     READLINE                ;
                   000237
545       P:0001A7 000000  END_READ    NOP                             ;
546       P:0001A8 0A0008              BCLR    #$8,X:CMD               ;
547    
548       P:0001A9 0A0089  AUTO_WIPE   JCLR    #$9,X:CMD,HH_DACS       ; test for AUTOWIPE command
                   0001AB
549                        ;           BSET    #$E,X:OPFLAGS           ;
550                        ;           BSET    #$5,X:OPFLAGS           ;
551                        ;           JSR     FL_CLOCKS               ; flush one parallel row
552                        ;           JSR     READLINE                ;
553                        ;           BCLR    #$9,X:CMD               ;
554    
555       P:0001AB 0A008A  HH_DACS     JCLR    #$A,X:CMD,HH_TEMP       ; test for HH_SYNC command
                   0001B0
556       P:0001AD 0BF080              JSR     SET_DACS                ;
                   00033E
557       P:0001AF 0A000A              BCLR    #$A,X:CMD               ;
558    
559       P:0001B0 0A008B  HH_TEMP     JCLR    #$B,X:CMD,HH_TEC        ; test for HH_TEMP command
                   0001B5
560       P:0001B2 0BF080              JSR     TEMP_READ               ; perform housekeeping chores
                   00035B
561       P:0001B4 0A000B              BCLR    #$B,X:CMD               ;
562    
563       P:0001B5 0A008C  HH_TEC      JCLR    #$C,X:CMD,HH_OTHER      ; test for HH_TEC command
                   0001BA
564       P:0001B7 0BF080              JSR     TEMP_SET                ; set the TEC value
                   000374
565       P:0001B9 0A000C              BCLR    #$C,X:CMD               ;
566    
567       P:0001BA 0A008D  HH_OTHER    JCLR    #$D,X:CMD,END_CODE      ; test for HH_OTHER command
                   0001C3


Motorola DSP56300 Assembler  Version 6.3.4   12-01-12  18:29:00  gcam_ccid-21.asm  Page 13



568       P:0001BC 0BF080              JSR     SET_GAIN                ;
                   000388
569       P:0001BE 0BF080              JSR     SET_SCLKS               ;
                   000392
570       P:0001C0 0BF080              JSR     SET_USEC                ;
                   00038F
571       P:0001C2 0A000D              BCLR    #$D,X:CMD               ;
572    
573       P:0001C3 0A0185  END_CODE    JCLR    #$5,X:OPFLAGS,WAIT_CMD  ; check for AUTO_WIPE
                   000145
574       P:0001C5 0A0029              BSET    #$9,X:CMD               ;
575       P:0001C6 0C0145              JMP     WAIT_CMD                ; Get next command
576    
577                        ;*****************************************************************************
578                        ;   HOLD (MPP MODE)
579                        ;*****************************************************************************
580       P:0001C7 07B080  MPPHOLD     MOVEP   X:MPP,Y:<<SEQREG        ;
                   000040
581       P:0001C9 00000C              RTS                             ;
582    
583                        ;*****************************************************************************
584                        ;   INPUT CLAMP
585                        ;*****************************************************************************
586       P:0001CA 07B080  IPC_CLAMP   MOVEP   X:IPCLKS,Y:<<SEQREG     ;
                   000042
587       P:0001CC 44F400              MOVE    #>HOLD_IPC,X0           ;
                   001F40
588       P:0001CE 06C420              REP     X0                      ; $1F4O=100 us
589       P:0001CF 000000              NOP                             ;
590       P:0001D0 07B080              MOVEP   X:(IPCLKS+1),Y:<<SEQREG ;
                   000043
591       P:0001D2 000000              NOP                             ;
592       P:0001D3 00000C              RTS                             ;
593    
594                        ;*****************************************************************************
595                        ;   FLUSHLINE  (FAST FLUSH)
596                        ;*****************************************************************************
597       P:0001D4 30C000  FLUSHLINE   MOVE    #SCLKS_FF,R0            ; initialize pointer
598       P:0001D5 060680              DO      #SEQ,ENDFF              ;
                   0001D9
599       P:0001D7 079880              MOVEP   X:(R0)+,Y:<<SEQREG      ;
600       P:0001D8 0620A0              REP     #HOLD_FF                ;
601       P:0001D9 000000              NOP                             ;
602       P:0001DA 00000C  ENDFF       RTS                             ;
603    
604                        ;*****************************************************************************
605                        ;   FLUSHPIX (HSKIP)
606                        ;*****************************************************************************
607       P:0001DB 060B00  FLUSHPIX    DO      X:HSKIP,ENDFP           ;
                   0001E4
608       P:0001DD 60F000              MOVE    X:SCLKS_FLR,R0          ; initialize pointer (modified -RAT)
                   000098
609       P:0001DF 060680              DO      #SEQ,ENDHCLK            ;
                   0001E3


Motorola DSP56300 Assembler  Version 6.3.4   12-01-12  18:29:00  gcam_ccid-21.asm  Page 14



610       P:0001E1 079880              MOVEP   X:(R0)+,Y:<<SEQREG      ;
611       P:0001E2 060FA0              REP     #HOLD_S                 ;
612       P:0001E3 000000              NOP                             ;
613       P:0001E4 000000  ENDHCLK     NOP                             ;
614       P:0001E5 00000C  ENDFP       RTS                             ;
615    
616                        ;*****************************************************************************
617                        ;   FLUSHROWS (VSKIP)
618                        ;*****************************************************************************
619       P:0001E6 060A00  FLUSHROWS   DO      X:VSKIP,ENDVSKIP        ;
                   0001F3
620       P:0001E8 0A1782              JCLR    #$2,X:PDIR,FLUSHRU      ; check for parallel direction
                   0001ED
621       P:0001EA 306800              MOVE    #PCLKS_RDL,R0           ; initialize pointer (modified -RAT)
622       P:0001EB 0AF080              JMP     FLUSHRL                 ; lower direction
                   0001EE
623       P:0001ED 305000  FLUSHRU     MOVE    #PCLKS_RDU,R0           ; upper direction
624       P:0001EE 060680  FLUSHRL     DO      #SEQ,ENDVCLK            ;
                   0001F2
625       P:0001F0 079880              MOVEP   X:(R0)+,Y:<<SEQREG      ;
626       P:0001F1 067CA0              REP     #HOLD_FL                ;
627       P:0001F2 000000              NOP                             ;
628       P:0001F3 000000  ENDVCLK     NOP                             ;
629       P:0001F4 00000C  ENDVSKIP    RTS                             ;
630    
631                        ;*****************************************************************************
632                        ;   FLUSHFRAME
633                        ;*****************************************************************************
634       P:0001F5 060500  FLUSHFRAME  DO      X:NFLUSH,ENDFLFR        ;
                   000202
635       P:0001F7 0A1782              JCLR    #$2,X:PDIR,FLUSHFU      ; check for parallel direction
                   0001FC
636       P:0001F9 307000  FL_CLOCKS   MOVE    #PCLKS_FLL,R0           ; initialize pointer (modified -RAT)
637       P:0001FA 0AF080              JMP     FLUSHFL                 ; lower direction
                   0001FD
638       P:0001FC 305800  FLUSHFU     MOVE    #PCLKS_FLU,R0           ; upper direction
639       P:0001FD 060680  FLUSHFL     DO      #SEQ,ENDFLCLK           ;
                   000201
640       P:0001FF 079880              MOVEP   X:(R0)+,Y:<<SEQREG      ;
641       P:000200 067CA0              REP     #HOLD_FL                ;
642       P:000201 000000              NOP                             ;
643       P:000202 000000  ENDFLCLK    NOP                             ;
644       P:000203 00000C  ENDFLFR     RTS                             ;
645    
646                        ;*****************************************************************************
647                        ;   PARALLEL TRANSFER (READOUT)
648                        ;*****************************************************************************
649       P:000204 060800  PARALLEL    DO      X:VBIN,ENDPT            ;
                   000213
650       P:000206 0A1782              JCLR    #$2,X:PDIR,PARROU       ; check for parallel direction
                   00020B
651       P:000208 306800              MOVE    #PCLKS_RDL,R0           ; initialize pointer (modified -RAT)
652       P:000209 0AF080              JMP     P_CLOCKS                ; lower direction
                   00020C


Motorola DSP56300 Assembler  Version 6.3.4   12-01-12  18:29:00  gcam_ccid-21.asm  Page 15



653       P:00020B 306800  PARROU      MOVE    #PCLKS_RDL,R0           ; upper direction (test - 28jun07 RAT)
654       P:00020C 060680  P_CLOCKS    DO      #SEQ,ENDPCLK            ;
                   000212
655       P:00020E 079880              MOVEP   X:(R0)+,Y:<<SEQREG      ;
656       P:00020F 44F400              MOVE    #>HOLD_P,X0             ;
                   00020A
657       P:000211 06C420              REP     X0                      ; $317=10us per phase
658       P:000212 000000              NOP                             ;
659       P:000213 000000  ENDPCLK     NOP                             ;
660       P:000214 00000C  ENDPT       RTS                             ;
661    
662                        ;*****************************************************************************
663                        ;   PARALLEL TRANSFER (FRAME TRANSFER)
664                        ;*****************************************************************************
665       P:000215 0A1782  FRAME       JCLR    #$2,X:PDIR,FLUSHFTU      ; check for parallel direction (modifi
ed -RAT)
                   00021B
666       P:000217 07B080              MOVEP   X:(PCLKS_FTL),Y:<<SEQREG ; 100 us CCD47 pause
                   000060
667       P:000219 0AF080              JMP     FLUSHFTL                 ; lower direction
                   00021D
668       P:00021B 07B080  FLUSHFTU    MOVEP   X:(PCLKS_FTL),Y:<<SEQREG ; upper direction (test - 28jun07 RAT)
                   000060
669       P:00021D 44F400  FLUSHFTL    MOVE    #>$1F40,X0               ;
                   001F40
670       P:00021F 06C420              REP     X0                       ; $1F40=100 usec
671       P:000220 000000              NOP                              ;
672       P:000221 0A1782              JCLR    #$2,X:PDIR,FTU_CLOCKS    ; check for parallel direction (modifi
ed -RAT)
                   00022D
673       P:000223 060400              DO      X:NFT,ENDFTL             ;
                   00022B
674       P:000225 306000              MOVE    #PCLKS_FTL,R0            ; initialize seq pointer
675       P:000226 060680              DO      #SEQ,ENDFTLCLK           ;
                   00022A
676       P:000228 079880              MOVEP   X:(R0)+,Y:<<SEQREG       ;
677       P:000229 067CA0              REP     #HOLD_FT                 ;
678       P:00022A 000000              NOP                              ;
679       P:00022B 000000  ENDFTLCLK   NOP                              ;
680       P:00022C 00000C  ENDFTL      RTS                              ;
681    
682       P:00022D 060400  FTU_CLOCKS  DO      X:NFT,ENDFTU             ;
                   000235
683       P:00022F 306000              MOVE    #PCLKS_FTL,R0            ; initialize seq pointer (test - 28jun
07 RAT)
684       P:000230 060680              DO      #SEQ,ENDFTUCLK           ;
                   000234
685       P:000232 079880              MOVEP   X:(R0)+,Y:<<SEQREG       ;
686       P:000233 067CA0              REP     #HOLD_FT                 ;
687       P:000234 000000              NOP                              ;
688       P:000235 000000  ENDFTUCLK   NOP                              ;
689       P:000236 00000C  ENDFTU      RTS                              ;
690    
691                        ;*****************************************************************************


Motorola DSP56300 Assembler  Version 6.3.4   12-01-12  18:29:00  gcam_ccid-21.asm  Page 16



692                        ;   READLINE SUBROUTINE
693                        ;*****************************************************************************
694       P:000237 060300  READLINE    DO      X:NCOLS,ENDRL           ;
                   0002D7
695       P:000239 07B080  READPIX     MOVEP   X:(INT_L),Y:<<SEQREG    ; FRST=ON RG=ON
                   000080
696                                    DUP     HOLD_RG                 ; macro
697  m                                 NOP                             ;
698  m                                 ENDM                            ; end macro
707       P:000243 07B080              MOVEP   X:(INT_L+1),Y:<<SEQREG  ; RG=OFF
                   000081
708       P:000245 07B080              MOVEP   X:(INT_L+2),Y:<<SEQREG  ; FRST=OFF
                   000082
709       P:000247 061FA0              REP     #HOLD_SIG               ; preamp settling time
710                        ;           REP     #$F                     ; preamp settling
711       P:000248 000000              NOP                             ;
712       P:000249 07B080  INT1        MOVEP   X:(INT_L+3),Y:<<SEQREG  ; FINT+=ON
                   000083
713       P:00024B 449300  SLEEP1      MOVE    X:USEC,X0               ; sleep USEC * 12.5ns
714       P:00024C 06C420              REP     X0                      ;
715       P:00024D 000000              NOP                             ;
716       P:00024E 07B080              MOVEP   X:(INT_L+4),Y:<<SEQREG  ; FINT+=OFF
                   000084
717       P:000250 60B000  SERIAL      MOVE    X:SCLKS,R0              ; serial transfer
718       P:000251 060900              DO      X:HBIN,ENDSCLK          ;
                   0002B2
719                        S_CLOCKS    DUP     SEQ                     ;    macro
720  m                                 MOVEP   X:(R0)+,Y:<<SEQREG      ;
721  m                                 DUP     HOLD_S                  ;    macro
722  m                                 NOP                             ;
723  m                                 ENDM                            ;
724  m                                 ENDM                            ;
839       P:0002B3 061FA0  ENDSCLK     REP     #HOLD_SIG               ; preamp settling time
840       P:0002B4 000000              NOP                             ; (adjust with o'scope)
841       P:0002B5 08F4BB  GET_DATA    MOVEP   #WS5,X:BCR              ;
                   07BFE1
842       P:0002B7 000000              NOP                             ;
843       P:0002B8 000000              NOP                             ;
844       P:0002B9 044E21              MOVEP   Y:<<ADC_A,A             ; read ADC
845       P:0002BA 044F22              MOVEP   Y:<<ADC_B,B             ; read ADC
846       P:0002BB 08F4BB              MOVEP   #WS,X:BCR               ;
                   073FE1
847       P:0002BD 000000              NOP                             ;
848       P:0002BE 07B080  INT2        MOVEP   X:(INT_H),Y:<<SEQREG    ; FINT-=ON
                   000088
849       P:0002C0 449300  SLEEP2      MOVE    X:USEC,X0               ; sleep USEC * 20ns
850       P:0002C1 06C420              REP     X0                      ;
851       P:0002C2 000000              NOP                             ;
852       P:0002C3 07B080              MOVEP   X:(INT_H+1),Y:<<SEQREG  ; FINT-=OFF
                   000089
853       P:0002C5 5C7000              MOVE    A1,Y:(PIX)              ;
                   000300
854       P:0002C7 5D7000              MOVE    B1,Y:(PIX+1)            ;
                   000301


Motorola DSP56300 Assembler  Version 6.3.4   12-01-12  18:29:00  gcam_ccid-21.asm  Page 17



855       P:0002C9 06AFA0              REP     #HOLD_ADC               ; settling time
856       P:0002CA 000000              NOP                             ; (adjust for best noise)
857       P:0002CB 07B080  CONVST      MOVEP   X:(INT_H+2),Y:<<SEQREG  ; /CONVST=ON
                   00008A
858       P:0002CD 08DD2F              MOVEP   N5,X:DSR0               ; set DMA source
859       P:0002CE 000000              NOP                             ;
860       P:0002CF 000000              NOP                             ;
861       P:0002D0 07B080              MOVEP   X:(INT_H+3),Y:<<SEQREG  ; /CONVST=OFF MIN 40 NS
                   00008B
862       P:0002D2 07B080              MOVEP   X:(INT_H+4),Y:<<SEQREG  ; FRST=ON
                   00008C
863       P:0002D4 0A01A0              JSET    #$0,X:OPFLAGS,ENDCHK    ; check for first pixel
                   0002D7
864       P:0002D6 0AAC37              BSET    #$17,X:DCR0             ; enable DMA
865       P:0002D7 000000  ENDCHK      NOP                             ;
866       P:0002D8 00000C  ENDRL       RTS                             ;
867    
868                        ;*******************************************************************************
869                        ;   READ AND WRITE 16-BIT AND 24-BIT DATA
870                        ;*******************************************************************************
871       P:0002D9 0A1680  READ16      JCLR    #$0,X:LINK,RD16B        ; check RS485 or fiber
                   0002E1
872       P:0002DB 01AD84              JCLR    #$4,X:PDRD,*            ; wait for data in RXREG
                   0002DB
873       P:0002DD 5EF000              MOVE    Y:RXREG,A               ; bits 15..0
                   FFFF86
874       P:0002DF 0140C6              AND     #>$FFFF,A               ;
                   00FFFF
875       P:0002E1 0A16A0  RD16B       JSET    #$0,X:LINK,ENDRD16      ; check RS485 or fiber
                   0002E8
876       P:0002E3 01B787              JCLR    #7,X:SSISR,*            ; wait for RDRF to go high
                   0002E3
877       P:0002E5 54F000              MOVE    X:RXD,A1                ; read from ESSI
                   FFFFB8
878       P:0002E7 000000              NOP                             ;
879       P:0002E8 00000C  ENDRD16     RTS                             ; 16-bit word in A1
880    
881       P:0002E9 0A1680  WRITE16     JCLR    #$0,X:LINK,WR16B        ; check RS485 or fiber
                   0002ED
882       P:0002EB 5C7000              MOVE    A1,Y:TXREG              ; write bits 15..0
                   FFFF85
883       P:0002ED 0A16A0  WR16B       JSET    #$0,X:LINK,ENDWR16      ;
                   0002F3
884       P:0002EF 01B786              JCLR    #6,X:SSISR,*            ; wait for TDE
                   0002EF
885       P:0002F1 547000              MOVE    A1,X:TXD                ;
                   FFFFBC
886       P:0002F3 00000C  ENDWR16     RTS                             ;
887    
888       P:0002F4 0A1680  READ24      JCLR    #$0,X:LINK,RD24B        ; check RS485 or fiber
                   000302
889       P:0002F6 01AD84              JCLR    #$4,X:PDRD,*            ; wait for data in RXREG
                   0002F6
890       P:0002F8 5EF000              MOVE    Y:RXREG,A               ; bits 15..0


Motorola DSP56300 Assembler  Version 6.3.4   12-01-12  18:29:00  gcam_ccid-21.asm  Page 18



                   FFFF86
891       P:0002FA 0140C6              AND     #>$FFFF,A               ;
                   00FFFF
892       P:0002FC 0C1C20              ASR     #$10,A,A                ; shift right 16 bits
893       P:0002FD 01AD84              JCLR    #$4,X:PDRD,*            ; wait for data in RXREG
                   0002FD
894       P:0002FF 5CF000              MOVE    Y:RXREG,A1              ; bits 15..0
                   FFFF86
895       P:000301 0C1D20              ASL     #$10,A,A                ; shift left 16 bits
896       P:000302 0A16A0  RD24B       JSET    #$0,X:LINK,ENDRD24      ;
                   00030E
897       P:000304 01B787              JCLR    #7,X:SSISR,*            ; wait for RDRF to go high
                   000304
898       P:000306 56F000              MOVE    X:RXD,A                 ; read from ESSI
                   FFFFB8
899       P:000308 0C1C20              ASR     #$10,A,A                ; shift right 16 bits
900       P:000309 01B787              JCLR    #7,X:SSISR,*            ; wait for RDRF to go high
                   000309
901       P:00030B 54F000              MOVE    X:RXD,A1                ;
                   FFFFB8
902       P:00030D 0C1D20              ASL     #$10,A,A                ; shift left 16 bits
903       P:00030E 00000C  ENDRD24     RTS                             ; 24-bit word in A1
904    
905       P:00030F 0A1680  WRITE24     JCLR    #$0,X:LINK,WR24B        ; check RS485 or fiber
                   000318
906       P:000311 5C7000              MOVE    A1,Y:TXREG              ; send bits 15..0
                   FFFF85
907       P:000313 0C1C20              ASR     #$10,A,A                ; right shift 16 bits
908       P:000314 0610A0              REP     #$10                    ; wait for data sent
909       P:000315 000000              NOP                             ;
910       P:000316 5C7000              MOVE    A1,Y:TXREG              ; send bits 23..16
                   FFFF85
911       P:000318 0A16A0  WR24B       JSET    #$0,X:LINK,ENDWR24      ;
                   000324
912       P:00031A 01B786              JCLR    #6,X:SSISR,*            ; wait for TDE
                   00031A
913       P:00031C 547000              MOVE    A1,X:TXD                ; send bits 15..0
                   FFFFBC
914       P:00031E 0C1C20              ASR     #$10,A,A                ; right shift 16 bits
915       P:00031F 000000              NOP                             ; wait for flag update
916       P:000320 01B786              JCLR    #6,X:SSISR,*            ; wait for TDE
                   000320
917       P:000322 547000              MOVE    A1,X:TXD                ; send bits 23..16
                   FFFFBC
918       P:000324 00000C  ENDWR24     RTS                             ;
919    
920                        ;*****************************************************************************
921                        ;   LOAD NEW DATA VIA SSI PORT
922                        ;*****************************************************************************
923       P:000325 0D02F4  MEM_LOAD    JSR     READ24                  ; get memspace/address
924       P:000326 219100              MOVE    A1,R1                   ; load address into R1
925       P:000327 218400              MOVE    A1,X0                   ; store memspace code
926       P:000328 0D02F4              JSR     READ24                  ; get data
927       P:000329 0AD157              BCLR    #$17,R1                 ; clear memspace bit


Motorola DSP56300 Assembler  Version 6.3.4   12-01-12  18:29:00  gcam_ccid-21.asm  Page 19



928       P:00032A 0AC437  X_LOAD      JSET    #$17,X0,Y_LOAD          ;
                   00032D
929       P:00032C 546100              MOVE    A1,X:(R1)               ; load x memory
930       P:00032D 0AC417  Y_LOAD      JCLR    #$17,X0,END_LOAD        ;
                   000330
931       P:00032F 5C6100              MOVE    A1,Y:(R1)               ; load y memory
932       P:000330 00000C  END_LOAD    RTS                             ;
933    
934                        ;*****************************************************************************
935                        ;   SEND MEMORY CONTENTS VIA SSI PORT
936                        ;*****************************************************************************
937       P:000331 0D02F4  MEM_SEND    JSR     READ24                  ; get memspace/address
938       P:000332 219100              MOVE    A1,R1                   ; load address into R1
939       P:000333 218400              MOVE    A1,X0                   ; save memspace code
940       P:000334 0AD157              BCLR    #$17,R1                 ; clear memspace bit
941       P:000335 0AC437  X_SEND      JSET    #$17,X0,Y_SEND          ;
                   000338
942       P:000337 54E100              MOVE    X:(R1),A1               ; send x memory
943       P:000338 0AC417  Y_SEND      JCLR    #$17,X0,WRITE24         ;
                   00030F
944       P:00033A 5CE100              MOVE    Y:(R1),A1               ; send y memory
945       P:00033B 0D030F  SEND24      JSR     WRITE24                 ;
946       P:00033C 000000              NOP                             ;
947       P:00033D 00000C              RTS                             ;
948    
949                        ;*****************************************************************************
950                        ;   CCID-21 SET DAC VOLTAGES  DEFAULTS:  OD=18V  RD=10V  OG=-2V
951                        ;   PCLKS=+4V -6V SCLKS=+4V -4V SW=+5 -5V RG=+8V -2V B7=-6V  B5=+12 to +15V
952                        ;*****************************************************************************
953       P:00033E 0BF080  SET_DACS    JSR     SET_VBIAS               ;
                   000343
954       P:000340 0BF080              JSR     SET_VCLKS               ;
                   00034F
955       P:000342 00000C              RTS                             ;
956    
957       P:000343 08F4BB  SET_VBIAS   MOVEP   #WS5,X:BCR              ; add wait states
                   07BFE1
958       P:000345 331800              MOVE    #VBIAS,R3               ; bias voltages
959       P:000346 64F400              MOVE    #SIG_AB,R4              ; bias DAC registers
                   FFFF88
960       P:000348 060880              DO      #$8,ENDSETB             ; set bias voltages
                   00034B
961       P:00034A 44DB00              MOVE    X:(R3)+,X0              ;
962       P:00034B 4C5C00              MOVE    X0,Y:(R4)+              ;
963       P:00034C 08F4BB  ENDSETB     MOVEP   #WS,X:BCR               ;
                   073FE1
964       P:00034E 00000C              RTS                             ;
965    
966       P:00034F 08F4BB  SET_VCLKS   MOVEP   #WS5,X:BCR              ; add wait states
                   07BFE1
967       P:000351 332000              MOVE    #VCLK,R3                ; clock voltages
968       P:000352 64F400              MOVE    #CLK_AB,R4              ; clock DAC registers
                   FFFF90
969       P:000354 061080              DO      #$10,ENDSETV            ; set clock voltages


Motorola DSP56300 Assembler  Version 6.3.4   12-01-12  18:29:00  gcam_ccid-21.asm  Page 20



                   000357
970       P:000356 44DB00              MOVE    X:(R3)+,X0              ;
971       P:000357 4C5C00              MOVE    X0,Y:(R4)+              ;
972       P:000358 08F4BB  ENDSETV     MOVEP   #WS,X:BCR               ; re-set wait states
                   073FE1
973       P:00035A 00000C              RTS
974    
975                        ;*****************************************************************************
976                        ;   TEMP MONITOR ADC START AND CONVERT
977                        ;*****************************************************************************
978       P:00035B 012D20  TEMP_READ   BSET    #$0,X:PDRD              ; turn on temp sensor
979       P:00035C 07F409              MOVEP   #$20,X:TCPR1            ; set timer compare value
                   000020
980       P:00035E 0BF080              JSR     M_TIMER                 ; wait for output to settle
                   000382
981    
982       P:000360 08F4BB              MOVEP   #WS3,X:BCR              ; set wait states for ADC
                   077FE1
983       P:000362 07B080              MOVEP   X:TCLKS,Y:<<SEQREG      ; assert /CONVST
                   000044
984       P:000364 0604A0              REP     #$4                     ;
985       P:000365 000000              NOP                             ;
986       P:000366 07B080              MOVEP   X:(TCLKS+1),Y:<<SEQREG  ; deassert /CONVST and wait
                   000045
987       P:000368 0650A0              REP     #$50                    ;
988       P:000369 000000              NOP                             ;
989    
990       P:00036A 044C22              MOVEP   Y:<<ADC_B,A1            ; read ADC2
991       P:00036B 45F400              MOVE    #>$3FFF,X1              ; prepare 14-bit mask
                   003FFF
992       P:00036D 200066              AND     X1,A1                   ; get 14 LSBs
993       P:00036E 012D00              BCLR    #$0,X:PDRD              ; turn off temp sensor
994       P:00036F 0BCC4D              BCHG    #$D,A1                  ; 2complement to binary
995       P:000370 08F4BB              MOVEP   #WS,X:BCR               ; re-set wait states
                   073FE1
996       P:000372 541100              MOVE    A1,X:TEMP               ;
997       P:000373 00000C              RTS                             ;
998    
999       P:000374 08F4BB  TEMP_SET    MOVEP   #WS5,X:BCR              ; add wait states
                   07BFE1
1000      P:000376 000000              NOP                             ;
1001      P:000377 07B08A              MOVEP   X:TEC,Y:<<TEC_REG       ; set TEC DAC
                   00001A
1002      P:000379 08F4BB              MOVEP   #WS,X:BCR               ; re-set wait states
                   073FE1
1003      P:00037B 00000C              RTS
1004   
1005                       ;*****************************************************************************
1006                       ;   MILLISECOND AND MICROSECOND TIMER MODULE
1007                       ;*****************************************************************************
1008      P:00037C 010F20  U_TIMER     BSET    #$0,X:TCSR0             ; start timer
1009      P:00037D 014F20              BTST    #$0,X:TCSR0             ; delay for flag update
1010   
1011      P:00037E 018F95              JCLR    #$15,X:TCSR0,*          ; wait for TCF flag


Motorola DSP56300 Assembler  Version 6.3.4   12-01-12  18:29:00  gcam_ccid-21.asm  Page 21



                   00037E
1012      P:000380 010F00              BCLR    #$0,X:TCSR0             ; stop timer, clear flag
1013      P:000381 00000C              RTS                             ; flags update during RTS
1014   
1015      P:000382 010B20  M_TIMER     BSET    #$0,X:TCSR1             ; start timer
1016      P:000383 014F20              BTST    #$0,X:TCSR0             ; delay for flag update
1017   
1018      P:000384 018B95              JCLR    #$15,X:TCSR1,*          ; wait for TCF flag
                   000384
1019      P:000386 010B00              BCLR    #$0,X:TCSR1             ; stop timer, clear flag
1020      P:000387 00000C              RTS                             ; flags update during RTS
1021   
1022                       ;*****************************************************************************
1023                       ;   SIGNAL-PROCESSING GAIN MODULE
1024                       ;*****************************************************************************
1025      P:000388 0A12A0  SET_GAIN    JSET    #$0,X:GAIN,HI_GAIN      ;
                   00038B
1026      P:00038A 012D01              BCLR    #$1,X:PDRD              ; set gain=0
1027      P:00038B 0A1280  HI_GAIN     JCLR    #$0,X:GAIN,END_GAIN     ;
                   00038E
1028      P:00038D 012D21              BSET    #$1,X:PDRD              ; set gain=1
1029      P:00038E 00000C  END_GAIN    RTS                             ;
1030   
1031                       ;*****************************************************************************
1032                       ;   SIGNAL-PROCESSING DUAL-SLOPE TIME MODULE
1033                       ;*****************************************************************************
1034      P:00038F 07F00D  SET_USEC    MOVEP   X:USEC,X:TCPR0          ; timer compare value
                   000013
1035      P:000391 00000C  END_USEC    RTS                             ;
1036   
1037                       ;*****************************************************************************
1038                       ;   SELECT SERIAL CLOCK SEQUENCE (IE OUTPUT AMPLIFIER)
1039                       ;*****************************************************************************
1040      P:000392 569400  SET_SCLKS   MOVE    X:OPCH,A                ; 0x1=right 0x2=left
1041      P:000393 44F400  RIGHT_AMP   MOVE    #>$1,X0                 ; 0x3=both  0x4=all
                   000001
1042      P:000395 200045              CMP     X0,A                    ;
1043      P:000396 0AF0A2              JNE     LEFT_AMP                ;
                   0003A0
1044      P:000398 46F400              MOVE    #>SCLKS_R,Y0            ; serial clock sequences
                   000090
1045      P:00039A 47F400              MOVE    #>SCLKS_FLR,Y1          ; serial flush sequences
                   000098
1046      P:00039C 75F400              MOVE    #PIX+1,N5               ; pointer to start of data
                   000301
1047      P:00039E 08F4AD              MOVEP   #>$0,X:DCO0             ; DMA counter
                   000000
1048      P:0003A0 44F400  LEFT_AMP    MOVE    #>$2,X0                 ;
                   000002
1049      P:0003A2 200045              CMP     X0,A                    ;
1050      P:0003A3 0AF0A2              JNE     BOTH_AMP                ;
                   0003AD
1051      P:0003A5 46F400              MOVE    #>SCLKS_L,Y0            ;
                   0000A0


Motorola DSP56300 Assembler  Version 6.3.4   12-01-12  18:29:00  gcam_ccid-21.asm  Page 22



1052      P:0003A7 47F400              MOVE    #>SCLKS_FLL,Y1          ;
                   0000A8
1053      P:0003A9 75F400              MOVE    #PIX,N5                 ;
                   000300
1054      P:0003AB 08F4AD              MOVEP   #>$0,X:DCO0             ;
                   000000
1055      P:0003AD 44F400  BOTH_AMP    MOVE    #>$3,X0                 ;
                   000003
1056      P:0003AF 200045              CMP     X0,A                    ;
1057      P:0003B0 0AF0A2              JNE     END_AMP                 ;
                   0003BA
1058      P:0003B2 46F400              MOVE    #>SCLKS_B,Y0            ;
                   0000B0
1059      P:0003B4 47F400              MOVE    #>SCLKS_FLB,Y1          ;
                   0000B8
1060      P:0003B6 75F400              MOVE    #PIX,N5                 ;
                   000300
1061      P:0003B8 08F4AD              MOVEP   #>$1,X:DCO0             ;
                   000001
1062      P:0003BA 463000  END_AMP     MOVE    Y0,X:SCLKS              ;
1063      P:0003BB 473100              MOVE    Y1,X:SCLKS_FL           ;
1064      P:0003BC 00000C              RTS                             ;
1065   
1066   
1067                       ;*****************************************************************************
1068                       ;   CMD.ASM -- ROUTINE TO INTERPRET AN 8-BIT COMMAND + COMPLEMENT
1069                       ;*****************************************************************************
1070                       ; Each command word is sent as two bytes -- the LSB has the command
1071                       ; and the MSB has the complement.
1072   
1073      P:0003BD 568000  CMD_FIX     MOVE    X:CMD,A                 ; extract cmd[7..0]
1074      P:0003BE 0140C6              AND     #>$FF,A                 ; and put in X1
                   0000FF
1075      P:0003C0 218500              MOVE    A1,X1                   ;
1076      P:0003C1 568000              MOVE    X:CMD,A                 ; extract cmd[15..8]
1077      P:0003C2 0C1ED0              LSR     #$8,A                   ; complement
1078      P:0003C3 57F417              NOT     A   #>$1,B              ; and put in A1
                   000001
1079      P:0003C5 0140C6              AND     #>$FF,A                 ;
                   0000FF
1080      P:0003C7 0C1E5D              ASL     X1,B,B                  ;
1081      P:0003C8 200065              CMP     X1,A                    ; compare X1 and A1
1082      P:0003C9 0AF0AA              JEQ     CMD_OK                  ;
                   0003CD
1083      P:0003CB 20001B  CMD_NG      CLR     B                       ; cmd word no good
1084      P:0003CC 000000              NOP                             ;
1085      P:0003CD 550000  CMD_OK      MOVE    B1,X:CMD                ; cmd word OK
1086      P:0003CE 000000              NOP                             ;
1087      P:0003CF 00000C  END_CMD     RTS                             ;
1088   
1089                                   END

0    Errors
0    Warnings


Motorola DSP56300 Assembler  Version 6.3.4   12-01-12  18:29:00  gcam_ccid-21.asm  Page 23





