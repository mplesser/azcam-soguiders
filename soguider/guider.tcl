# Steward Observatory Autoguiding Software 
# Written: 3/25/00 GDS
# Last modified: MPL for AzCam 19.05

# For Windows and Linux, added started hint about power
# This version does not use the camera and scope files
# This version requires local AzCamServer

set moddate 10/19/2020
set version 6.2

# change this to shutdown AzCam when guider shuts down
set shutdownazcam 1

# Comments ---------------------------------------------------------------------
# Configuration philosophy
#
# The telescope and camera environment is set by command-line parameters.
#
# Command syntax is: wish guider.tcl telid camindex telhost telport azcamhost azcamport
#
# Example for "90guider" at the 2.3m Bok telescope:
# "wish guider.tcl bok 90primeguider 10.30.1.24 5750 localhost 2402"
#
# If neither command-line parameter exists, the telescope is set to "notel" and the guider to "noazcam"
# To disable AZCAM server communication, set camera index to "noazcam", e.g., "guider.tcl bok noazcam"
#
# Note that the path to code and the written .bin images is designated through the "start in"
#   parameter of the icon.
# ------------------------------------------------------------------------------

# Set window title
wm title . "Autoguider - Steward Observatory Autoguiding System (vers. $version)"

# Initialize display
wm geometry . 900x650+0+0
wm iconify .
set bgcolor [ . cget -background ]

# Define fonts per operating system
if { $tcl_platform(os) == "Linux" || $tcl_platform(os) == "SunOS" } { set platform linux }
if { [string range $tcl_platform(os) 0 6] == "Windows" } { set platform windows }

if { $platform == "windows" } {
  font create bf8 -family "MS Sans Serif" -weight bold -size 8
  font create bf8u -family "MS Sans Serif" -weight bold -size 8 -underline true
  font create bf10 -family "MS Sans Serif" -weight bold -size 10 
  font create f8 -family "MS Sans Serif" -size 8 
}

if { $platform == "linux" } {
  font create bf8 -family "helvetica" -weight bold -size 10 
  font create bf8u -family "helvetica" -weight bold -size 10 -underline true  
  font create bf10 -family "helvetica" -weight bold -size 10 
  font create f8 -family "helvetica" -weight bold -size -12 
  option add *padX 5
  option add *padY 5
  option add *Dialog.Button.font {helvetica 6 bold} 
  option add *Dialog.msg.font {helvetica 6 bold}
}

# Specify primary button colors ("color" or "bw")
set buttontype color
set activecolor green
set idlecolor red
set acqboxcolor black

# Filenames -------------------------------------------------------------------
# imgfile is the image filename (no path)
# azcamdir is the path to AzCam code files as seen from the server
# azcamfile is the image file as seen from the server

set imgfile "image.bin"
set azcamdir ""
set varfile "variables.cfg"
set telfile "scope.cfg"
set camfile "camera.cfg"
set plogfile "command.log"
set tlogfile "scope.log"
set b2gfile "./bin2gif"
set conhlpfile "guider.hlp"
set updhlpfile "updates.hlp"

# "Remote" image path and filename to allow AZCAM to run on a different machine
# Default remote image path
set azcamfile [join "$azcamdir $imgfile" ""]
set lockfile [join "$azcamdir image.OK" ""]
set giffile [join "$azcamdir image.gif" ""]
set conhlpfile [join "$azcamdir $conhlpfile" ""]
set updhlpfile [join "$azcamdir $updhlpfile" ""]

# Variables -------------------------------------------------------------------

set fileip 6543
set pi 3.14159265
set theta0 0.0
set rotrad0 0.0

# time out variable for receiving the image
set t_out 0

# Computed midpoint of exposure
set tmid 0.0   

# Default detector characteristics
set detcols 512
set detrows 512
set bin 1    
     
# Acquisition area screen placement
# xs, ys                canvas size of acquisition area
# xoff, yoff            offsets of acquisition canvas 
# xm, ym                "marked" coordinates of guider box center
# xp, yp                "placed" coordinates of guider box center
# bs                    "selected" guider box size (set to bsp)
# bsp                   "placed" guider box size (square; must be odd)
# bhs                   guider box half-size
# xac, yac              screen coordinates of acquisition canvas center
# xorg, yorg            guide coordinates in box
# gamma                 brightness of photo images
# percpix               auto-scale contrast of photo images
set xs 512
set ys 512
set xoff 45
set yoff 25
set xac [expr int($xs/2 + $xoff)]
set yac [expr int($ys/2 + $yoff)]
set bs 61
set bsp $bs
set bhs [expr int($bs / 2)]
set xp $xac
set yp $yac
set xm $xp
set ym $yp
set percpix 0.925
set gamma 1.
set xorg $bhs
set yorg $bhs

# Properties of real image
# detcols, detrows      device dimensions
# xps, yps              size of acquired picture 
# xdc, ydc              center pixel of acquired picture
# fcol, lcol            first/last physical column numbers on CCD
# frow, lrow            first/last physical row numbers on CCD
# bin                   ccd binning 
# xlo, xhi, ylo, yhi    limits of acquired picture in screen coordinates
# xc, yc                center pixel of acquisition box in image coordinates
# Temporary settings for widget creation
set xdc [expr $xs / 2]
set ydc [expr $ys / 2]
set xlo $xoff
set xhi [expr $xoff + $xs]
set ylo $yoff
set yhi [expr $yoff + $ys]

# Guide area variables
# gs                    size of guide box
# ghs                   half-size of guide box
# xgc, ygc              screen coordinates of guide box center
set gs 101
set ghs [expr int($gs / 2)]
set xgc [expr $xoff + $xs + $ghs + 5]
set ygc [expr $yoff + $ghs + 1]

# Exposure time
# exptime           actual exposure time in sec
# expsel            selected exposure time in sec (converted to exptime)
set exptime 1
set expsel 1

# Guide parameters
# movefil           move multiplier
# deltime           delay after move in sec
# movelim           upper limit to single move in arcsec
# moveth            threshold for moving
# jogamt            udlr jog amount in pixels
set movefil .8
set deltime 0
set movelim 1.0
set moveth 0.1
set jogamt 1
set fluxlim .01
set minflux 1

# RA/DEC compass
# compass           enabled or disabled
# compscale         size of compass relative to acquisition canvas
set compscale 0.12

# Guide/noguide flag and recentering flag
set guiding no
set recenter yes

# Transformation parameters
set flip 1
set transformed no
set troff 30.

# Periodic error correction
set pecstat disabled
set pecperiod 120
set ralist [list]
set tlist [list]
set rasum 0.

# Flag to enable preserving offset window
set offpres no

# Centroid output
# xmid, ymid        centroid of star in binned device coordinates
# xdel, ydel        guide error in binned device coordinates
# radel, decdel     guide error in RA, Dec in arcsec
# racorr, deccoor   correction in RA, Dec in arcsec
# rarms, decrms     guiding rms in RA, Dec arcsec
set xbar 0.0
set ybar 0.0
set xmid ""
set ymid ""
set xdel ""
set ydel ""
set radel ""
set decdel ""
set racorr ""
set deccorr ""
set rarms ""
set decrms ""

# Image info
set fwhm ""
set starflux ""
set backflux ""

# Camera info
set ccdtemp ""
set dewtemp ""
set ccdtempmax 0.
set dewtempmax 40.
set camstat "NOT CONNECTED"
set temps off

# Logging flags
set proclog disabled
set tellog disabled
set plog noop
set tlog noop

# Stripchart flag
set scharts enabled

# Marker type
set mtype marker

# Default binding for left mouse click
set lclick acqboxselect

# Check for file existence
proc chkfile { fname } {
     if { [file exists $fname] } {
        return
     } else {
        error "File $fname doesn't exist!"
     }
}

# Telescope and Camera communication -------------------------------------------------------

# Telescope communication
# Default telescope id
set telid NOTEL
set telidold $telid
# Initial process id for telescope command
set telpid 0
# Telescope socket id (to be filled in upon opening socket)
set telsock ""
# Now default is to use 150 character TCS
set tel150 enabled

# Command line arguments are: telid camindex

set azcamhost disabled
set camindex NOAZCAM

if { $argv != "" } {
    set telid [string toupper [lindex $argv 0]]
    set camindex [string toupper [lindex $argv 1]]
    set telhost [string toupper [lindex $argv 2]]
    set telport [string toupper [lindex $argv 3]]
    set azcamhost [string toupper [lindex $argv 4]]
    set azcamport [string toupper [lindex $argv 5]]
   }
   
# azcambusy prevents conflicting AZCAM requests
set azcambusy no

# AZCAM socket id (to be filled in upon opening socket)
set azcamsock ""
set azcamtemp ""

# Define overall canvas -------------------------------------------------------
canvas .layout -width [expr $xoff + $xs + $gs + 245] -height [expr $yoff + $ys + 100]
.layout configure -cursor plus

# Create bounding box for acquisition image
.layout create rectangle $xoff $yoff [expr $xoff + $xs] [expr $yoff + $ys] \
               -outline white -width 2 -fill black

# Create bounding box for guide image
.layout create rectangle [expr $xgc - $ghs] [expr $ygc - $ghs] \
                [expr $xgc + $ghs] [expr $ygc + $ghs] \
                -outline white -tag guidebox -width 4 -fill black

# Canvas images -------------------------------------------------------
# Create acquisition image
image create photo acqimage
.layout create image $xac $yac -anchor c -image acqimage

# Create guide window images
image create photo fguideimage
image create photo wguideimage

# Define widgets --------------------------------------------------------------

# label for acquisition area
label .fulllab -text "Full frame" -font bf8u -anchor w

# label for guide area
label .winlab -text "Window" -font bf8u -anchor w

# guide box slider
scale .box -from 21 -to 101 -variable bs -resolution 1 -tickinterval 80 \
      -orient horizontal -length 280 -showvalue yes -command { acqboxsize }

# label for acq. slider
label .lbox -text "Window size:"

# decrease gamma
button .gamma- -width 2 -height 1 -background black -activebackground darkgrey -command { changegamma 0.8333 }

# default gamma = 1
button .gamma0 -width 6 -height 1 -text Default -background grey  -activebackground darkgrey \
   -command { list puts [set gamma 1.; changegamma 1.] }
  
# increase gamma
button .gamma+ -width 2 -height 1 -background white -activebackground darkgrey -command { changegamma 1.2 }

# label for gamma buttons
label .lgamma -text "        Brightness        " -font bf8u

# acquire label
label .acqbut -width 18 -text Acquire -background red -font bf8 -relief ridge

# single acquire button
button .sinacq -width 8 -height 2 -text Single -background red -borderwidth 3 -font bf8 \
  -state disabled -command { acquire yes }

# repeat acquire button
button .rptacq -width 8 -height 2 -text "Repeat" -background red -borderwidth 3 -font bf8 \
  -state disabled -command { togglerpt }

# guide label
label .guidebut -width 18 -text Guide -background red -font bf8 -relief ridge

# windowed guide button
button .winstart -width 8 -height 2 -text "Windowed" -background red -borderwidth 3 -font bf8 \
  -state disabled -command { guide windowed }

# full-frame guide button
button .fullstart -width 8 -height 2 -text "Fullframe" -background red -borderwidth 3 -font bf8 \
  -state disabled -command { guide fullframe }

# x coord in acq. image
label .xc -width 4 -justify center -textvariable xc -font bf8

# y coord in acq. image
label .yc -width 4 -justify center -textvariable yc -font bf8

# message
entry .message -width 58 -font bf8 -bg red -textvariable msg 


# exposure time slider
scale .expslide -from 10 -to 0 -tickinterval 2 -variable expsel -resolution 0.2 \
      -digits 3 -length 230 -showvalue no -command exptimeset

# exposure time entry
entry .expselect -width 5 -state normal -justify r -textvariable exptime -font bf8 -background LemonChiffon
catch {.expselect configure -disabledforeground black}

# exposure time slider label
label .explabel -font bf8u -text "Exposure (s)"

# NSEW guide indicators
radiobutton .nind -selectcolor $bgcolor -state disabled -disabledforeground $bgcolor -foreground $bgcolor 
radiobutton .sind -selectcolor $bgcolor -state disabled -disabledforeground $bgcolor -foreground $bgcolor 
radiobutton .eind -selectcolor $bgcolor -state disabled -disabledforeground $bgcolor -foreground $bgcolor 
radiobutton .wind -selectcolor $bgcolor -state disabled -disabledforeground $bgcolor -foreground $bgcolor 
label .nindlab -padx 0 -pady 0 -text N
label .sindlab -padx 0 -pady 0 -text S
label .eindlab -padx 0 -pady 0 -text E
label .windlab -padx 0 -pady 0 -text W

# UpDownLeftRight movement buttons
# udlr indicates intended motion of star, not telescope
button .moveu -font bf8 -width 2 -text U -state normal -command { list puts [jog $jogamt 0] }
button .moved -font bf8 -width 2 -text D -state normal -command { list puts [jog -$jogamt 0] }
button .movel -font bf8 -width 2 -text L -state normal -command { list puts [jog 0  $jogamt] }
button .mover -font bf8 -width 2 -text R -state normal -command { list puts [jog 0 -$jogamt] }
label  .jogamt -font bf8 -width 2 -textvariable jogamt -anchor n

# Centroid display
label .centhead -text Centroiding -anchor c -font bf8u
label .xhead -text x -anchor c -font bf8u
label .yhead -text y -anchor c -font bf8u
label .centlab -text "Centroid (pix):" -anchor w
label .xcent -textvariable xmid -anchor e -width 6
label .ycent -textvariable ymid -anchor e -width 6
label .dellab -text "Offset (pix):" -anchor w
label .xdel -textvariable xdel -anchor e -width 6
label .ydel -textvariable ydel -anchor e -width 6
label .rahead -text "RA" -anchor c -font bf8u
label .dechead -text "Dec" -anchor c -font bf8u
label .corrlab -text "Correction (arcsec):" -anchor w
label .racorr -textvariable racorr -anchor e -width 6
label .deccorr -textvariable deccorr -anchor e -width 6
label .rmslab -text "Guide rms (arcsec):" -anchor w
label .rarms -textvariable rarms -anchor e -width 6
label .decrms -textvariable decrms -anchor e -width 6
label .peclab -text "Learning PEC" -anchor w
radiobutton .peclearn -state disabled -disabledforeground $bgcolor -foreground red -selectcolor red

# Image characteristics
label .imhead -text "Image" -anchor c -font bf8u
label .fwhmlab -text "FWHM (arcsec):" -anchor w
label .fwhm -textvariable fwhm -anchor e -width 5
label .starfluxlab -text "Star flux (x1000):" -anchor w
label .starflux -textvariable starflux -anchor e -width 7
label .backfluxlab -text "Sky flux (x1000):" -anchor w
label .backflux -textvariable backflux -anchor e -width 7
label .imscalelab -text "Scale (arcsec/pix):" -anchor w
label .imscale -textvariable imscale -anchor e -width 5
label .fovlab -text "FOV (arcmin):" -anchor w
label .fov -textvariable fov -anchor e -width 8

