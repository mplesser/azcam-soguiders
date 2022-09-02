# Set_IP_Address.py
# Sets the IP address of a Window 7 PC.
# 14Aug12 last change MPL

import sys,os,subprocess,socket

# look for command line option
try:
    menu=int(sys.argv[1])
    prompt=0
except:
    prompt=1
    
# get name of this computer
pcname=socket.gethostname()

print
print '*****************************************************'
print ' This script will change this computer\'s IP address!'
print '*****************************************************'
print
print 'This computer is %s' % pcname
print

if prompt:
    if pcname!='spolguider':    
        print 'Select 0 for DHCP'
        print '       1 for mountain default'
    else:
        print 'Select 0 for DHCP'
        print '       1 for BOK default'
        print '       2 for BIG61 default'
    print
    menu=raw_input('Enter menu choice number from above (return to quit): ')
    print

if menu=='':
    sys.exit('Quitting...')
    
menu=int(menu)

# make import file name
if pcname=='spolguider' and menu>0:
    SITE=['','bok','big61']
    lanfile=pcname+SITE[menu]+'_IP'
elif pcname=='spolguider':
    lanfile=pcname+'bok_IP' # need LAN
else:
    lanfile=pcname+'_IP'

# import
try:
    s='from %s import *' % lanfile
    exec s
except:
    print 'ERROR importing IP info file %s.py' % lanfile
    raw_input('\nPress any key to exit...')
    sys.exit('Quitting.')

if menu!=0:
    print 'IP values read from file %s.py are:' % lanfile
    print ' LAN name:',lan
    print ' IP address:',ip
    print ' Subnet Mask:',subnetmask
    print ' Gateway:',gateway
    print ' DNS server primary:',dns1
    try:  # DNS2 may be undefined
        print ' DNS server secondary:',dns2
    except:
        pass
    
print
print 'Current LAN settings:'
s='netsh interface ip show addresses name=\"%s\"' % lan
subprocess.call(s, shell=True)

if menu==0:
    print 'Setting IP info to DHCP'
else:
    print 'Changing \"%s\" address to: %s' % (lan,ip)

if menu==0:
    s='netsh interface ip set address name=\"%s\" source=dhcp' % lan
    subprocess.call(s, shell=True)
    s='netsh interface ip set dnsservers name=\"%s\" source=dhcp' % lan
    subprocess.call(s, shell=True)
else:
    s='netsh interface ip set dnsservers name=\"%s\" source=static %s primary' % (lan,dns1)
    subprocess.call(s, shell=True)
    try:  # dns2 may be undefined
        s='netsh interface ip set dnsservers name=\"%s\" source=static %s none' % (lan,dns2)    
        subprocess.call(s, shell=True)
    except:
        pass
    s='netsh interface ip set address name=\"%s\" source=static %s %s %s 1' % (lan,ip,subnetmask,gateway)
    subprocess.call(s, shell=True)

print
print 'New LAN settings:'
s='netsh interface ip show addresses name=\"%s\"' % lan
subprocess.call(s, shell=True)

# finished
print
print '*****************************************************'
print ' Finished.  Press any key to close...'
print '*****************************************************'
if prompt:
    raw_input()
