#!/bin/bash
################################################################################
#
# Mutate kippo.cfg file and base install. This script will remove some obvious 
# kippo signatures and add some randomness to the command set.
#
# Modified by: alienelephant
# Part of: https://github.com/alienelephant/kippo-frankenstein
# Version 1.0
#
# Credits to the orig author:
# Tor Inge Skaar
# The Honeynet Project - Norwegian Chapter (www.honeynor.no)
# https://github.com/toringe/kippomutate/
#
################################################################################

# maybe shuf -n 100 /usr/share/dict/words|grep -v \'|grep -v 'ed' would be better on the fly...?
hostnames=(web3
nas
localhost
kail
bufniag01
grieves
Piraeus
absinthe
braille
lightest
augur
beast
chain
Aruba
nip
corrupter
amazes
Campinas
snuffbox)

ssh_versions=(SSH-2.0-OpenSSH_4.2p1 Debian-7ubuntu3.1
SSH-2.0-OpenSSH_4.3
SSH-2.0-OpenSSH_4.6
SSH-2.0-OpenSSH_5.1p1 Debian-5
SSH-2.0-OpenSSH_5.1p1 FreeBSD-20080901
SSH-2.0-OpenSSH_5.3p1 Debian-3ubuntu5
SSH-2.0-OpenSSH_5.3p1 Debian-3ubuntu6
SSH-2.0-OpenSSH_5.3p1 Debian-3ubuntu7
SSH-2.0-OpenSSH_5.5p1 Debian-6
SSH-2.0-OpenSSH_5.5p1 Debian-6+squeeze1
SSH-2.0-OpenSSH_5.5p1 Debian-6+squeeze2
SSH-2.0-OpenSSH_5.8p2_hpn13v11 FreeBSD-20110503
SSH-2.0-OpenSSH_5.9p1 Debian-5ubuntu1
SSH-2.0-OpenSSH_5.9
)

# randomize hostname and ssh version
hostname=${hostnames[$RANDOM % ${#hostnames[@]}]}
ssh_version_string=${ssh_versions[$RANDOM % ${#ssh_versions[@]}]}
banner_file=""

#
# Generate a random integer between $1 (min) and $2 (max)
#
function rand {
	min=$1
	max=$2
	delta=$(( max - min + 1 ))
	len=${#delta}
	if [ $len -lt 5 ]; then
		len=5
	fi
	clen=$(( len * 2 ))
	alen=$(( len + 1 ))
	rseq=$( head -c ${clen} /dev/urandom | xxd -p | tr -d [:alpha:] | tr -d "\n" | sed 's/^[0]*//g' | awk "{print substr(\$0,0,${alen})}" )
	rnd1=$(( rseq % delta ))
	rnd2=$(( min + rnd1 ))
	echo $rnd2
}
################################################################################

if [ ! -d "honeyfs" ] || [ ! -d "kippo" ] || [ ! -f "kippo.tac" ]; then
	echo "This script must executed from kippo's root directory" >&2
	exit 1
fi

txtcmd=$( cat kippo/core/honeypot.py | grep -i txtcmd | wc -l )
if [ $txtcmd -eq 0 ]; then
	echo "Your kippo version has no support for txtcmds. You should get the latest version from SVN: svn checkout http://kippo.googlecode.com/svn/trunk/ kippo-svn" >&2
	exit 1
fi


if [ ! -f "kippo.cfg" ]; then
  echo "kippo.cfg not found in CWD"
  exit 1
fi

echo "* Mutating kippo.cfg"
echo "[+] Random hostname = $hostname"
echo "[+] Random ssh version = $ssh_version_string"
sed -i "s#^hostname =.*#hostname = $hostname#g" kippo.cfg
sed -i "s#^ssh_version_string =.*#ssh_version_string = $ssh_version_string#g" kippo.cfg

echo "* Mutating ifconfig"
mac="00:02:"$( head -c 4 /dev/urandom | xxd -p | awk '{ print substr($0,1,2)":"substr($0,3,2)":"substr($0,5,2)":"substr($0,7,2) }' )
ip="192.168.1."$( rand 2 254 )
eth0rx1=$( rand 1000000 100000000 )
eth0tx1=$( rand 1000000 100000000 )
eth0rx2=$(( eth0rx1 / 1000 / 1000 )) # Using SI insted of IEC simply because of ease of rounding.
eth0tx2=$(( eth0tx1 / 1000 / 1000 ))
lo_byte1=$( rand 10000 100000 )
lo_byte2=$(( lo_byte1 / 1000 ))

read -d '' IFCONFIG <<EOS
eth0      Link encap:Ethernet  HWaddr ${mac}
          inet addr:${ip}  Bcast:192.168.1.255  Mask:255.255.255.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:$(rand 1000 100000 ) errors:0 dropped:0 overruns:0 frame:0
          TX packets:$(rand 1000 100000 ) errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:${eth0rx1} (${eth0rx2} MB)  TX bytes:${eth0tx1} (${eth0tx2} MB)
          Interrupt:16

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          UP LOOPBACK RUNNING  MTU:16436  Metric:1
          RX packets:$(rand 100 10000) errors:0 dropped:0 overruns:0 frame:0
          TX packets:$(rand 100 10000) errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:${lo_byte1} (${lo_byte2} KB)  TX bytes:${lo_byte1} (${lo_byte2} KB)
EOS

echo "${IFCONFIG}" > txtcmds/sbin/ifconfig

echo "* Mutating last"
ip="192.168.1."$(rand 2 254)
max=$( date -d "48 hours ago" +%s )
min=$( date -d "30 days ago" +%s )
date=$( rand $min $max )
ts=$( rand 10 40 )
te=$(( ts + 18 ))
session=$( rand 0 9 )
txt="root     pts/${session}        ${ip} "$(date -d@${date} +"%a %b %e")" 08:${ts} - 08:${te}  (00:18)\n\nwtmp begins "$( date -d@${min} +"%a %b %e %H:%M:%S %Y") 
echo -e "$txt" > txtcmds/usr/bin/last

echo "* Mutating vi"
vierr[1]="E558: Terminal entry not found in terminfo"
vierr[2]="E518: Unknown option: ?"
vierr[3]="E82: Cannot allocate any buffer, exiting..."
vierr[4]="E95: Buffer with this name already exists"
vierr[5]="E101: More than two buffers in diff mode, don't know which one to use"
vierr[6]="E544: Keymap file not found"
vierr[7]="E655: Too many symbolic links (cycle?)"
vierr[8]="E624: Can't open file"
vierr[9]="E185: Cannot find color scheme"
rnd=$(rand 1 9)
echo ${vierr[${rnd}]} > txtcmds/usr/bin/vi