# Camera status
label .camhead -text "Camera" -anchor c -font bf8u
label .detdimlab -text "CCD dimensions:" -anchor w
label .detcols -textvariable detcols -anchor e -width 3
label .detrows -textvariable detrows -anchor e -width 3
label .detcollab -text "Columns in use" -anchor w
label .fcol -textvariable fcol -anchor e -width 3
label .lcol -textvariable lcol -anchor e -width 3
label .detrowlab -text "Rows in use" -anchor w
label .frow -textvariable frow -anchor e -width 3
label .lrow -textvariable lrow -anchor e -width 3
label .binlab -text "Binning:" -anchor w
label .bin -textvariable bin -anchor e -width 5
label .ccdtemplab -text "CCD Temp (C):" -anchor w -width 30
label .ccdtemp -textvariable ccdtemp -anchor e -width 5
label .dewtemplab -text "Dewar Temp (C):" -anchor w -width 30
label .dewtemp -textvariable dewtemp -anchor e -width 5
label .camstatlab -text "Status:" -anchor w
label .camstat -textvariable camstat -anchor e -width 18

# Timer
label .tleftlab -text "Time left" -font bf8u -anchor c -width 8
label .tleft -textvariable tleft -font bf10 -anchor e -background LemonChiffon -width 6 -relief sunken

# Menubar ---------------------------------------------------------------------

menu .menubar -type menubar
. configure -menu .menubar

# "File" menu
.menubar add cascade -label File -menu .menubar.file -underline 0 -state active
  menu .menubar.file -tearoff no
  .menubar.file add command -label "Save Image as..." -command { writefits .fi }
  .menubar.file add separator
  .menubar.file add command -label Minify -command { wm iconify . }
  .menubar.file add separator
  .menubar.file add command -label "Shutdown Autoguider" -command { bye }
    
# "System" menu
.menubar add cascade -label System -menu .menubar.sys -underline 0
  menu .menubar.sys -tearoff no
  .menubar.sys add checkbutton -label "\u00AB Telescope log" -variable tellog \
    -onvalue enabled -offvalue disabled -command { set tellog [loginit tlog $tlogfile $tellog] }
  .menubar.sys add checkbutton -label "\u00AB Command log" -variable proclog \
    -onvalue enabled -offvalue disabled -command { set proclog [loginit plog $plogfile $proclog] }
  .menubar.sys add separator
  .menubar.sys add command -label "Set image path..." -command { editpath .editpath }
  .menubar.sys add separator
  .menubar.sys add command -label "File Manager" -command { catch { exec c:/windows/explorer.exe /n,/e,C:\\ } }

# "Display" menu
.menubar add cascade -label "Display" -menu .menubar.disp -underline 0
  menu .menubar.disp -tearoff no
  .menubar.disp add command -label "Tracking stripcharts..." -command { strips .strip }
  .menubar.disp add separator
  .menubar.disp add command -label "Place markers..." -command { putmark .tr } 
  .menubar.disp add command -label "Erase all markers" -command { list puts [set mtype marker; wincleanup .tr] }
  .menubar.disp add separator
  .menubar.disp add command -label "Adjust image contrast..." -command { contrast .con }
  .menubar.disp add separator
  .menubar.disp add checkbutton -label "\u00AB Show RA/Dec Axes" -variable compass \
    -onvalue enabled -offvalue disabled -command { refreshcanvas }
  .menubar.disp add separator
  .menubar.disp add radiobutton -label "\u00AB Colored buttons" -variable buttontype -value color -command buttonset
  .menubar.disp add radiobutton -label "\u00AB B&W buttons" -variable buttontype -value bw -command buttonset
  .menubar.disp add separator
  .menubar.disp add command -label "Diagnostic display" -command { verbose .vb }

# "Parameters" menu
.menubar add cascade -label Parameters -menu .menubar.parm -underline 0
  menu .menubar.parm -tearoff no
  .menubar.parm add command -label "Edit guiding parameters..." -command { editparms .editparms }
  .menubar.parm add separator
  .menubar.parm add command -label "Restore parameters now" -command { list puts [chkfile $varfile; source $varfile; restorestat] }
  .menubar.parm add command -label "Save parameters now" -command { list puts [savevars; putmsg "Parameters saved"] }
  .menubar.parm add separator
  .menubar.parm add checkbutton -label "\u00AB Periodic Error Correction" -variable pecstat -onvalue "enabled" -offvalue "disabled"

# "Camera" menu
.menubar add cascade -label Camera -menu .menubar.cam -underline 0
  menu .menubar.cam -tearoff no
  .menubar.cam add command -label "AZCAM communication:" -accelerator $camindex
  .menubar.cam add separator
  .menubar.cam add command -label "Set temperature alarms..." -command { setalarms .setalarms }
  .menubar.cam add command -label "Set CCD binning..." -command { editbinning .editbin }
  .menubar.cam add separator
  .menubar.cam add command -label "Initialize camera..." \
      -command { list puts [if {$azcamhost == "disabled" } { tk_messageBox -type ok -icon warning -message "Camera not connected" -title Warning } else { resetccd .setup } ] }

# "Telescope" menu
.menubar add cascade -label Telescope -menu .menubar.tel -underline 0
  menu .menubar.tel -tearoff no
  .menubar.tel add command -label "Telescope:" -accelerator $telid
  .menubar.tel add separator
  .menubar.tel add command -label "Offset telescope..." -command { offset }
  .menubar.tel add separator
  .menubar.tel add command -label "Set xy <--> RA/Dec transformation..." -command { transform }
  .menubar.tel add checkbutton -label "\u00AB Use 150 character TCS" -variable tel150 \
    -onvalue enabled -offvalue disabled

# "Help" menu
.menubar add cascade -label Help -menu .menubar.hlp -underline 0
  menu .menubar.hlp -tearoff no
  .menubar.hlp add command -label "Configuration help" -command { guiderhelp $conhlpfile "Configuration help" }
  .menubar.hlp add command -label "What's new in v.$version?" -command { guiderhelp $updhlpfile "What's New?"}
  .menubar.hlp add command -label "About Guider..." -command { about $version $moddate }
  
# "Popup" menu
menu .popup -tearoff no
  .popup add command -label "Offset telescope..." -command { offset }
  .popup add separator
  .popup add command -label "Place markers..." -command { putmark .tr } 
  .popup add command -label "Erase all markers" -command { list puts [set mtype marker; wincleanup .tr] }
  .popup add separator
  .popup add command -label "Save Image as..." -command { writefits .fi }
  .popup add separator
  .popup add command -label "Close popup"
  .popup add separator
  .popup add command -label "Shutdown autoguider" -command { bye }
    
# Place widgets ---------------------------------------------------------------

# Acquisition window labels and controls
set cy [expr $yoff + $ys]
pack .layout -anchor nw
place .fulllab -x $xoff -y [expr $yoff - 2] -anchor sw
place .winlab -x [expr $xgc - $ghs] -y [expr $yoff - 2] -anchor sw
place .box -x [expr $xac - 200] -y [expr $cy + 35] -anchor w
place .lbox -x [expr $xac - 285] -y [expr $cy + 35] -anchor w
place .lgamma -x [expr $xac + 185] -y [expr $cy + 15] -anchor c
place .gamma- -x [expr $xac + 130] -y [expr $cy + 45] -anchor c
place .gamma0 -x [expr $xac + 185] -y [expr $cy + 45] -anchor c
place .gamma+ -x [expr $xac + 240] -y [expr $cy + 45] -anchor c

# Acquire/guide buttons and message window
set cx [expr $xs + $gs + 197]
incr cy -40
place .acqbut -x $cx -y $cy -anchor s
place .sinacq -x $cx -y $cy -anchor nw
place .rptacq -x $cx -y $cy -anchor ne
incr cy 85
place .guidebut -x $cx -y $cy -anchor s
place .winstart -x $cx -y $cy -anchor nw
place .fullstart -x $cx -y $cy -anchor ne
place .xc -x $xac -y 10 -anchor c
place .yc -x 1 -y $yac -anchor w
place .message -x $xoff -y [expr $cy + 33] -anchor w

# Exposure slider
set cx [expr $xgc - $ghs + 50]
set cy [expr $ygc + $ghs + 190]
place .explabel -x $cx -y $cy -anchor n
place .expselect -x $cx -y [expr $cy + 28] -anchor n
place .expslide -x $cx -y [expr $cy + 53] -anchor n

# NSEW flashers
incr cx 5
incr cy -170
place .nind -x $cx -y $cy -anchor c
place .sind -x $cx -y [expr $cy + 60] -anchor c
place .eind -x [expr $cx - 30] -y [expr $cy + 30] -anchor c
place .wind -x [expr $cx + 30] -y [expr $cy + 30] -anchor c
incr cx -5
place .nindlab -x $cx -y [expr $cy + 17] -anchor c
place .sindlab -x $cx -y [expr $cy + 43] -anchor c
place .eindlab -x [expr $cx - 14] -y [expr $cy + 31] -anchor c
place .windlab -x [expr $cx + 13] -y [expr $cy + 31] -anchor c

# Move buttons
incr cx 2
incr cy 87
place .moveu -x $cx -y $cy -anchor c
place .moved -x $cx -y [expr $cy + 60] -anchor c
place .movel -x [expr $cx - 33] -y [expr $cy + 30] -anchor c
place .mover -x [expr $cx + 33] -y [expr $cy + 30] -anchor c
place .jogamt -x $cx -y [expr $cy + 30] -anchor c

# Centroid data
set cx [expr $xgc + $ghs + 185]
set cy [expr $ygc - $ghs - 14]
place .centhead -x [expr $cx - 180] -y $cy -anchor w
place .xhead -x [expr $cx - 20] -y $cy -anchor c
place .yhead -x [expr $cx + 30] -y $cy -anchor c
place .centlab -x [expr $cx - 180] -y [expr $cy + 22] -anchor w
place .xcent -x $cx -y [expr $cy + 22] -anchor e
place .ycent -x [expr $cx + 50] -y [expr $cy + 22] -anchor e
place .dellab -x [expr $cx - 180] -y [expr $cy + 44] -anchor w
place .xdel -x $cx -y [expr $cy + 44] -anchor e
place .ydel -x [expr $cx + 50] -y [expr $cy + 44] -anchor e
place .rahead -x [expr $cx - 20] -y [expr $cy + 66] -anchor c
place .dechead -x [expr $cx + 30] -y [expr $cy + 66] -anchor c

# Telescope corrections
place .corrlab -x [expr $cx - 180] -y [expr $cy + 88] -anchor w
place .racorr -x $cx -y [expr $cy + 88] -anchor e
place .deccorr -x [expr $cx + 50] -y [expr $cy + 88] -anchor e
place .rmslab -x [expr $cx - 180] -y [expr $cy + 110] -anchor w
place .rarms -x $cx -y [expr $cy + 110] -anchor e
place .decrms -x [expr $cx + 50] -y [expr $cy + 110] -anchor e

# PEC learning indicator
place .peclab -x [expr $cx - 180] -y [expr $cy + 132] -anchor w
place .peclearn -x $cx -y [expr $cy + 132] -anchor e

# Image characteristics
incr cy 155
place .imhead -x [expr $cx - 180] -y $cy -anchor w
place .fwhmlab -x [expr $cx - 180] -y [expr $cy + 22] -anchor w
place .fwhm -x [expr $cx + 50] -y [expr $cy + 22] -anchor e
place .starfluxlab -x [expr $cx - 180] -y [expr $cy + 44] -anchor w
place .starflux -x [expr $cx + 50] -y [expr $cy + 44] -anchor e
place .backfluxlab -x [expr $cx - 180] -y [expr $cy + 66] -anchor w
place .backflux -x [expr $cx + 50] -y [expr $cy + 66] -anchor e
place .imscalelab -x [expr $cx - 180] -y [expr $cy + 88] -anchor w
place .imscale -x [expr $cx + 50] -y [expr $cy + 88] -anchor e
place .fovlab -x [expr $cx - 180] -y [expr $cy + 110] -anchor w
place .fov -x [expr $cx + 50] -y [expr $cy + 110] -anchor e

# Camera characteristics
incr cy 140
place .camhead -x [expr $cx - 180] -y $cy -anchor w
place .detdimlab -x [expr $cx - 180] -y [expr $cy + 22] -anchor w
place .detcols -x [expr $cx + 20] -y [expr $cy + 22] -anchor e
place .detrows -x [expr $cx + 50] -y [expr $cy + 22] -anchor e
place .detcollab -x [expr $cx - 180] -y [expr $cy + 44] -anchor w
place .fcol -x [expr $cx + 20] -y [expr $cy + 44] -anchor e
place .lcol -x [expr $cx + 50] -y [expr $cy + 44] -anchor e
place .detrowlab -x [expr $cx - 180] -y [expr $cy + 66] -anchor w
place .frow -x [expr $cx + 20] -y [expr $cy + 66] -anchor e
place .lrow -x [expr $cx + 50] -y [expr $cy + 66] -anchor e
place .binlab -x [expr $cx - 180] -y [expr $cy + 88] -anchor w
place .bin -x [expr $cx + 50] -y [expr $cy + 88] -anchor e
place .ccdtemplab -x [expr $cx - 180] -y [expr $cy + 110] -anchor w
place .ccdtemp -x [expr $cx + 50] -y [expr $cy + 110] -anchor e
place .dewtemplab -x [expr $cx - 180] -y [expr $cy + 132] -anchor w
place .dewtemp -x [expr $cx + 50] -y [expr $cy + 132] -anchor e
place .camstatlab -x [expr $cx - 180] -y [expr $cy + 154] -anchor w
place .camstat -x [expr $cx + 50] -y [expr $cy + 154] -anchor e

# Count-down timer
set cx [expr $cx - 160]
set cy 590
place .tleftlab -x $cx -y $cy -anchor c
place .tleft -x $cx -y [expr $cy + 25] -anchor c

# Bindings --------------------------------------------------------------------

# Left button
bind .layout <Button-1> {
     set xm %x
     set ym %y
     $lclick "$mtype"
}

# Right button
bind .layout <Button-3> {
     clrmsg
     if { $guiding == "no" } { tk_popup .popup [expr %x + 5] [expr %y + 50] }
}

bind .expselect <Key-Return> {
     if { $exptime >= 0 && $exptime <= 2000 } {
        clrmsg
        set expsel $exptime
     } else {
        set exptime $expsel
        putmsg "Exposure time limits: 0 to 2000 sec"
     }
}

bind . <Escape> { clrmsg }

# Procedures ------------------------------------------------------------------

# Logfile initialization
proc loginit { logproc logfile logflag } {
     global resp plog tlog
     switch -exact -- $logproc {
       tlog { set logtype Telescope }
       plog { set logtype Command }
       default { error "Invalid log type" }
     }     
     set header [clock format [clock seconds] -format "%D"]
     if { $logflag == "enabled" } {
     set resp none
# Open window here to query user on creation of log file
     .logquery .log $logtype
     vwait resp
       if { $resp == "enabled" } { 
# Delete log file, if it exists
         file delete -force $logfile
# Alias to active procedure
         set $logproc $logproc
# Notify user
         $logproc "$logtype logging started $header"
         putmsg "$logtype logging started"
       }
     destroy .log
     } else { 
     set resp disabled
# Notify user
     putmsg "$logtype logging stopped"
     $logproc "$logtype logging stopped $header"
# Alias to null procedure
     set $logproc noop
     }
     return $resp
}

