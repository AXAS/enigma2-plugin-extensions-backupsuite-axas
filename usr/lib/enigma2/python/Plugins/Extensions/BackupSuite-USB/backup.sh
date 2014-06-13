#!/bin/sh
if tty > /dev/null ; then
   RED='-e \e[00;31m'
   GREEN='-e \e[00;32m'
   YELLOW='-e \e[01;33m'
   BLUE='-e \e[00;34m'
   PURPLE='-e \e[01;31m'
   WHITE='-e \e[00;37m'
else
   RED='\c00??0000'
   GREEN='\c0000??00'
   YELLOW='\c00????00'
   BLUE='\c0000????'
   PURPLE='\c00?:55>7'
   WHITE='\c00??????'
fi
export LANG=$1
export HARDDISK=0
export SHOW="python /usr/lib/enigma2/python/Plugins/Extensions/BackupSuite-HDD/message.py $LANG"
TARGET="XX"
for candidate in /media/*
do
	if [ -f "${candidate}/"*[Bb][Aa][Cc][Kk][Uu][Pp][Ss][Tt][Ii][Cc][Kk]* ]
	then
	TARGET="${candidate}"
	fi 
done

if [ "$TARGET" = "XX" ] ; then
	echo -n $RED
	$SHOW "message21" #error about no USB-found
	echo -n $WHITE
else
	echo -n $YELLOW
	$SHOW "message22" 
	SIZE_1="$(df -h "$TARGET" | tail -n 1 | awk {'print $4'})"
	SIZE_2="$(df -h "$TARGET" | tail -n 1 | awk {'print $2'})"
	echo -n " -> $TARGET ($SIZE_2, " ; $SHOW "message16" ; echo "$SIZE_1)"
	echo -n $WHITE
	backupsuite.sh "$TARGET" 
	sync
fi