# Query widget for logging
proc .logquery { w logtype } {
     catch { destroy $w }
     toplevel $w
     wm title $w "Logfiles"
     label $w.ques -text "$logtype logging will record all $logtype actions \n and delete any previous log file. \n Click OK to start log." -font bf8 -width 50
     button $w.ok -width 5 -text "OK" -command { set resp enabled }
     button $w.cancel -text "Cancel" -default active -command { set resp disabled }
     place $w.ques -x 200 -y 25 -anchor c
     place $w.ok -x 100 -y 75 -anchor c
     place $w.cancel -x 300 -y 75 -anchor c
     bind $w <Key-Return> { set resp disabled }
     wm geometry $w 400x100+45+50
     wm resizable $w 0 0
     wm protocol $w WM_DELETE_WINDOW { }
     focus $w
}
          
# Procedure logging
proc plog { entry } {
     global proclog plogfile 
     set logid [open $plogfile a]
     set t [clock format [clock seconds] -format "%T"]
     puts $logid "$t $entry"
     flush $logid
     close $logid
}

# Telescope logging
proc tlog { entry } {
     global tellog tlogfile 
     set logid [open $tlogfile a]
     set t [clock format [clock seconds] -format "%T"]
     puts $logid "$t $entry"
     flush $logid
     close $logid
}

# AZCAM procedures ------------------------------------------------------------
# Open client socket
proc open_socket { host port } {
     global msg plog
     $plog "open_socket $host $port"
     set id ""
     catch {set id [socket $host $port]}
# Timeout for modification of channel id
     set i 0
     while { $i < 3000 } {
      if { $id != "" } { break }
      incr i 100
      after 100
     }
     if { $id == "" } {
       putmsg "Timeout opening socket $host $port"
       pause 1000
     } else {
       fconfigure $id -blocking 0 -buffering line
     }
     return $id
}

# Check for "OK" status flag response from AzCam
proc checkazcam { stat } {
     global plog
     $plog "checkazcam $stat"
     set stat1 [scan $stat %s]
#     if { $stat1 != "OK"} { tk_messageBox -type ok -icon error -message $stat -title "AZCAM Error"}   # don't pop up
     if { $stat1 != "OK"} { putmsg "AzCam error $stat"}
}

# Output command to AzCam
proc write_azcam { cid cmd checkstat } {
     global azcamresp azcamhost azcambusy azcamcmd plog
     $plog "write_azcam $cid $cmd $checkstat"
     if { $azcamhost == "disabled" } { return }
     set azcambusy yes
# Ensure input channel is empty
     read $cid
# Output command
     set azcamcmd $cmd
     catch {puts $cid $cmd}
     catch {flush $cid}
     set azcamresp N/A
# Read back response
     if { $checkstat == "yes" } {
       set azcamresp ""
       set i 0
       while { $i < 10000 } {
         incr i 100
         after 100
         set azcamresp [gets $cid]
         if { $azcamresp != "" } { break }
       }
     }
     set azcambusy no
# Check for error
    if { $azcamresp != "" } {
        if { $checkstat == "yes" } { checkazcam $azcamresp }
        return $azcamresp
        }
        
     # timeout occurred if here...
     
     return "OK"
}

# Get device columns and rows from AZCAM server
proc get_detpars { } {
     global detcols detrows plog azcamsock
     $plog "GetImageSize"
     scan [write_azcam $azcamsock "parameters.get_par imagesizex" yes] %s%s stat Ncols
     scan [write_azcam $azcamsock "parameters.get_par imagesizey" yes] %s%s stat Nrows
     set detcols [string range $Ncols 0 "end"]
     set detrows [string range $Nrows 0 "end"]
}

# Set first/last physical col and col binning; first/last physical row and row binning
proc format_ccd { } {
     global fcol lcol frow lrow bin plog azcamsock
     $plog "format_ccd $fcol $lcol $frow $lrow $bin $bin"
     scan [write_azcam $azcamsock "exposure.set_roi $fcol $lcol $frow $lrow $bin $bin" yes] %s stat
}

# Set and initiate exposure
proc expose_ccd { } {
     global exptime azcamfile plog azcamsock plog
     $plog "expose_ccd $azcamfile"
     scan [write_azcam $azcamsock "exposure.set_exposuretime $exptime" yes] %s stat
     scan [write_azcam $azcamsock "exposure.guide1 1" yes] %s stat
}

# Get CCD temperature and dewar temperature
proc get_temp { } {
     global ccdtemp dewtemp plog azcamtemp azcamsock
     $plog "get_temp"
     scan [write_azcam $azcamtemp "tempcon.get_temperatures" yes] %s%s%s stat ccdtemp dewtemp
}

# Configure AZCAM server to x-y flipped or no-flipped output
proc set_config { } {
     global plog azcamsock flip
     $plog "set_config $flip"
     if {$flip == -1} { set fcmd 1 } else { set fcmd 0 }
     scan [write_azcam $azcamsock "exposure.set_focalplane 1 1 1 1 $fcmd" yes] %s stat
}

# Toplevel edit window for image fits writing
proc writefits { w } {
     global azcamdir acquired fitsname guiding plog azcamhost 
     if { $azcamhost == "disabled" } { tk_messageBox -type ok -icon warning -message "Camera not connected" -title "Warning"; return }
     if { $acquired == "no" } { tk_messageBox -type ok -icon warning -message "Image not yet acquired" -title "Warning"; return }
     if { $guiding == "yes" } { putmsg "Stop exposure before writing image"; return }
     catch { destroy $w }
     toplevel $w
     $plog "writefits"
     wm title $w "Save as..."
     set fitsname $azcamdir
     label $w.label -width 58 -text "Filename must be UNIX-style: use '/', not '\\'!  Extension will be \".fits\"" -anchor w
     entry $w.entry -width 58 -textvariable fitsname -font bf8
     button $w.ok -text "OK" -command { chkfits }
     button $w.cancel -text "Cancel" -command { list puts [destroy .fi] }
     pack $w.label -padx 5 -pady 5 -side top
     pack $w.entry -padx 5 -pady 5 -side top
     pack $w.cancel $w.ok -side right -padx 10 -pady 5 -expand 1
     bind $w <Key-Return> chkfits
     wm geometry $w +0+50
     wm resizable $w 0 0
     focus $w
}

# Check fits filename
proc chkfits { } {
     global fitsname plog
     $plog "chkfits $fitsname"
     if { [file isdirectory $fitsname] == 1 } { error "$fitsname invalid image name!" } 
     set fitsname [file rootname $fitsname]
     set fitsname "$fitsname.fits"
     if { [file exists $fitsname] } { 
       .fi.label configure -text "FILE EXISTS!! CONFIRM OVERWRITE:" -foreground blue -font bf8
       .fi.ok configure -command { write_image }
     } else {
       write_image }
}

# Instruct AZCAM server to write out last image taken
proc write_image { } {
     global fitsname plog azcamsock fileport
     # $plog "WriteFile $fitsname"
     $plog "NOT SUPPORTED!"
     set path "!"
     append path $fitsname
     # write the Image as a fits file
     #scan [write_azcam $azcamsock "WriteGuiderImage $fitsname" yes] %s stat
     #putmsg "Image written as $fitsname"
     destroy .fi
}

# Toplevel "about" window
proc about { version moddate } {
     catch { destroy .ab }
     toplevel .ab
     wm title .ab "About Guider..."
     frame .ab.a
     pack .ab.a -side top
     canvas .ab.a.img -width 50 -height 50
     image create photo galaxy
     .ab.a.img create image 32 32 -anchor c -image galaxy
     galaxy read galaxy.gif
     label .ab.a.label1 -width 30 -text "Steward Autoguider vers. $version" -font bf8 -anchor w -fg blue
     pack .ab.a.img .ab.a.label1 -side left -padx 5
     frame .ab.b
     pack .ab.b -side top
     label .ab.b.label2 -text "Authors: G. Schmidt, M. Lesser, G. Williams"
     pack .ab.b.label2 
     frame .ab.c
     pack .ab.c -side top
     label .ab.c.label3 -text "Last modified $moddate"
     pack .ab.c.label3
     frame .ab.d
     pack .ab.d -side top
     label .ab.d.label4 -text "\u00A9 2004 - 2018 - The University of Arizona"
     button .ab.d.ok -text "OK" -default active -command { destroy .ab }
     pack .ab.d.label4 .ab.d.ok -side left -padx 10 -pady 5
     bind .ab <Key-Return> { destroy .ab }
     wm geometry .ab +400+50
     wm resizable .ab 0 0
     focus .ab
}

# Reset camera
proc resetccd { w } {
     global plog 
     $plog "resetccd"
     catch { destroy $w }
     toplevel $w
     wm title $w "Reset camera controller"
     label $w.reset -text "Are you sure?" -font bf8 -anchor c
     button $w.ok -text "OK" -command { list puts [lowreset; putmsg "AZCAM has been reset"; destroy .setup] }
     button $w.cancel -text "Cancel" -default active -command { destroy .setup }
     pack $w.reset -side top -pady 5 -padx 90
     pack $w.ok $w.cancel -side left -padx 10 -pady 5 -expand 1
     bind $w <Key-Return> { destroy .setup }
     wm geometry $w +250+50
     wm resizable $w 0 0
     focus $w
}

# Low-level resetting of camera
proc lowreset { } {
     global devfile azcamsock plog
     $plog "lowreset"
     set stat ""
     scan [write_azcam $azcamsock "exposure.reset" yes] %s stat
     return $stat
}

# Background updating of temperatures
proc updatetemp { } {
     global temps plog
     $plog "updatetemp"
     set temps on
     set j 0
     while { $j < 10 } {
       pause 1000
       if { $temps == "exiting" } { break }
       incr j
       if { $j == 10 } {
         set j 0
         if { $temps == "on" } { checktemp }
       }
     }
     shutdown
}

# Check for over-temperature condition
proc checktemp { } {
     global ccdtemp ccdtempmax dewtemp dewtempmax plog temps bgcolor
     $plog "checktemp $ccdtemp $ccdtempmax $dewtemp $dewtempmax"
     set temps off
# Retrieve temperatures from server
     get_temp
     set temps on
# Check for over-temperature conditions
     if { $ccdtemp > $ccdtempmax } { 
         .ccdtemplab configure -background orangered -font bf8 
         .ccdtemp configure -background orangered -font bf8
     } else { 
         .ccdtemplab configure -background $bgcolor -font f8 
         .ccdtemp configure -background $bgcolor -font f8 
     }
     if { $dewtemp > $dewtempmax } { 
         .dewtemplab configure -background orangered -font bf8 
         .dewtemp configure -background orangered -font bf8
     } else { 
         .dewtemplab configure -background $bgcolor -font f8
         .dewtemp configure -background $bgcolor -font f8
     }
}

# Format CCD and set image parameters
# Parameters are first col, last col, first row, last row, bin [origin is pixel (1,1)]
proc setformat { x1 x2 y1 y2 } {
     global fcol lcol frow lrow bin reformat xps yps xdc ydc xac yac
     global xlo xhi ylo yhi detcols detrows plog
     $plog "set_format $x1 $x2 $y1 $y2"
# Set first, last col and first, last row
     set fcol [expr ($x1 - 1) * $bin + 1]
     set lcol [expr $x2 * $bin]
     set frow [expr ($y1 - 1) * $bin + 1]
     set lrow [expr $y2 * $bin]
# Format CCD
     format_ccd
# Set picture sizes
     set xps [expr $x2 - $x1 + 1]
     set yps [expr $y2 - $y1 + 1]
# Set half-sizes of acquisition image
     set xdc [expr int($detcols / $bin / 2)]
     set ydc [expr int($detrows / $bin / 2)]
# Set screen boundaries of acquisition image
     set xlo [expr $xac - $xdc]
     set xhi [expr $xac + $xdc]
     set ylo [expr $yac - $ydc]
     set yhi [expr $yac + $ydc]
     set reformat no
}

# Set exposure time with entry box
proc exptimeset { input } {
     global exptime plog
     $plog "exptimeset $input"
     set exptime $input
     clrmsg
}

# Select box size to odd number of pixels
proc acqboxsize { input } {
     global bs bhs bsp plog
     $plog "acqboxsize $input"
     set bs $bsp
     if { $input < $bsp } { incr bs -2; incr bhs -1 }
     if { $input > $bsp } { incr bs 2; incr bhs }
     set bsp $bs
     acqboxselect slider
}

# Query widget for xy<->RA/Dec transformation
proc .trquery { w } {
     global resp troff plog
     $plog ".trquery"
     catch { destroy $w }
     toplevel $w
     wm title $w "xy <-> RA/Dec transformation"
     label $w.ques -text "Select offset amount.\n Click OK to start." -font bf8 -anchor c -width 60
     button $w.ok -text "OK" -default active -command { set resp 1 }
     button $w.cancel -text "Cancel" -command { set resp -1 }
     label $w.offlab -text "Offset amount in arcsec" -anchor c -width 60
     scale $w.off -from 10 -to 60 -variable troff -resolution 5 -tickinterval 10 \
      -orient horizontal -length 220 -showvalue yes
     place $w.ques -x 120 -y 40 -anchor c
     place $w.ok -x 270 -y 25 -anchor c
     place $w.cancel -x 270 -y 60 -anchor c
     place $w.offlab -x 150 -y 90 -anchor c
     place $w.off -x 150 -y 125 -anchor c
     bind $w <Key-Return> { set resp 1 }
     wm geometry $w 320x150+600+50
     wm resizable $w 0 0
     wm protocol $w WM_DELETE_WINDOW { }
     focus $w
}

# Place crosshairs on stars during transformation or telescope offset
proc mark { mtype } {
     global resp xm ym xlo xhi ylo yhi plog
     $plog "mark $xm $ym"
# Check for being outside image boundary
     if { $xm > $xhi || $xm < $xlo || $ym > $yhi || $ym < $ylo } { 
         set msg [.tr.ques cget -text]
         if { $msg == "Mark star-" || $msg == "Mark target location-" } {
           .tr.ques configure -text "Star outside picture"
           catch { raise .vb }
           pause 2000
           .tr.ques configure -text $msg
         }
         catch { raise .vb }
         return
     }
     set xc $xm
     set yc $ym
     crosshairs $xm $ym 0 15 $mtype blue
     set resp 1
     catch {raise .tr}
     catch {focus -force .tr}
     catch {raise .off}
     catch {focus -force .off}
}

proc putmark { w } {
     global lclick mtype plog
     $plog "putmark"
     catch { destroy $w }
     toplevel $w
     wm title $w "Place markers..."
     label $w.ques -text "Mark star-" -font bf8 -anchor c -width 40
     button $w.done -text "Done" -command { list puts [set lclick acqboxselect; destroy .tr] }
     button $w.erase -text "Erase markers" -command { .layout delete marker }
     pack $w.ques -side top -pady 5
     pack $w.done $w.erase -side left -padx 10 -pady 5 -expand 1
     wm geometry $w +600+50
     set lclick mark
     set mtype marker
     wm resizable $w 0 0
     wm protocol $w WM_DELETE_WINDOW { }
     focus $w
}

# Set xy <-> RA/Dec transformation
proc transform { } {
     global transformed telid rptacq resp troff plog camindex tel150
     global imscale fov xps yps theta theta0 rotrad0 flip xm ym lclick mtype pi
     $plog "transform"
# flip              E CCW of N = 1; E CW of N = -1
# theta             angle of N vector relative to "up"; theta > 0 for CCW
     if { $telid == "NOTEL" } { tk_messageBox -type ok -icon warning -message "Transformation requires telescope" -title "Warning"; return }
     set lclick mark
     set mtype cross
     set rptacq no
     refreshcanvas
# Query for offset amount
     .trquery .tr
     raise .tr
     focus -force .tr
     vwait resp
     if { $resp == -1 } { wincleanup .tr; return }
# Take 1st exposure without restarting temperature update
     .tr.ques configure -text "Taking 1st exposure..."
     freeze .tr.ok
     freeze .tr.cancel
# Ensure acquired images will be in non-flipped format
     set flip 1
     set_config
# Now take exposure
     acquire no
     set resp 0
     .tr.ques configure -text "Mark star-"
     thaw .tr.cancel
     catch { raise .vb }
     vwait resp
     if { $resp == -1 } { wincleanup .tr; return }
     set x1 $xm
     set y1 $ym
# Move telescope
     set resp 0
# Move telescope EAST
     .tr.ques configure -text "Moving telescope EAST..."
     set telresp [write_tel "RADECGUIDE $troff 0." yes]
# Wait for telescope to stop moving    
     set stat [telwait]
     .tr.ques configure -text $stat
     pause 1000
# Mark second position
     .tr.ques configure -text "Taking 2nd exposure..."
     freeze .tr.ok
     freeze .tr.cancel
     raise .tr
     focus -force .tr
     catch { raise .vb }
# Take 2nd exposure without restarting temperature update
     acquire no
     crosshairs $x1 $y1 0 15 cross blue
     set resp 0     
     .tr.ques configure -text "Mark star-"
     thaw .tr.cancel
     vwait resp
     if { $resp == -1 } { wincleanup .tr; return }
     set x2 $xm
     set y2 $ym
# Move telescope NORTH
     .tr.ques configure -text "Moving telescope NORTH..."
     set telresp [write_tel "RADECGUIDE 0. $troff" yes]
# Wait for telescope to stop moving    
     set stat [telwait]
     .tr.ques configure -text $stat
     pause 1000
# Mark third position
     .tr.ques configure -text "Taking 3rd exposure..."
     freeze .tr.ok
     freeze .tr.cancel
     catch { raise .vb }
# Take 3rd exposure without restarting temperature update
     acquire no
     clrmsg
     crosshairs $x1 $y1 0 15 cross blue
     crosshairs $x2 $y2 0 15 cross blue
     set resp 0     
     .tr.ques configure -text "Mark star-"
     thaw .tr.cancel
     raise .tr
     focus -force .tr
     catch { raise .vb }
     vwait resp
     if { $resp == -1 } { wincleanup .tr; return }
     .tr.ques configure -text "Transformation complete"
     set x3 $xm
     set y3 $ym
     crosshairs $x3 $y3 0 15 cross blue
     update idletasks
# Compute xy differences
     set dx1 [expr $x2 - $x1]
     set dy1 [expr $y2 - $y1]
     set dx2 [expr $x3 - $x2]
     set dy2 [expr $y3 - $y2]
# Compute image scale in arcsec/pixel
     set imscale [expr ($troff / hypot ($dx1, $dy1) + $troff / hypot ($dx2, $dy2)) / 2.]
     roundvar imscale 3
# Compute image field of view
     set fovx [expr $imscale * $xps / 60.]
     set fovy [expr $imscale * $yps / 60.]
     roundvar fovx 1
     roundvar fovy 1
     set fov "$fovx x $fovy"
# Now set theta and "flip" variables appropriately
     set theta [expr atan2($dx2, $dy2)]
     if { $theta < 0.} { set theta [expr $theta + 2. * $pi] }
# theta0 is the value of theta at the time of transformation
     set theta0 $theta
     if { $theta <= [expr 0.25 * $pi] || $theta >= [expr 1.75 * $pi] } { set flip [expr  $dx1 / abs($dx1)] }
     if { $theta >  [expr 0.25 * $pi] && $theta <= [expr 0.75 * $pi] } { set flip [expr -$dy1 / abs($dy1)] }
     if { $theta >  [expr 0.75 * $pi] && $theta <= [expr 1.25 * $pi] } { set flip [expr -$dx1 / abs($dx1)] }
     if { $theta >  [expr 1.25 * $pi] && $theta <  [expr 1.75 * $pi] } { set flip [expr  $dy1 / abs($dy1)] }
# Read rotator initial value if at MMT or if using 150 character TCS at Bok
     if { $telid == "MMT" } { set rotrad0 [getrot] }
     if { $telid == "BOK" && $camindex != "90PRIMEGUIDER" && $tel150 == "enabled" } { set rotrad0 [getrot] }
     set transformed yes
     wincleanup .tr
     savevars
# We now take a fresh exposure and show the compass on the new (possibly flipped) image
     set_config
     acquire no 
     refreshcanvas
     updatetemp
}

# Clean up canvas
proc wincleanup { w } {
     global lclick offpres mtype plog
     $plog "wincleanup"
     .layout delete $mtype
     set lclick acqboxselect
     if { $w == ".off" && $offpres == "yes"} { return }
     set offpres no
     destroy $w
}

# Modify gamma factor on the images
proc changegamma { fac } {
     global acquired gamma plog
     $plog "changegamma $fac"
     if { $acquired == "no" } { return }
     set gamma [expr $fac * $gamma]
     acqimage configure -gamma $gamma
     fguideimage configure -gamma $gamma
     wguideimage configure -gamma $gamma
}

# Define acquisition image and create initial box
# GSZ: new version 31Jan2011
proc acquire { tempstart } {
     global acquired rptacq guiding detcols detrows bin temps xps yps azcamhost
     global activecolor idlecolor plog t_out
     $plog "acquire $tempstart $rptacq"
     if { $azcamhost == "disabled" } { list puts [tk_messageBox -type ok -icon warning -message "Camera not connected" -title "Warning"; return] }
     # Change button colors based on whether single or repeat acquisition
     if { $rptacq == "no" } { 
       .sinacq configure -background $activecolor
       freeze .sinacq
       freeze .rptacq 
     } else {
       freeze .sinacq
     }
     .guidebut configure -foreground grey50
     .acqbut configure -background $activecolor -text Acquiring
     fguideimage blank
     wguideimage blank
     acqimage blank
     clrmsg

     # Ensure camera is in correct flip mode
     set_config

     # Take full-frame image in selected binning
     setformat 1 [expr $detcols / $bin] 1 [expr $detrows / $bin]
     acqimage configure -width $xps -height $yps
     pulldowns disabled
     acqwindow freeze
     guidewindow freeze
     update idletasks

     # Stop temperature updates
     set temps off
     set guiding yes
     while { 1 } {
       # Take exposure and display with intensity scaling
       expose yes
       if { $t_out == 0 } {
          set acquired yes
          refreshcanvas
       } else { putmsg  "Timeout waiting for .bin image file" }

       update idletasks
       if { $rptacq == "no" } { break }
     }
     toidle $tempstart
}

# Return gui to idle state
proc toidle { tempstart } {
     global guiding temps idlecolor plog
     $plog "toidle $tempstart"
     set guiding no
     clrmsg
     acqwindow thaw
     guidewindow thaw
     .guidebut configure -foreground black
     .acqbut configure -background $idlecolor -text Acquire
     .sinacq configure -background $idlecolor -state normal
     thaw .rptacq
     pulldowns normal
# Restart temperature updating
     if { $tempstart == "yes" } { set temps on }
     update idletasks
}

# Toggle repeat button feature for acquisition
proc togglerpt { } {
     global rptacq activecolor idlecolor azcamhost plog
     $plog "togglerpt $rptacq"

     if { $azcamhost == "disabled" } { list puts [tk_messageBox -type ok -icon warning -message "Camera not connected" -title "Warning"; return] }
     switch -exact -- $rptacq {
       yes { .rptacq configure -background $idlecolor; set rptacq no; obsstop }
       no  { .rptacq configure -background $activecolor; set rptacq yes; acquire yes }
       }
}

# Refresh acquisition area of canvas with compass, if desired
proc refreshcanvas { } {
     global acquired transformed compass giffile plog
     $plog "refreshcanvas"
     if { $acquired == "no" } { return }
     .layout delete compass
     acqimage read $giffile
     acqboxselect click
     if { $compass == "enabled" && $transformed == "yes" } drawcompass
     update idletasks
}

# Take exposure
proc expose { scaling } {
     global camstat lockfile imgfile giffile b2gfile xps yps percpix zmin zmax
     global tleft exptime plog stat azcamsock tmid t_out
     $plog "expose $exptime $scaling"

     # Delete previous image and lock files MPL 13Jan12
     if { [catch { file delete -force $lockfile } errorstat] } {
        putmsg "could not delete lock file"
        return
        #pause 1000
        #catch [file delete -force $lockfile]
     }
     if { [catch { file delete -force $imgfile } errorstat] } {
        putmsg "could not delete bin file"
        return
        #pause 1000
        #catch {file delete -force $imgfile}
     }
     if { [catch { file delete -force $giffile } errorstat] } {
        putmsg "could not delete gif file"
        return
        #pause 1000
        #catch [file delete -force $giffile]
     }
     
     # Prepare for exposure
     catch { raise .vb }
     set camstat EXPOSING

     # Estimate midpoint of exposure by expected start/end times
     # Format of tmid is integer seconds, not hh:mm:ss
     set tmid [expr int([clock seconds] + $exptime / 2. + 0.5) ]

     # Expose CCD
     expose_ccd

     # Wait for end of exposure, stopping 2 seconds early to look for lock file
     if { $exptime > 2. } {
       # Read clock time
       set tnow [clock seconds]
       
       # Compute stop time
       set tend [expr $tnow + $exptime]
       set tleft [expr int($exptime)]
       while { $tleft > 2 } {
         pause 500
         set tnow [clock seconds]

         # Compute time left
         set tleft [expr int($tend - $tnow)]
         update idletasks
       }
     }
     set camstat READING
     
     # Now look for appearance of lock image file
     # Read clock time
     set tnow [clock seconds]

     # Set read time to twice expected read time of chip (20 microseconds/pixel), plus 10 seconds allowance
     set tend [expr int(2 * $xps * $yps / 50000 + $tnow + 10)]

     # Set time out flag
     set t_out 0
     set cnt 0

     while { $tnow <= $tend } {
       if { [file exists $lockfile] } { break }

       pause 200

       set cnt [expr $cnt + 1]

       # get exposure status
       exposurestatus
       # just to show that the process is working
       putmsg "$camstat $cnt"
       update idletasks

       set tnow [clock seconds]
     }

     if { $tnow >= $tend } { 
         toidle yes 
         set t_out 1
         # tk_messageBox -type ok -icon warning -message "Timeout waiting for .bin image file" -title "Timeout!"
         }

     set tleft ""
     set camstat IDLE

     if { $t_out == 0 } {
         # Intensity scale image, if desired
         if { $scaling == "yes" } {
            if { [catch {zscale $imgfile $yps $xps $percpix } errorstat] } {
               putmsg "Scaling error: $errorstat" }
         }

         # Create .gif display file
         if { [catch {exec $b2gfile $imgfile $giffile $yps $xps $zmin $zmax } errorstat] } {
              putmsg "Bin2Gif error: $errorstat" }
              
         # Update rotator angle after each exposure
         updatetheta
     } 

     update idletasks
}

# Master guiding loop
# GSZ: new version 31Jan2011
proc guide { mode } {
     global guiding acquired transformed reformat imgfile giffile temps activecolor idlecolor bgcolor flip
     global xgc ygc bhs ghs xc yc xs ys xps yps exptime detcols detrows xp yp xm ym
     global fcol lcol frow lrow bin imscale
     global xdel ydel rarms decrms xbar ybar xmid ymid racorr deccorr starflux backflux minflux fwhm recenter
     global radel decdel scharts plog tlog
     global raerr decerr pecstat pecperiod tlist ralist rasum
     global xorg yorg xoff yoff ncyc
     $plog "guide $mode"
# Check that all is ready for guiding
     if { $guiding == "yes" } { return }
     if { $acquired == "no" } { tk_messageBox -type ok -icon warning -message "Image not yet acquired" -title "Warning"; return }
     if { $transformed == "no" } { tk_messageBox -type ok -icon warning -message "xy <-> RA/Dec Transformation not yet performed" -title "Warning"; return }
# Configure canvas for guiding and ensure reformat occurs
     pulldowns disabled
     acqwindow freeze
     .acqbut configure -foreground grey50
     freeze .rptacq
     .guidebut configure -background $activecolor -text Guiding
# Fullframe - blank acquisition image, change button colors, format CCD to full frame
# Windowed - change button colors, freeze exposure time controls (because of intensity scaling vis-a-vis acquisition window)
     switch -exact -- $mode {
         fullframe { .fullstart configure -background $activecolor -command { obsstop }
           acqimage blank
           freeze .winstart
           setformat 1 [expr $detcols / $bin] 1 [expr $detrows / $bin] }
         windowed  { .winstart configure -background $activecolor -command { obsstop }
           freeze .fullstart
           freeze .expslide
           freeze .expselect }
     }
     set reformat yes
     wguideimage blank
     fguideimage blank
     update idletasks
# Stop temperature updating
     set temps off
     set guiding yes
# Ensure camera is in correct flip mode
     set_config
# Guiding loop
# For PEC mode, clear lists and correction sum, and illuminate "PEC learn" indicator 
     if { $pecstat == "enabled" } { 
       set ralist { }
       set tlist { }
       set rasum 0.
       thaw .peclearn
     }
     set rasum2 0.
     set decsum2 0.
     set ncyc 0
     clrmsg
     while { $guiding == "yes" } {
         if { $reformat == "yes" } {
# Set boundaries of guiding box for fullframe read
            set x1 [expr $xc - $bhs]
            set x2 [expr $xc + $bhs]
            set y1 [expr $yc - $bhs]
            set y2 [expr $yc + $bhs]
            drawacqbox
# If windowed readout mode, format chip first time through
            if { $mode == "windowed" } {
# Remember that frame may be flipped, so we mirror x-coordinate to get correct chip region
# If flipped, we must reorder first and last columns
              if { $flip == -1 } {
                set xtemp [expr $detcols / $bin - $x1 + 1]
                set x1 [expr $detcols / $bin - $x2 + 1]
                set x2 $xtemp
              }
              setformat $x1 $x2 $y1 $y2
# Now set boundaries of guiding box for windowed read
              set x1 0
              set x2 [expr $xps - 1]
              set y1 0
              set y2 [expr $yps - 1] }
         }
         set reformat no
# Blink frame of guide window
         .layout itemconfigure guidebox -outline white
         if { $exptime <= 0 } { putmsg "Guide exposure time must be > 0 sec"; pause 800; continue }
# Take image with intensity scaling, if desired
         if { $mode == "windowed" } { expose yes } else { expose yes }
# Blink frame of guide window
         .layout itemconfigure guidebox -outline black
# Fullframe - display new full-frame image and copy section to guide window
# Windowed - display new image in guide window
         switch -exact -- $mode {
             fullframe { refreshcanvas
                         .layout delete fguideimage
                         .layout create image [expr $xoff + $xs + 5] [expr $yoff + 1] -anchor nw -image fguideimage
                         fguideimage configure -width $xps -height $yps
                         acqimage read $giffile
                         if { $ncyc != 0 } { fguideimage copy acqimage \
                         -from $x1 $y1 $x2 $y2  -to [expr $ghs - $bhs] [expr $ghs - $bhs] } }
             windowed  { .layout delete wguideimage
                         .layout create image $xgc $ygc -anchor c -image wguideimage
                        wguideimage configure -width $xps -height $yps
                        wguideimage read $giffile }
         }
# Paint green cross-hairs on guide window
         .layout delete sights
         crosshairs $xgc $ygc [expr 0.3 * $ghs] [expr 0.7 * $ghs] sights green
# Pass binary image filename and centroiding instructions to compiled centroiding routine
# Input parameters are: rows, cols, [first row, last row, first col, last col of centroiding window]
# Centroid updates xbar ybar fwhm starflux backflux
        clrmsg
        set yy1 [expr $y1 + 2]
        set yy2 [expr $y2 - 2]
        set xx1 [expr $x1 + 2]
        set xx2 [expr $x2 - 2]
        if { [catch {centroid $imgfile $yps $xps $yy1 $yy2 $xx1 $xx2} errorstat] } {
            putmsg "Centroid error: $errorstat"; continue }
# Check for valid fwhm
        if { [catch {set fwhm [expr $fwhm * $imscale] } errorstat] } { set fwhm 0.0 }
        if { $fwhm <= 0. || $fwhm > 40. } { set fwhm 0.0 }
        roundvar fwhm 2        
        if { $starflux < $minflux } { 
             .starflux configure -background orangered
             .starfluxlab configure -background orangered
             set msgflux [expr $minflux * 1000]
             putmsg "STAR FLUX < $msgflux... CLOUDS?"; continue
    } else { .starflux configure -background $bgcolor 
             .starfluxlab configure -background $bgcolor }
# Check that other returned values are valid numbers (>0) 
         if { $xbar <= 0 || $ybar <= 0 || $backflux <= 0 } { continue }        
# "centroid" coordinates are referenced 1 LESS than box coordinates,
# so we convert to box coordinates
         set xbar [expr $xbar + 1.0]
         set ybar [expr $ybar + 1.0]
# Compute centroid in fullframe coordinates
         set xmid [expr $xbar + $xc - $bhs]
         set ymid [expr $ybar + $yc - $bhs]         
# Format parameters for display
         roundvar xmid 2
         roundvar ymid 2
         roundvar starflux 1
         roundvar backflux 1
# On first pass, save original x and y positions for future reference
         if { $ncyc == 0 } {
            set xorg $xbar
            set yorg $ybar
            roundvar xorg 2
            roundvar yorg 2
# If recentering is also desired, center guide box to nearest half-pixel
            if { $recenter == "yes" } {
               set xdel [expr $xbar - $bhs]
               set ydel [expr $ybar - $bhs]
               set ixdel [expr round($xdel)]
               set iydel [expr round($ydel)]
               boxadjust -$iydel -$ixdel
               set xdel ""
               set ydel ""
            }
         } else {
# If not on first pass...
# Compute differences in fractional pixels
            set xdel [expr $xbar - $xorg]
            set ydel [expr $ybar - $yorg]
# Correct telescope position with limit checking but no message
# Telcorrect computes the tracking errors raerr and decerr, the (possibly predicted) radel and decdel, and makes corrections racorr and deccorr
# Format parameters for display
            roundvar xdel 2
            roundvar ydel 2
            telcorrect $ydel $xdel yes no         
# Compute guiding information
            if { $ncyc == 0 } { incr ncyc }
            set rasum2 [expr $rasum2 + pow($raerr,2)]
            set decsum2 [expr $decsum2 + pow($decerr,2)]
            set rarms [expr sqrt($rasum2 / $ncyc)]
            roundvar rarms 2
            set decrms [expr sqrt($decsum2 / $ncyc)]
            roundvar decrms 2
# Log info to stripcharts
            if { $scharts == "enabled" } { stripchart -$raerr -$decerr $fwhm $starflux $ncyc }
         }
         incr ncyc
         tlog "$xmid $ymid $xdel $ydel $fwhm $starflux $backflux"
         update idletasks
     }
# Wrap up guiding
# Configure canvas to idle configuration
     pulldowns normal
     switch -exact -- $mode {
         fullframe { .fullstart configure -background $idlecolor -command { guide fullframe } }
         windowed  { .winstart configure -background $idlecolor -command { guide windowed } }
     }
     thaw .winstart
     thaw .fullstart
     .guidebut configure -background $idlecolor -text Guide
     .acqbut configure -foreground black
     clrmsg
     freeze .peclearn
     acqwindow thaw
     thaw .rptacq
     thaw .expslide
     thaw .expselect
     set guiding no
     set xm $xp
     set ym $yp
     savevars
# Restart temperature updating
     set temps on
}

# Terminate observing process
proc obsstop { } {
     global guiding plog
     $plog "obsstop"
     set guiding stop
     putmsg "Sequence ending.  Please wait..."
     freeze .rptacq
     freeze .fullstart
     freeze .winstart
}

# Draw box on acquisition window
proc drawacqbox { } {
     global xp yp bhs acqboxcolor plog
     $plog "drawacqbox"
     .layout delete acqbox
     .layout create rectangle [expr $xp - $bhs] [expr $yp - $bhs] \
                              [expr $xp + $bhs] [expr $yp + $bhs] -outline $acqboxcolor -tag acqbox
}

# Write text in message widget
proc putmsg { input } {
     global msg 
     set msg "***** $input *****"
     .message configure -background orangered
     update idletasks
}

# Clear message widget
proc clrmsg { } {
     global msg 
     .message configure -background LemonChiffon
     set msg ""
}

# Draw crosshairs in desired color 
proc crosshairs { xcen ycen in out type color } {
     global plog
     $plog "crosshairs"
     .layout create line $xcen [expr $ycen - $out] $xcen [expr $ycen - $in] -fill $color -tag $type
     .layout create line $xcen [expr $ycen + $in] $xcen [expr $ycen + $out] -fill $color -tag $type
     .layout create line [expr $xcen - $out] $ycen [expr $xcen - $in] $ycen -fill $color -tag $type
     .layout create line [expr $xcen + $in] $ycen [expr $xcen + $out] $ycen -fill $color -tag $type
}

# Select region of acquisition area to use for guiding
# "origin" is how selected: = "click" if from mouse click, "slider" if from adjustment of box size
proc acqboxselect { origin } {
     global xm ym xlo xhi ylo yhi bs bsp bhs xp yp xc yc xac yac xdc ydc guiding plog
     if { $origin == "click" } { $plog "acqboxselect $origin $xm $ym $bs" }
     if { $guiding != "no" } { return }
     clrmsg
# Check that selected position doesn't overlap image edge
     if { $xm > $xhi || $xm < $xlo || $ym > $yhi || $ym < $ylo } { return }
     if { $xm < [expr $xlo + $bhs + 2] || $xm > [expr $xhi - $bhs - 2] || \
         $ym < [expr $ylo + $bhs + 2] || $ym > [expr $yhi - $bhs - 2] } {
         switch -exact -- $origin {
           click { set xm $xp; set ym $yp }
           slider { set xp $xm; set yp $ym; incr bs -2; incr bhs -1; set bsp $bs }
         }
         putmsg "Star too near edge.  Select new star or reduce box size."
         return
     }
     clrmsg
     drawacqbox
     .layout move acqbox [expr $xm - $xp] [expr $ym - $yp]
     set xp $xm
     set yp $ym
     set xc [expr $xp - $xac + $xdc]
     set yc [expr $yp - $yac + $ydc]
}

# Toplevel image contrast adjustment slider
proc contrast { w } {
     global percpix plog
     $plog "contrast"
     catch { destroy $w }
     toplevel $w
     wm title $w "Contrast adjustment"
     scale $w.conslide -from 0.80 -to 1.00 -tickinterval 0.05 -variable percpix -resolution 0.01 \
           -digits 3 -length 350 -orient horizontal -showvalue yes -label "Image contrast              (HIGH <---------------------> LOW)"
     button $w.close -width 11 -text "Close window" -default active -command { destroy .con }
     pack $w.conslide $w.close -side left -padx 5
     bind $w <Key-Return> { destroy .con }
     wm geometry $w +100+50
     wm resizable $w 0 0
     focus $w
}
           
# Toplevel verbose display
proc verbose { w } {
     global azcamcmd azcamresp azcambusy guiding transformed imgfile temps theta flip compass acquired telem
     global telcmd rarad decrad rotrad xorg yorg plog
     $plog "verbose"
     catch { destroy $w }
     toplevel $w
     wm title $w "Display extras"
     label $w.imgfilelab -text "Image file" -anchor e
     label $w.imgfile -width 40 -textvariable imgfile -anchor e
     label $w.azcamcmdlab -text "AZCAM cmd"
     label $w.azcamcmd -width 40 -textvariable azcamcmd -anchor e
     label $w.azcamresplab -text "AZCAM reply" -anchor w
     label $w.azcamresp -width 40 -textvariable azcamresp -anchor e
     label $w.telcmdlab -text "Scope cmd" -anchor w
     label $w.telcmd -width 40 -textvariable telcmd -anchor e
     label $w.tempslab -text "Temp readback" -anchor w
     label $w.temps -width 40 -textvariable temps -anchor e
     label $w.ralab -text "RA (rad)" -anchor w
     label $w.ra -width 40 -textvariable rarad -anchor e
     label $w.declab -text "Dec (rad)" -anchor w
     label $w.dec -width 40 -textvariable decrad -anchor e
     label $w.rotlab -text "Rotator (rad)" -anchor w
     label $w.rot -width 40 -textvariable rotrad -anchor e
     label $w.thetalab -text "Theta (rad)" -anchor w
     label $w.theta -width 40 -textvariable theta -anchor e
     checkbutton $w.acquired -text "Acquired" -variable acquired -onvalue yes -state disabled -disabledforeground black
     checkbutton $w.compass -text "Compass" -variable compass -onvalue enabled -state disabled -disabledforeground black
     checkbutton $w.transformed -text "Transformed" -variable transformed -onvalue yes -state disabled -disabledforeground black
     checkbutton $w.flipped -text "Flipped" -variable flip -onvalue -1 -state disabled -disabledforeground black
     checkbutton $w.guiding -text "Guiding" -variable guiding -onvalue yes -state disabled -disabledforeground black
     checkbutton $w.azcambusy -text "AZCAM busy" -variable azcambusy -onvalue yes -state disabled -disabledforeground black
     label $w.xorglab -width 7 -text "xguide" -anchor w
     label $w.xorg -width 5 -textvariable xorg -anchor e
     label $w.yorglab -width 7 -text "yguide" -anchor w
     label $w.yorg -width 5 -textvariable ncyc -anchor e
     place $w.azcamcmdlab -x 10 -y 20 -anchor w
     place $w.azcamcmd -x 485 -y 20 -anchor e
     place $w.azcamresplab -x 10 -y 40 -anchor w
     place $w.azcamresp -x 485 -y 40 -anchor e
     place $w.imgfilelab -x 10 -y 60 -anchor w
     place $w.imgfile -x 485 -y 60 -anchor e
     place $w.telcmdlab -x 10 -y 80 -anchor w
     place $w.telcmd -x 485 -y 80 -anchor e
     place $w.tempslab -x 10 -y 100 -anchor w
     place $w.temps -x 485 -y 100 -anchor e
     place $w.ralab -x 10 -y 120 -anchor w
     place $w.ra -x 485 -y 120 -anchor e
     place $w.declab -x 10 -y 140 -anchor w
     place $w.dec -x 485 -y 140 -anchor e
     place $w.rotlab -x 10 -y 160 -anchor w
     place $w.rot -x 485 -y 160 -anchor e
     place $w.thetalab -x 10 -y 180 -anchor w
     place $w.theta -x 485 -y 180 -anchor e
     place $w.acquired -x 10 -y 205 -anchor w
     place $w.guiding -x 10 -y 230 -anchor w
     place $w.transformed -x 135 -y 205 -anchor w
     place $w.compass -x 135 -y 230 -anchor w
     place $w.flipped -x 270 -y 205 -anchor w
     place $w.azcambusy -x 270 -y 230 -anchor w
     place $w.xorglab -x 390 -y 205 -anchor w
     place $w.xorg -x 440 -y 205 -anchor w
     place $w.yorglab -x 390 -y 230 -anchor w
     place $w.yorg -x 440  -y 230 -anchor w
     wm geometry $w 490x250+0+460
     wm resizable $w 0 0
}

# Toplevel temperature alarm setpoint sliders
proc setalarms { w } {
     global ccdtempmax dewtempmax plog
     $plog "setalarms"
     catch { destroy $w }
     toplevel $w
     wm title $w "Temperature setpoints"
     scale $w.ctmax -from -40 -to 10 -variable ccdtempmax -length 350 -orient horizontal -showvalue no \
           -tickinterval 5 -resolution 5 -label "CCD alarm temperature"
     scale $w.dtmax -from 0 -to 50 -variable dewtempmax -length 350 -orient horizontal -showvalue no \
           -tickinterval 5 -resolution 5 -label "Dewar alarm temperature"
     button $w.close -width 7 -height 2 -text "Close \n window" -default active -command { destroy .setalarms }
     place $w.ctmax -x 10 -y 40 -anchor w
     place $w.dtmax -x 10 -y 110 -anchor w
     place $w.close -x 375 -y 75 -anchor w
     bind $w <Key-Return> { destroy .setalarms }
     wm geometry $w 450x150+250+50
     wm resizable $w 0 0
     focus $w
}

# Toplevel edit window for guiding parameters
proc editparms { w } {
     global deltime filter movelim jogamt minflux plog pecstat pecperiod
     $plog "editparms"
     catch { destroy $w }
     toplevel $w
     wm title $w "Guider parameters"
       # minimum flux
     scale $w.minflux -from -1 -to 3 -variable fluxlim -length 350 -orient horizontal -showvalue no \
           -resolution .001 -label "Star brightness threshold (x1000)" -command minfluxset
     label $w.minfluxsel -width 5 -textvariable minflux -anchor e
       # filter slider
     scale $w.filslide -from 0.0 -to 1.0 -tickinterval 0.2 -variable movefil -resolution 0.1 \
           -digits 2 -length 350 -orient horizontal -showvalue yes -label "Motion Multiplier"
       # maximum move slider
     scale $w.limslide -from 0.1 -to 1.0 -tickinterval .2 -variable movelim -resolution 0.1 \
           -digits 2 -length 350 -orient horizontal -showvalue yes -label "Max. movement (arcsec)"
       # threshold slider
     scale $w.thslide -from 0.0 -to 0.5 -tickinterval 0.1 -variable moveth -resolution 0.05 \
           -digits 2 -length 350 -orient horizontal -showvalue yes -label "Min. movement (arcsec)"
       # delay slider
     scale $w.delslide -from 0 -to 5 -tickinterval 0.5 -variable deltime -resolution 0.5 \
           -digits 2 -length 350 -orient horizontal -showvalue yes -label "Guide delay (sec)"
       # checkbox for initial centering of box
     checkbutton $w.recenter -text "Recenter box on first exposure?" -onvalue yes -offvalue no \
           -variable recenter -width 25
     label $w.pecperiodsel -width 15 -text "PEC period (s)" -anchor e
     entry $w.pecperiod -width 5 -font bf8 -textvariable pecperiod
       # manual jog slider
     scale $w.jogslide -from 0 -to 3 -tickinterval .5 -variable jogamt -resolution .1 \
           -digits 2 -length 350 -orient horizontal -showvalue yes -label "Movement per UDLR click (pix)" \
           -command { jogchk }
     button $w.close -width 11 -text "Close window" -default active -command { destroy .editparms }
     pack $w.minflux $w.filslide $w.limslide $w.thslide $w.delslide $w.jogslide -anchor w -pady 4 -side top
     place $w.minfluxsel -x 320 -y 15 -anchor c
     pack $w.recenter -padx 2 -pady 5 -side top
     pack $w.pecperiodsel $w.pecperiod -padx 5 -pady 3 -side left
     pack $w.close -padx 20 -pady 5 -side left
     if { $pecstat == "disabled" } { $w.pecperiod configure -foreground grey -state disabled }
     bind $w <Key-Return> { destroy .editparms }
     wm geometry $w +170+50
     wm resizable $w 0 0
     focus $w
}

# Set minimum guiding flux on logarithmic scale
proc minfluxset { input } {
     global minflux plog
     $plog "minfluxset $input"
     set minflux [expr pow(10, $input)]
     roundvar minflux 1
}

# Toplevel edit window for CCD binning
proc editbinning { w } {
     global bin acquired transformed plog
     $plog "editbinning"
     catch { destroy $w }
     toplevel $w
     wm title $w "CCD binning"
     radiobutton $w.bin1 -variable bin -value 1 -text 1x1 -activeforeground red
     radiobutton $w.bin2 -variable bin -value 2 -text 2x2 -activeforeground red
     radiobutton $w.bin3 -variable bin -value 3 -text 3x3 -activeforeground red
     radiobutton $w.bin4 -variable bin -value 4 -text 4x4 -activeforeground red
     button $w.close -text "Close window" -default active \
           -command { list puts [acqimage blank; set acquired no; set transformed no; destroy .editbin] }
     pack $w.bin1 $w.bin2 $w.bin3 $w.bin4 $w.close -padx 3 -pady 5 -side left -expand 1
     bind $w <Key-Return> { list puts [acqimage blank; set acquired no; set transformed no; destroy .editbin] }
     wm geometry $w +250+50
     wm resizable $w 0 0
     wm protocol $w WM_DELETE_WINDOW { }
     focus $w
}

# Toplevel edit window for path
proc editpath { w } {
     global azcamdir path plog
     $plog "editpath"
     catch { destroy $w }
     toplevel $w
     wm title $w "Edit image path"
     set path $azcamdir
     label $w.label -width 50 -text "UNIX convention paths - use '/', not '\\'!" -anchor w
     entry $w.entry -width 45 -textvariable path -font bf8
     button $w.ok -text "OK" -default active -command { checkpath $path }
     button $w.cancel -text "Cancel" -command { destroy .editpath }
     pack $w.label -padx 5 -pady 5 -side top
     pack $w.entry -padx 5 -pady 5 -side top
     pack $w.cancel $w.ok -side right -padx 10 -pady 5 -expand 1
     bind $w <Key-Return> { checkpath $path }
     wm geometry $w +45+50
     wm resizable $w 0 0
     focus $w
}

# Add a trailing slash, if necessary
proc checkpath { input } {
     global azcamfile azcamdir imgfile plog
     $plog "checkpath $input"
     if { [file isdirectory $input] != 1 } { error "$input not an existing directory!" }
     set azcamdir $input
     set azcamfile [file join $azcamdir $imgfile]
     putmsg "Binary image file now $azcamfile"
     destroy .editpath
}

# Toplevel window with stripcharts
proc strips { w } {
     global sw sh sb sscale rascale decscale fwscale stscale smax tbase scharts minflux plog 
     catch { destroy $w }
     toplevel $w
     $plog "strips"
     wm title $w "Tracking, image charts"
     set sw 100
     set sh 70
     set sb 3
     set xm 0
     set sscale 3
     scaleupdate $sscale
# Initialize flux scale to twice minflux
     set smax [expr int(2000 * $minflux)]
     set stscale "Flux: 0-$smax"
     set scharts enabled
     canvas $w.rchart -width [expr $sw + 2 * $sb] -height [expr $sh + 2 * $sb]
     canvas $w.dchart -width [expr $sw + 2 * $sb] -height [expr $sh + 2 * $sb]
     canvas $w.fchart -width [expr $sw + 2 * $sb] -height [expr $sh + 2 * $sb]
     canvas $w.schart -width [expr $sw + 2 * $sb] -height [expr $sh + 2 * $sb]
     label $w.r -width 16 -textvariable rascale -anchor c
     $w.rchart create rectangle $sb $sb [expr $sw + 2 * $sb] [expr $sh + 2 * $sb] \
               -outline white -width $sb -fill black
     label $w.d -width 16 -textvariable decscale -anchor c
     $w.dchart create rectangle $sb $sb [expr $sw + 2 * $sb] [expr $sh + 2 * $sb] \
               -outline white -width $sb -fill black
     label $w.f -width 16 -textvariable fwscale -anchor c
     $w.fchart create rectangle $sb $sb [expr $sw + 2 * $sb] [expr $sh + 2 * $sb] \
               -outline white -width $sb -fill black
     label $w.s -width 16 -textvariable stscale -anchor c
     $w.schart create rectangle $sb $sb [expr $sw + 2 * $sb] [expr $sh + 2 * $sb] \
               -outline white -width $sb -fill black
     label $w.lyscale -width 15 -text "Range (\")" -anchor c
     scale $w.yscale -from 1 -to 6 -variable sscale -resolution 1 -tickinterval 1 \
      -orient horizontal -length $sw -sliderlength 15 -showvalue no -command { scaleupdate }
     label $w.lxscale -width 15 -text "Timeline(min):" -anchor c
     label $w.xscale -width 6 -textvariable tbase -anchor c
     button $w.close -width 4 -height 1 -text Close -command { list puts [set scharts disabled; destroy .strip] }
     button $w.clear -width 4 -height 1 -text Clear -command { stripinit }
     pack $w.r $w.rchart $w.d $w.dchart $w.f $w.fchart -ipady 4 -side top
     pack $w.lyscale $w.yscale $w.s $w.schart $w.lxscale $w.xscale -side top -ipady 4
     pack $w.clear $w.close -pady 5 -side left -expand 1
     wm protocol $w WM_DELETE_WINDOW { list puts [set scharts disabled; destroy .strip] }
     wm geometry $w +905+0
     wm resizable $w 0 0
}

# Update half-scale of stripcharts
proc scaleupdate { scale } {
     global rascale decscale fwscale plog
     $plog "scaleupdate $scale"
     set rascale "RA \u00B1[expr $scale / 2.]\" range"
     set decscale "Dec \u00B1[expr $scale / 2.]\" range"
     set fwscale "FWHM 0-$scale\" range"
}

# Initialize recirculating lists
proc stripinit { } {
     global sdex rdata ddata fdata sdata plog
     $plog "stripinit"
     set sdex 0
     set rdata ""
     set ddata ""
     set fdata ""
     set sdata ""
}

# Stripchart display.  If ncyc == 1, initialize charts
proc stripchart { rval dval fval sval ncyc } {
     global sb sw sh rdata ddata fdata sdata sscale smaxht stscale
     global exptime tbase xps yps bin sdex detcols plog
     $plog "stripchart $rval $dval $fval $sval $ncyc"
# First time through, initialize recirculating lists
     if { $ncyc == 1 } { stripinit }
# Add new items to recirculating lists
     set sdex [lcycle $sdex $rval $dval $fval $sval]
# Calculate display constants
     set sh2 [expr $sh / 2]
     set yor2 [expr $sb + 1 + $sh2]
# Delete all old lines
     .strip.rchart delete rchart
     .strip.dchart delete dchart
     .strip.fchart delete fchart
     .strip.schart delete schart
     .strip.rchart delete grid
     .strip.dchart delete grid
# Autoscale flux max to a power of two
     set i 0
     set smax 0
     while { $i < $sdex } {
       if { [lindex $sdata $i] > $smax } { set smax [lindex $sdata $i] }
       incr i
     }
     set smax [expr int( log($smax) / log(2.0) + 1)]
     set smax [expr pow(2,$smax)]
     set smaxht [expr $sh / $smax]
     set smaxnew [expr int($smax * 1000)]
     set stscale "Flux: 0-$smaxnew"
# Set max height for guiding values
     set maxht [expr $sh / $sscale]
     set i 0
     set x [expr $sw - $sdex]
# Draw stripcharts
     while { $i < $sdex } {
       drawline .strip.rchart $x $sh2 [expr $maxht * [lindex $rdata $i]] rchart
       drawline .strip.dchart $x $sh2 [expr $maxht * [lindex $ddata $i]] dchart
       drawline .strip.fchart $x $sh  [expr $maxht * [lindex $fdata $i]] fchart
       drawline .strip.schart $x $sh  [expr $smaxht * [lindex $sdata $i]] schart
       incr i
       incr x
     }
# Draw zerolines in RA and DEC charts
     .strip.rchart create line [expr $sb + 2] $yor2 [expr $sb + $sw] $yor2 -fill red -tag grid
     .strip.dchart create line [expr $sb + 2] $yor2 [expr $sb + $sw] $yor2 -fill red -tag grid
# Estimate timebase in minutes at 50,000 pixels/sec
# Controller reads yps rows by detcols cols
# Assume 0.75 sec avg. deadtime per exposure for issuing guide commands etc.
     set tbase [expr $sw * ($exptime + 0.75 + $detcols / $bin * $yps / 50000.) / 60.]
     roundvar tbase 1
}

# Cycle list items
proc lcycle { sdex rval dval fval sval } {
     global rdata ddata fdata sdata sw plog
     $plog "lcycle $sdex $rval $dval $fval $sval"
# Add new elements at ends of lists
     lappend rdata $rval
     lappend ddata $dval
     lappend fdata $fval
     lappend sdata $sval
# Delete first element if index exceeds length
     if { $sdex == $sw } { 
       set rdata [lreplace $rdata 0 0]
       set ddata [lreplace $ddata 0 0]
       set fdata [lreplace $fdata 0 0]
       set sdata [lreplace $sdata 0 0] } else { incr sdex }
     return $sdex
}

# Draw vertical line in canvas "w", at location "x", y origin "y0", height "ht", tag "id"
proc drawline { w x y0 ht id } {
     global sb plog
     $plog "drawline $x $y0 $ht $id"
     set x [expr $x + $sb + 2]
     set yor [expr $sb + 1 + $y0]
     $w create line $x $yor $x [expr $yor - $ht] -fill green -tag $id
}

# Select colored or black and white major buttons
proc buttonset { } {
     global buttontype activecolor idlecolor plog
     $plog "buttonset $buttontype"
     switch -exact -- $buttontype {
       color { set activecolor green; set idlecolor red }
       bw    { set activecolor white; set idlecolor grey60 }
     }
     .acqbut configure -background $idlecolor
     .sinacq configure -background $idlecolor
     .rptacq configure -background $idlecolor
     .guidebut configure -background $idlecolor
     .winstart configure -background $idlecolor
     .fullstart configure -background $idlecolor
}

# Freeze/thaw acquisition window controls - "cmd" is freeze or thaw
proc acqwindow { cmd } {
     $cmd .sinacq
     $cmd .expselect
     $cmd .box
}

# Freeze/thaw guide window controls - "cmd" is freeze or thaw
proc guidewindow { cmd } {
     $cmd .winstart
     $cmd .fullstart
}

# Freeze/thaw telescope motion flashers - "cmd" is freeze or thaw
proc flashers { cmd } {
     $cmd .nind
     $cmd .sind
     $cmd .wind
     $cmd .eind
}

# Draw a line in a rotated coordinate system (theta > 0 for CCW)
proc rotline { x1 y1 x2 y2 } {
     global xor yor theta flip pi plog
     $plog "rotline $x1 $y1 $x2 $y2"
# If flipped coordinate system, mirror N axis around vertical line because image will be mirrored
     if {$flip == -1} { set ftheta [expr 2 * $pi - $theta] } else { set ftheta $theta }
     set st [expr sin($ftheta)]
     set ct [expr cos($ftheta)]
     set x1 [expr $x1 - $xor]
     set x2 [expr $x2 - $xor]
     set y1 [expr $y1 - $yor]
     set y2 [expr $y2 - $yor]
     set X1 [expr int($x1 * $ct + $y1 * $st + $xor)] 
     set Y1 [expr int(-$x1 * $st + $y1 * $ct + $yor)]
     set X2 [expr int($x2 * $ct + $y2 * $st + $xor)] 
     set Y2 [expr int(-$x2 * $st + $y2 * $ct + $yor)]
     .layout create line $X1 $Y1 $X2 $Y2 -fill green -tag compass
     incr X1
     incr X2
     incr Y1
     incr Y2
     .layout create line $X1 $Y1 $X2 $Y2 -fill green -tag compass
}

# Draw RA/dec compass
proc drawcompass { } {
     global xoff yoff xs xor yor compscale imscale plog
     $plog "drawcompass"
     set size [expr $compscale * $xs]
     set len [expr round ($size * $imscale)]
# Draw directional lines
     set xor [expr $xoff + 1.3 * $size]
     set yor [expr $yoff + 1.3 * $size]
     rotline $xor $yor $xor [expr $yor - $size]
     rotline $xor $yor [expr $xor - $size] $yor
# Draw "N" label
     set ht [expr 0.2 * $size]
     set wd [expr 0.6 * $ht]
     set x0 [expr $xor - $wd / 2.]
     set y0 [expr $yor - 1.18 * $size]
     rotline $x0 $y0 $x0 [expr $y0 + $ht]
     rotline $x0 $y0 [expr $x0 + $wd] [expr $y0 + $ht]
     rotline [expr $x0 + $wd] $y0 [expr $x0 + $wd] [expr $y0 + $ht]
# Draw "E" label
     set x0 [expr $xor - 1.15 * $size]
     set y0 [expr $yor + $ht / 2.]
     rotline $x0 $y0 $x0 [expr $y0 - $ht]
     rotline $x0 $y0 [expr $x0 + $wd] $y0
     rotline $x0 [expr $y0 - 0.5 * $ht] [expr $x0 + 0.7 * $wd] [expr $y0 - 0.5 * $ht]
     rotline $x0 [expr $y0 - $ht] [expr $x0 + $wd] [expr $y0 - $ht]
}

# Save all global variables except those which can cause problems upon reloading
proc savevars { } {
     global varfile telem plog
     $plog "savevars"
     set telem ""
     set fid [open $varfile w]
     set globs [info globals]
     foreach item $globs {
       upvar #0 $item value
       set val ""
       catch { set val "$value" }
       if { $val == "" } { continue }
# Below are the variables to exclude from saved list
       switch -exact -- $item {
         azcamcmd { }
         azcamhost { }
         azcamsock { }
         azcamtemp { }
         azcamport { }
         errorInfo { }
         telid { }
         telidold { }
         camindex { }
         telhost { }
         telsock { }
         telport { }
         scharts { }
         temps { }
         ddata { }
         rdata { }
         fdata { }
         argv { }
         tlogfile { }
         tellog { }
         plogfile { }
         proclog { }
         plog { }
         tlog { }
         camstat { }
         rascale { }
         decscale { }
         fwscale { }
         platform { }
         version { }
         moddate { }
         default { catch { puts $fid "set $item \"$val\"" } }
       }
     }
     catch { flush $fid }
     catch { close $fid }
}

# Clear centroid and image values for display purposes
proc clrguidevals { } {
     global xmid ymid fwhm starflux backflux xdel ydel racorr deccorr rarms decrms plog
     $plog "clrguidevals"
     set xmid ""
     set ymid ""
     set fwhm ""
     set starflux ""
     set backflux ""
     set xdel ""
     set ydel ""
     set racorr ""
     set deccorr ""
     set rarms ""
     set decrms ""
}

# Restore idle status after restoring variables
proc restorestat { } {
     global acquired plog
     $plog "restorestat"
     clrguidevals
     set acquired no
     buttonset
     changegamma 1.
     acqimage blank
     drawacqbox
     putmsg "Parameters restored"
}

# Toplevel query widget for telescope offsetting
proc .offquery { w } {
     global resp dra ddec offpres plog
     $plog ".offquery"
     set dra 0
     set ddec 0
     set offpres no
     catch { destroy $w }
     toplevel $w
     wm title $w "Offset telescope"
     label $w.ques -text "Mark object or enter offset in arcsec \n and click to move-" -font bf8 -width 50
     label $w.note -text "+ offset in RA moves telescope EAST (object WEST) \n + offset in Dec moves telescope NORTH (object SOUTH)" -width 50
     label $w.ralab -text "RA" -width 5 -justify right
     label $w.declab -text "Dec" -width 5 -justify right
     entry $w.ra -width 5 -justify right -textvariable dra -background LemonChiffon
     entry $w.dec -width 5 -justify right -textvariable ddec -background LemonChiffon
     button $w.move -width 7 -text "Move" -command { list puts [movetel $dra $ddec yes; wincleanup .off; set resp -1] }
     button $w.cancel -text "Cancel" -default active -command { list puts [set offpres no; wincleanup .off; set resp -1] }
     checkbutton $w.pres -text "Check to preserve window after move" -variable offpres -onvalue yes
     place $w.ques -x 175 -y 25 -anchor c
     place $w.note -x 175 -y 60 -anchor c
     place $w.cancel -x 175 -y 100 -anchor c
     place $w.pres -x 30 -y 130 -anchor w
     place $w.ralab -x 355 -y 20
     place $w.ra -x 415 -y 30 -anchor c
     place $w.declab -x 355 -y 60
     place $w.dec -x 415 -y 70 -anchor c
     place $w.move -x 400 -y 110 -anchor c
     bind $w <Key-Return> { set resp -1 }
     wm geometry $w 450x150+565+50
     wm resizable $w 0 0
     wm protocol $w WM_DELETE_WINDOW { }
     focus $w
}

# Offset telescope
proc offset { } {
     global acquired transformed xm ym lclick mtype rptacq resp movefil guiding offpres plog
     $plog "offset"
     if { $acquired == "no" } { tk_messageBox -type ok -icon warning -message "Image not yet acquired" -title Warning; return }
     if { $transformed == "no" } { tk_messageBox -type ok -icon warning -title Warning -message "xy <-> RA/Dec Transformation not yet performed"; return }
     if { $guiding == "yes" } { tk_messageBox -type ok -icon warning -message "Stop exposure before offsetting telescope" -title Warning; return }
     clrmsg
     set lclick mark
     set mtype cross
     set rptacq no
# Mark first position
     if { $offpres == "no" } { .offquery .off }
     set resp 0
     thaw .off.cancel
     catch {raise .off}
     focus -force .off
     catch { raise .vb }
     vwait resp
     if { $resp == -1 } { return }
     set x1 $xm
     set y1 $ym
# Mark second position
     .off.ques configure -text "Mark target location-"
     .off.note configure -text ""
     thaw .off.cancel
     catch { raise .vb }
     vwait resp
     if { $resp == -1 } { return }
     set xdel [expr ($x1 - $xm)]
     set ydel [expr ($y1 - $ym)]
# Move telescope with no limit checking but message
     telcorrect $ydel $xdel no yes
     wincleanup .off
     acquire no
}

# Telescope interface ---------------------------------------------------------

# Adjust guidebox position - parameters are in integer pixels (dr > 0; ul < 0)
proc boxadjust { ud lr } {
     global plog guiding xc yc xp yp bhs xps yps xgc ygc xorg yorg reformat 
     $plog "boxadjust $ud $lr"
     if { $guiding != "yes" } { return }
     if { $ud == 0. && $lr == 0. } { return }
     set xm [expr $xc - $lr]
     set ym [expr $yc - $ud]
     if { $xm < [expr $bhs + 3] || $xm > [expr $xps - $bhs - 3] || \
         $ym < [expr $bhs + 3] || $ym > [expr $yps - $bhs - 3] } {
         tk_messageBox -type ok -icon error -message "Star too near edge.  Select new star or reduce box size." -title "Error"; set lr 0; set ud 0 }
      set xc [expr $xc - $lr]
      set yc [expr $yc - $ud]
      set xp [expr $xp - $lr]
      set yp [expr $yp - $ud]
      set xorg [expr $xorg + $lr]
      set yorg [expr $yorg + $ud] 
      set reformat yes
}

# Limit jogamt to >0
proc jogchk { value } {
     global jogamt plog
     $plog "jogchk $value"
     if { $value == 0. } { set jogamt 0.1 }
}

# Jog telescope manually - parameters are now in fractional pixels (dr > 0; ul < 0)
proc jog { ud lr } {
     global plog guiding transformed xorg yorg xgc ygc ghs bhs xoff yoff xs
     $plog "jog $ud $lr"
# If guiding, we simply adjust xorg and yorg and recenter box to nearest half-pixel
     if { $guiding == "yes" } {
       set xorg [expr $xorg - $lr]
       set yorg [expr $yorg - $ud]
       set ixdel [expr round ($lr)]
       set iydel [expr round ($ud)]
       boxadjust $iydel $ixdel
     } else {
       if { $transformed == "no" } { tk_messageBox -type ok -icon warning -title "Warning" -message "xy <-> RA/Dec Transformation not yet performed"; return }
# If not guiding, we move telescope with no limit checking but message
       telcorrect $ud $lr no yes
     }
}

# Correct telescope - parameters are in binned pixels (N,E > 0; S,W < 0)
# This procedure now includes capability to invoke PEC
proc telcorrect { ud lr limitchk msg } {
     global imscale theta flip movefil movelim deccorr racorr decdel radel plog moveth pi
     global raerr decerr tmid tlist ralist pecstat pecperiod rasum
     $plog "telcorrect $ud $lr"
# If flipped coordinate system, mirror N axis around vertical line because image will be mirrored
     if {$flip == -1} { set ftheta [expr 2 * $pi - $theta] } else { set ftheta $theta }
     set st [expr sin($ftheta)]
     set ct [expr cos($ftheta)]
# Set decdel and radel are in seconds of arc
     set decerr [expr ($lr * $st + $ud * $ct) * $imscale]
     set raerr  [expr ($lr * $ct - $ud * $st) * $imscale]
     set decdel [expr -$decerr]
     set radel  [expr -$raerr]
# Limit checking
     if { $limitchk == "yes" } { 
# If PEC is enabled, invoke PEC calculation
# We place PEC inside of limit checking to ensure that guiding is in process
# Note that peccompute updates radel
       if { $pecstat == "enabled" } peccompute
       set deccorr [expr $decdel * $movefil]
       set racorr [expr $radel * $movefil]
       if { [expr abs($deccorr)] < $moveth } { set deccorr 0. }
       if { [expr abs($racorr)]  < $moveth } { set racorr  0. }
       if { $deccorr < -$movelim } { set deccorr -$movelim }
       if { $deccorr >  $movelim } { set deccorr  $movelim }
       if { $racorr  < -$movelim } { set racorr  -$movelim }
       if { $racorr  >  $movelim } { set racorr   $movelim }
     } else {
       set racorr $radel
       set deccorr $decdel 
     }     
     roundvar deccorr 2
     roundvar racorr 2
     movetel $racorr $deccorr $msg
# If PEC is not enabled, return now
     if { $pecstat != "enabled" } return    
# Otherwise, append new values to lists
     lappend tlist $tmid
     lappend ralist [expr $raerr - $rasum]
# Delete old list entry(s)
     set tlength [llength $tlist]
     set i 0
     while { $i < $tlength } {
       if { [lindex $tlist 0] < [expr $tmid - 2. * $pecperiod ] } {
            set tlist [ldelete $tlist 0]
            set ralist [ldelete $ralist 0]
       }
       incr i
     }
     set rasum [expr $rasum + $racorr] 
}

# Move telescope
proc movetel { dra ddec msg } {
     global moveth deltime plog bgcolor
     $plog "movetel $dra $ddec"
# Offsets are in arcsec and limited to <1000 arcsec
     if { [expr abs($dra) > 1000] || [expr abs($ddec) > 1000] } { 
       tk_messageBox -type ok -icon warning -message "Offset too large" -title "Warning"; return }
     if { $dra == "" } { set dra 0. }
     if { $ddec == "" } { set ddec 0. }
# Flash directional indicators
     flashers thaw
     if { $ddec >  $moveth } { .nind configure -selectcolor red -foreground red }
     if { $ddec < -$moveth } { .sind configure -selectcolor red -foreground red }
     if { $dra >  $moveth }  { .eind configure -selectcolor red -foreground red }
     if { $dra < -$moveth }  { .wind configure -selectcolor red -foreground red }
# Move telescope
     if { $dra != 0. || $ddec != 0. } { 
         set telresp [write_tel "RADECGUIDE $dra $ddec" yes]
     } else {
         flashers freeze
         return
     }
# Allow for telescope latency
     if { $deltime != 0 } { after [expr int(1000 * $deltime)] }
     .nind configure -selectcolor $bgcolor -foreground $bgcolor -state disabled
     .sind configure -selectcolor $bgcolor -foreground $bgcolor -state disabled
     .eind configure -selectcolor $bgcolor -foreground $bgcolor -state disabled
     .wind configure -selectcolor $bgcolor -foreground $bgcolor -state disabled
     if { $msg == "no" } { return }
     putmsg "Moving telescope $dra in RA and $ddec in Dec..."
# Wait for telescope to stop moving    
     set stat [telwait]
     putmsg $stat
}

# Telescope communication ----------------------------------------------
# Output move command to telescope
proc write_tel { cmd getresp } {
     global telid sysid telsock telcmd telpid plog
     if { $telid == "NOTEL" } { 
       tk_messageBox -type ok -icon warning -message "No telescope selected" -title "Warning"; return }
     incr telpid
     set $telpid [expr int(fmod($telpid, 255))]
     set telcmd "$telid $sysid $telpid $cmd"
     $plog "write_tel $telcmd"
     set telresp ""
# Ensure input channel is empty
     read $telsock
# Output command to telescope host
     puts $telsock $telcmd
     flush $telsock
# Wait for response except on shutdown command
     if { $getresp == "yes" } { 
      set i 0
      while { $i < 10000 } {
        incr i 100
        pause 100
        set telresp [gets $telsock]
        if { $telresp != "" } { break }
      }
# Check for error
      if { $telresp == "" } { tk_messageBox -type ok -icon warning -message "Telescope host timeout!"; return }
# Parse response
      set telresp [lindex $telresp 3]
      return $telresp
     }
}

# Read the instrument rotator angle in radians
proc getrot { } {
     global plog pi rotrad fwhm 
     $plog "getrot"
     set rotdeg [write_tel "REQUEST ROT" yes]
     set rotrad [expr $rotdeg / 180. * $pi ]
     return $rotrad
}

# Update the angle between Up and North (recall theta increases CCW)
proc updatetheta { } {
     global theta0 theta rotrad0 telid camindex tel150 plog
     $plog "updatetheta"
     if { $telid == "MMT" } { 
       set rotrad [getrot]
       set theta [expr $theta0 - $rotrad + $rotrad0]
     }
     if { $telid == "BOK" && $camindex != "90PRIMEGUIDER" && $tel150 == "enabled" } {
       set rotrad [getrot]
       set theta [expr $theta0 - $rotrad + $rotrad0]
     }
}

# Read telescope DEC through socket
proc getdec { } {
     global decrad pi plog
     $plog "getdec"
# Make sure decimal point is in correct place
     while { 1 } {
       set dec [write_tel "REQUEST DEC" yes]
       if { [string index $dec 7] == "." } { break }
     }
# Replace leading zeroes to avoid confusion with octal numbers
     set i 1
     while { $i < 6 } {
       if { [string index $dec $i] == "0" } { set dec [string replace $dec $i $i " "] }
       incr i 2
     }
     set sgn [string index $dec 0]
     set deg [string range $dec 1 2]
     set min [string range $dec 3 4]
     set sec [string range $dec 5 8]
     set decrad [expr ($deg + $min / 60. + $sec / 3600.) / 180. * $pi]
     if { $sgn == "-" } { set decrad -$decrad }
# Return Dec in radians
     return $decrad
}

# Read telescope RA through socket
proc getra { } {
     global rarad pi plog
     $plog "getra"
# Make sure decimal point is in correct place
     while { 1 } {
       set ra [write_tel "REQUEST RA" yes]
       if { [string index $ra 6] == "." } { break }
     }
# Replace leading zeroes to avoid confusion with octal numbers
     set i 0
     while { $i < 5 } {
       if { [string index $ra $i] == "0" } { set ra [string replace $ra $i $i " "] }
       incr i 2
     }
     set hr [string range $ra 0 1]
     set min [string range $ra 2 3]
     set sec [string range $ra 4 8]
# Return RA in radians
     set rarad [expr ($hr + $min / 60. + $sec / 3600.) / 12. * $pi]
     return $rarad
}

# Get first character of telemetry stream
# 0 = stable
# 1 = moving in dec
# 2 = moving in ra
# 3 = moving in both axes
proc getmotion { } {
     global plog
     $plog "getmotion"
     set mvmnt [write_tel "REQUEST MOTION" yes]
     return $mvmnt
}

# Wait for telescope to stop moving
proc telwait { } {
     global plog
     $plog "telwait"
# Wait for motion stopped
     set i 0
# 15 second timeout
     while { $i < 15000 } {
       set mvmnt [getmotion]
       pause 1000
       incr i 1000
       if { $mvmnt == 0 } { break }
     }
     if { $mvmnt == 0 } { 
       set stat "Telescope offset completed"
       pause 500
     } else { 
       set stat ""
       destroy .off       
       tk_messageBox -type ok -icon warning -message "Telescope did not complete move!"
     }
     return $stat
}
       
# Startup/shutdown ------------------------------------------------------------

# Close down guider
proc bye { } {
     global temps version plog
     $plog "bye"
     catch { grab release .exit; destroy .exit }
     toplevel .exit
     wm title .exit "Confirm shut down..."
     label .exit.msg -text "Do you really want to shutdown autoguider?" -font bf8
     button .exit.cancel -text "Cancel" -command { list puts [grab release .exit; destroy .exit] }
     button .exit.exit -text "Confirm shutdown" -default active \
       -command { stopguider }     
     pack .exit.msg -side top -padx 15 -pady 10
     pack .exit.exit .exit.cancel -side left -padx 15 -pady 10 -expand 1
     bind .exit <Key-Return> { stopguider }
     wm geometry .exit 400x110+350+250
     wm resizable .exit 0 0
     focus .exit
     grab .exit
}

# Stop guider program
proc stopguider { } {
     global temps plog azcamsock shutdownazcam
     $plog "stopguider"
     .exit.msg configure -text "Shutting down..."
     pause 500
     if { $shutdownazcam == 1 } { 
        write_azcam $azcamsock "exitazcam" no
     } else {
        write_azcam $azcamsock "closeconnection" no }
     
     
# Test "temps" value to allow forced shutdown if temperature updating is not running
     if { $temps == "on" } {
       set temps exiting
     } else {
       shutdown }
}
       
# Startup procedure - sets variable defaults and widgets
proc startup { } {
     global camfile camindex camstat azcamsock azcamtemp azcamdir azcamhost azcamport azcambusy fileport fileip
     global platform imgfile azcamdir azcamfile devfile
     global telfile telid telhost telport telsock telidold sysid fileport myip
     global compass acquired rptacq transformed guiding pecstat pecperiod
     global detcols detrows frow lrow fcol lcol bin xc yc xps yps
     global xlo xhi ylo yhi xdc ydc xac yac xs ys xoff yoff xp yp acqboxcolor scharts
     grab release .startup
     wm deiconify .
     focus .
     destroy .startup
     pause 500
     putmsg " "

# Open socket to AZCAM
     if { $camindex == "NOAZCAM" } {
       putmsg "AzCam communication disabled"
       pause 1500
     } else {
       putmsg "Opening AzCam socket to $azcamhost:$azcamport.  Please wait..."
       set devfile "reset"
       if { $platform == "windows" } { set azcamdir "./" }
       if { $platform == "linux" } { set azcamdir "./" }
       set fileport $azcamport+2
     }

# Find out localhost's IP#, so we can let AZCAM know how to talk to fileserver
    set theserver [socket -server none -myaddr [info hostname] 0]
    set myip [lindex [fconfigure $theserver -sockname] 0]
    close $theserver
    
# Start up imagewriter
#
#      if { $platform == "windows" } { exec python #./StartAzCamImageWriter.py & }
      if { $platform == "linux" } { exec python StartAzCamImageWriter.py & }

# Shared library for centroiding

     if { $platform == "windows" } { load [file join [pwd] GuiderCentroid.dll] Centroid }
     #if { $platform == "windows" } { load "GuiderCentroid.dll" Centroid }

     if { $platform == "linux" } { load "./GuiderCentroid.so" Centroid }
    
# "Remote" image filename is path/filename that AZCAM sees
# This may be different than the GUI if the processes are running on different machines
       set azcamfile [join "$azcamdir $imgfile" ""]
# Open AZCAM socket and initialize AZCAM
       if { $azcamport == "" } {
         tk_messageBox -type ok -icon warning -message "No info for camera $camindex" -title Warning
         set camindex "NOAZCAM"
         set azcamhost disabled
       } else {
         set azcamsock [open_socket $azcamhost $azcamport]
         if { $azcamsock == "" } { set azcamhost disabled }
         set azcamtemp $azcamsock
         set stat ""

         scan [write_azcam $azcamsock "register guider" yes] %s stat

         scan [lowreset] %s stat
         if { $stat != "OK" } {
           putmsg "Could not initialize camera - check power"
           pause 5000
           set camindex "NOAZCAM"
           set azcamhost disabled
          } else {
           setformat 1 512 1 512
           get_detpars
           #scan [write_azcam $azcamsock "Set ImageFolder $azcamdir" yes] %s stat
         }
       }
     
     if { $azcamhost == "disabled" } {
          putmsg "AZCAM communication disabled"
          .menubar.cam entryconfigure 0 -accelerator $camindex
     } else {
          putmsg "AZCAM connection opened to host $azcamhost, port $azcamport"
          set camstat IDLE
          set xac [expr int($xs/2 + $xoff)]
          set yac [expr int($ys/2 + $yoff)]
          set xp $xac
          set yp $yac
          set xdc [expr int($detcols / 2)]
          set ydc [expr int($detrows / 2)]
          set xc $xdc
          set yc $ydc
          set xlo [expr $xac - $xdc]
          set xhi [expr $xac + $xdc]
          set ylo [expr $yac - $ydc]
          set yhi [expr $yac + $ydc]
          set fcol 1
          set lcol $detcols
          set frow 1
          set lrow $detrows
          set xps $detcols
          set yps $detrows
          acqimage configure -width $xps -height $yps
          set azcambusy no
          set compass enabled
          set rptacq no
          set guiding no
          update idletasks
          pause 1500
     }
     
# Let AZCAM know local IP# - NEW
     if { $azcamhost != "disabled" } {
     #scan [write_azcam $azcamsock "Set RemoteImageServerHost $myip" yes] %s stat
     #scan [write_azcam $azcamsock "Set RemoteImageServerPort $fileip" yes] %s stat
     }
     
# Open socket to telescope
     if { $telid != "NOTEL" } {
      putmsg "Opening socket to telescope $telid.  Please wait..."
      #chkfile $telfile
      #set fid [open $telfile]
      set sysid "TCS"
      #if { $telport == "" } { 
      #  tk_messageBox -type ok -icon warning -message "No configuration entry for telescope $telid" -title "Warning"
      #  set telid NOTEL
      #} else {
        catch { set telsock [open_socket $telhost $telport] }
        if { $telsock == "" } { set telid NOTEL }
      #}
     }
     if { $telid == "NOTEL" } {
       putmsg "Telescope communication disabled"
     } else {
       putmsg "Connection opened to $telid, host $telhost, system $sysid, port $telport"
     }
     if { $telid == "BOK" } { set pecstat enabled; set pecperiod 120 }
     if { $telid == "BIG61" } { set pecstat enabled; set pecperiod 180 }
     if { $azcamhost != "disabled" } {
       acqwindow thaw
       flashers freeze
       thaw .sinacq
       thaw .rptacq
       thaw .winstart
       thaw .fullstart
     }
     pause 1500
     pulldowns normal
     set acqboxcolor white
     set acquired no
     drawacqbox
     putmsg "Ready"
     if { $scharts == "enabled" } { strips .strip }
     if { $azcamhost != "disabled" } {
# Start temperature updating
       updatetemp
     }
}

# Shutdown procedure
proc shutdown { } {
     global azcamsock azcamtemp azcamhost telid telsock 
     global plog plogfile tlogfile proclog tellog myip fileip

# Close telescope socket 
     if { $telid != "NOTEL" } { 
         catch {write_tel "SHUTDOWN" no}
         pause 1000
         catch {close $telsock}
        }
# Close AZCAM sockets
     catch {close $azcamsock}
     
# Close AzCamImageWriter, if it is running, by sending "-1" to fileserver
     catch {set fid [socket $myip $fileip]}
     catch {puts $fid "-1"}
     catch {close $fid}
     
# Close down log files, if running
     if { $proclog == "enabled" } { loginit plog $plogfile disabled }
     if { $tellog == "enabled" } { loginit tlog $tlogfile disabled }
     exit
}
       
# Utility procedures ----------------------------------------------------------

# Null procedure
proc noop { dummy } { }

# Event-active timer - pause millisec
proc pause { ms } {
     global plog
     $plog "pause $ms"
     set x 0
     after $ms { set x 1 }
     vwait x
}

# Enable/disable menubar
proc pulldowns { state } {
     global plog
     $plog "pulldowns $state"
     set i 0
     while { $i < 7 } {
       incr i
       .menubar entryconfigure $i -state $state
     }
}

# Thaw a widget
proc thaw { w } {
     global thaw plog
     $plog "thaw $w"
     $w configure -state normal
}

# Freeze widget
proc freeze { w } {
     global plog
     $plog "freeze $w"
     $w configure -state disabled
}

# Round variable to specified number of decimal points
proc roundvar { input digits } {
     global plog
     $plog "roundvar $input $digits"
     upvar $input linkvar
# Ensure "digits" is integer
     set digits [expr int($digits)]
# Compute delta to add to input value
     set delta [expr pow(10., -$digits) * 0.5]
     if { $linkvar < 0 } { set delta -$delta }
# Add delta to input value
     set linkvar [expr $linkvar + $delta]
# Search for decimal point
     set decpnt [string first . $linkvar]
# Select substring to keep
     set trim [expr $decpnt + $digits + 1]
     set linkvar [string replace $linkvar $trim end]
}

# Guider help

proc guiderhelp { helpfile title } {
     global plog
     $plog "guiderhelp $helpfile $title"
# Read help file
     chkfile $helpfile
     set fid [open $helpfile]
     fconfigure $fid -translation auto
     set helptxt [read $fid]
     catch {destroy .hlp}
     toplevel .hlp
     wm title .hlp $title
     wm iconname .hlp "Help"
     wm geometry .hlp +400+50
# Create text widget to display help file
     text .hlp.text -relief sunken -bd 2 -yscrollcommand ".hlp.scroll set" -setgrid 1 \
       -width 70 -height 20 -wrap word
     scrollbar .hlp.scroll -command ".hlp.text yview"
     pack .hlp.scroll -side right -fill y
     pack .hlp.text -expand yes -fill both
     .hlp.text insert 0.0 $helptxt
     freeze .hlp.text
}

# PEC procedures --------------------------------------------------------------

# List utilities

# Delete the $adex element of a list (0-based)
proc ldelete { alist adex } {
     global plog
     $plog "ldelete $alist $adex"
     set alist [lreplace $alist $adex $adex]
}

# Find the 0-based index of the element just less than or equal to a test value
# (Assumes list is in increasing order)
proc lfind { alist aval } {
     global plog
     $plog "lfind $alist $aval"
     set length [llength $alist]
     set i 0
     while { $i < $length } {
       if { [lindex $alist $i] > $aval } break
       incr i
     }
     incr i -1
}

# Linearly interpolate values in blist according to location of $aval in alist
proc linterpolate { alist blist aval } {
     global plog
     $plog "linterpolate $alist $blist $aval"
     set ldex [ lfind $alist $aval]
     if { $ldex == [llength $alist] } { incr ldex -1 }
     set alo [ lindex $alist $ldex ]
     set ahi [ lindex $alist [expr $ldex + 1] ]
     set blo [ lindex $blist $ldex ]
     set bhi [ lindex $blist [expr $ldex + 1] ]
     set bval [ expr ($bhi - $blo) / ($ahi - $alo) * ($aval - $alo) + $blo]
}

#
proc peccompute { } {
     global radel tmid ralist tlist pecperiod msg plog
     $plog "peccompute"
# If lists aren't at least 2 deep, return now
     if { [llength $tlist] < 3 } return
# If $pecperiod hasn't elapsed, return now
     if { [lindex $tlist 0] > [expr $tmid - $pecperiod] } return
# Otherwise, compute RA PEC
# Clear PEC learn light
     freeze .peclearn
     set dt [expr {[lindex $tlist end] - [lindex $tlist end-1]} ]
     set t1 [expr $tmid - $pecperiod]
     set t2 [expr $t1 + $dt]
     set delta0 [expr {[linterpolate $tlist $ralist $t2] - [linterpolate $tlist $ralist $t1]} ]
     set radel [expr $radel - $delta0]
}
  
# get camera status
proc exposurestatus { } {

     global azcamsock camstat
     set cmd "parameters.get_par exposureflag"
     set stat {empty}
     scan [ write_azcam $azcamsock $cmd yes] %s%s resp stat
     if { $resp == "OK" } {
       switch -exact $stat { 
         0 { set camstat IDLE }
         1 { set camstat EXPOSING }
         2 { set camstat ABORT }
         3 { set camstat PAUSE } 
         4 { set camstat RESUME }        
         5 { set camstat READ }        
         6 { set camstat PAUSED }        
         7 { set camstat READOUT }        
         8 { set camstat SETUP }        
         9 { set camstat WRITING }        
         10 { set camstat ERROR }        
       }
     }
}

# End of procedures -----------------------------------------------------------

# Query startup mode
focus .
wm protocol . WM_DELETE_WINDOW { bye }
toplevel .startup
frame .startup.a
pack .startup.a -side top
label .startup.a.msg -width 48 -height 2 -font bf8 -text "Welcome to Steward Autoguider vers. $version \n Choose startup mode:" 
button .startup.a.fresh -width 25 -height 1 -text "Start using default parameters" -default active -command { startup }
button .startup.a.restore -width 25 -height 1 -text "Restart with saved parameters" \
       -command { list puts [chkfile $varfile; source $varfile; restorestat; startup] }
button .startup.a.cancel -width 8 -height 1 -text "Cancel" -command { exit }
pack .startup.a.msg -side top -pady 10
pack .startup.a.fresh .startup.a.restore .startup.a.cancel -side left -padx 10 -pady 10

frame .startup.b
pack .startup.b -side top
label .startup.b.cr -text "\u00A9 2004 - 2008 - The University of Arizona"
pack .startup.b.cr -side left -pady 10

bind .startup <Key-Return> startup
wm geometry .startup +300+250
wm resizable .startup 0 0
focus .startup
grab .startup
     
# End of Guider code-----------------------------------------------------------