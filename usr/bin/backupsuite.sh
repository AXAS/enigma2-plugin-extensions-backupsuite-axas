###############################################################################
#       FULL BACKUP UYILITY FOR ENIGMA2/OPENPLI, SUPPORTS THE MODELS          #
#      Clark Tech/Xtrend etXX00, MK-Digital XP1000  and                       #
#                                  AXAS MOD                                   #	
#                   MAKES A FULLBACK-UP READY FOR FLASHING.                   #
#                                                                             #
#                   Pedro_Newbie (backupsuite@outlook.com)                    #
###############################################################################
#
#!/bin/sh
############ TESTING IF PROGRAM IS RUN FROM COMMANDLINE OR CONSOLE ############
if tty > /dev/null ; then		# Commandline
	RED='-e \e[00;31m'
	GREEN='-e \e[00;32m'
	YELLOW='-e \e[01;33m'
	BLUE='-e \e[01;34m'
	PURPLE='-e \e[01;31m'
	WHITE='-e \e[00;37m'
else							# On the STB
	RED='\c00??0000'
	GREEN='\c0000??00'
	YELLOW='\c00????00'
	BLUE='\c0000????'
	PURPLE='\c00?:55>7'   
	WHITE='\c00??????'
fi

########################## DECLARATION OF VARIABLES ###########################
VERSION="Version 1.0 for Axas-Support"
START=$(date +%s)
MEDIA="$1"
DATE=`date +%Y%m%d_%H%M`
IMAGEVERSION=`date +%Y%m%d`
MKFS=/usr/sbin/mkfs.ubifs
NANDDUMP=/usr/sbin/nanddump
UBINIZE=/usr/sbin/ubinize
WORKDIR="$MEDIA/bi"
TARGET="XX"
UBINIZE_ARGS="-m 2048 -p 128KiB"
MTDKERNEL="mtd1"
#MKUBIFS_ARGS="-m 2048 -e 126976 -c 4096" moved to ET/XP and VU part

################### START THE LOGFILE /tmp/BackupSuite.log ####################
echo "Plugin version     = $VERSION" > /tmp/BackupSuite.log
echo "Back-up media      = $MEDIA" >> /tmp/BackupSuite.log
df -h "$MEDIA"  >> /tmp/BackupSuite.log
echo "Back-up date_time  = $DATE" >> /tmp/BackupSuite.log
echo "Working directory  = $WORKDIR" >> /tmp/BackupSuite.log

######################### TESTING FOR UBIFS OR JFFS2 ##########################
if grep rootfs /proc/mounts | grep ubifs > /dev/null; then	
	ROOTFSTYPE=ubifs
else
	echo $RED
	$SHOW "message01"			#NO UBIFS, THEN JFFS2 BUT NOT SUPPORTED ANYMORE
	echo $WHITE
	exit 0
fi

####### TESTING IF ALL THE TOOLS FOR THE BUILDING PROCESS ARE PRESENT #########
echo $RED
if [ ! -f $NANDDUMP ] ; then
	echo -n "$NANDDUMP " ; $SHOW "message05"  	# nanddump not found.
	echo "NO NANDDUMP FOUND, ABORTING" >> /tmp/BackupSuite.log
	echo $WHITE
	exit 0
fi
if [ ! -f $MKFS ] ; then
	echo -n "$MKFS " ; $SHOW "message05"  		# mkfs.ubifs not found.
	echo "NO MKFS.UBIFS FOUND, ABORTING" >> /tmp/BackupSuite.log
	echo $WHITE
	exit 0
fi
if [ ! -f $UBINIZE ] ; then
	echo -n "$UBINIZE " ; $SHOW "message05"  	# ubinize not found.
	echo "NO UBINIZE FOUND, ABORTING" >> /tmp/BackupSuite.log
	echo $WHITE
	exit 0
fi
echo -n $WHITE


########## TESTING WHICH BRAND AND MODEL SATELLITE RECEIVER IS USED ###########
#------------------------------------------------------------------------------
####################### XTREND/CLARK TECH AND XP MODELS #######################
if [ -f /proc/stb/info/boxtype ] ; then
	MODEL=$( cat /proc/stb/info/boxtype )
	MKUBIFS_ARGS="-m 2048 -e 126976 -c 4096"
	if grep et /proc/stb/info/boxtype > /dev/null ; then
		TYPE=ET
		SHOWNAME="Xtrend $MODEL"
		MAINDEST="$MEDIA/${MODEL:0:3}x00"
		EXTRA="$MEDIA/fullbackup_${MODEL:0:3}x00/$DATE"
		echo "Destination        = $MAINDEST" >> /tmp/BackupSuite.log
	elif grep xp /proc/stb/info/boxtype > /dev/null ; then
		TYPE=XP
		SHOWNAME="MK-Digital $MODEL"
		MAINDEST="$MEDIA/$MODEL"
		EXTRA="$MEDIA/fullbackup_$MODEL/$DATE"
		echo "Destination        = $MAINDEST" >> /tmp/BackupSuite.log
	elif grep odinm7 /proc/stb/info/boxtype > /dev/null ; then
		TYPE=odinm7
		MTDKERNEL="mtd3"
		SHOWNAME="Axas Classm"
		MAINDEST="$MEDIA/en2"
		EXTRA="$MEDIA/fullbackup_$MODEL/$DATE"
		echo "Destination        = $MAINDEST" >> /tmp/BackupSuite.log
	elif grep e3hd /proc/stb/info/boxtype > /dev/null ; then
		TYPE=e3hd
		SHOWNAME="Axas E3HD"
		MAINDEST="$MEDIA/e3hd"
		EXTRA="$MEDIA/fullbackup_$MODEL/$DATE"
		echo "Destination        = $MAINDEST" >> /tmp/BackupSuite.log
	else
		echo $RED
		$SHOW "message01"  					# No supported receiver found!
		echo $WHITE
		exit 0
	fi

######################### NO SUPPORTED RECEIVER FOUND #########################
else
	echo $RED
	$SHOW "message01"  		# No supported receiver found!
	echo $WHITE
	exit 0
fi
######### END TESTING WHICH BRAND AND MODEL SATELLITE RECEIVER IS USED ########


############# START TO SHOW SOME INFORMATION ABOUT BRAND & MODEL ##############
echo -n $PURPLE
echo -n "$SHOWNAME " | tr  a-z A-Z	# Shows the receiver brand and model
$SHOW "message02"  					# BACK-UP TOOL FOR MAKING A COMPLETE BACK-UP 

echo $BLUE
echo "$VERSION"
echo $WHITE

$SHOW "message03" 	# Please be patient, ... will take about 5-7 minutes 
echo " "
#exit 0  #USE FOR DEBUGGING/TESTING


##################### PREPARING THE BUILDING ENVIRONMENT ######################
rm -rf "$WORKDIR"		# GETTING RID OF THE OLD REMAINS IF ANY
echo "Remove directory   = $WORKDIR" >> /tmp/BackupSuite.log
mkdir -p "$WORKDIR"		# MAKING THE WORKING FOLDER WHERE EVERYTHING HAPPENS
echo "Recreate directory = $WORKDIR" >> /tmp/BackupSuite.log
mkdir -p /tmp/bi/root
echo "Create directory   = /tmp/bi/root" >> /tmp/BackupSuite.log
sync
mount --bind / /tmp/bi/root


####################### START THE REAL BACK-UP PROCESS ########################
#------------------------------------------------------------------------------
############################# MAKING UBINIZE.CFG ##############################
echo \[ubifs\] > "$WORKDIR/ubinize.cfg"
echo mode=ubi >> "$WORKDIR/ubinize.cfg"
echo image="$WORKDIR/root.ubi" >> "$WORKDIR/ubinize.cfg"
echo vol_id=0 >> "$WORKDIR/ubinize.cfg"
echo vol_type=dynamic >> "$WORKDIR/ubinize.cfg"
echo vol_name=rootfs >> "$WORKDIR/ubinize.cfg"
echo vol_flags=autoresize >> "$WORKDIR/ubinize.cfg"
echo " " >> /tmp/BackupSuite.log
echo "UBINIZE.CFG CREATED WITH THE CONTENT:"  >> /tmp/BackupSuite.log
cat "$WORKDIR/ubinize.cfg"  >> /tmp/BackupSuite.log
touch "$WORKDIR/root.ubi"
chmod 644 "$WORKDIR/root.ubi"
echo "--------------------------" >> /tmp/BackupSuite.log

#############################  MAKING ROOT.UBI(FS) ############################
$SHOW "message06a"  						#Create: root.ubifs
echo "Start creating root.ubi"  >> /tmp/BackupSuite.log
$MKFS -r /tmp/bi/root -o "$WORKDIR/root.ubi" $MKUBIFS_ARGS
if [ -f "$WORKDIR/root.ubi" ] ; then
	echo "ROOT.UBI MADE:" >> /tmp/BackupSuite.log
	ls -e1 "$WORKDIR/root.ubi" >> /tmp/BackupSuite.log
else 
	echo "$WORKDIR/root.ubi NOT FOUND"  >> /tmp/BackupSuite.log
fi

echo "Start UBINIZING" >> /tmp/BackupSuite.log
$UBINIZE -o "$WORKDIR/root.ubifs" $UBINIZE_ARGS "$WORKDIR/ubinize.cfg" >/dev/null
chmod 644 "$WORKDIR/root.ubifs"
if [ -f "$WORKDIR/root.ubifs" ] ; then
	echo "ROOT.UBIFS MADE:" >> /tmp/BackupSuite.log
	ls -e1 "$WORKDIR/root.ubifs" >> /tmp/BackupSuite.log
else 
	echo "$WORKDIR/root.ubifs NOT FOUND"  >> /tmp/BackupSuite.log
fi

############################## MAKING KERNELDUMP ##############################
echo "Start creating kerneldump" >> /tmp/BackupSuite.log
$SHOW "message07"  							# Create: kerneldump
$NANDDUMP /dev/$MTDKERNEL -q > "$WORKDIR/vmlinux.gz"

if [ -f "$WORKDIR/vmlinux.gz" ] ; then
	echo "VMLINUX.GZ MADE:" >> /tmp/BackupSuite.log
	ls -e1 "$WORKDIR/vmlinux.gz" >> /tmp/BackupSuite.log
else 
	echo "$WORKDIR/vmlinux.gz NOT FOUND"  >> /tmp/BackupSuite.log
fi
echo "--------------------------" >> /tmp/BackupSuite.log


############################ ASSEMBLING THE IMAGE #############################
#------------------------------------------------------------------------------
##################### HANDLING THE ET and XP1000 SERIES   #####################

	rm -rf "$MAINDEST"
	echo "Removed directory  = $MAINDEST"  >> /tmp/BackupSuite.log
	mkdir -p "$MAINDEST"
	echo "Created directory  = $MAINDEST"  >> /tmp/BackupSuite.log
	mkdir -p "$EXTRA"
	echo "Created directory  = $EXTRA" >> /tmp/BackupSuite.log
	mv "$WORKDIR/root.ubifs" "$MAINDEST/rootfs.bin" 
	mv "$WORKDIR/vmlinux.gz" "$MAINDEST/kernel.bin"
	echo "rename this file to 'force' to force an update without confirmation" > "$MAINDEST/noforce"; 
	echo "Axas-Support-$IMAGEVERSION" > "$MAINDEST/imageversion"
	cp -r "$MAINDEST" "$EXTRA" 					#copy the made back-up to images
	if [ -f "$MAINDEST/rootfs.bin" -a -f "$MAINDEST/kernel.bin" -a -f "$MAINDEST/imageversion" -a -f "$MAINDEST/noforce" ] ; then
		echo " "  >> /tmp/BackupSuite.log
		echo "BACK-UP MADE SUCCESSFULLY IN: $MAINDEST"  >> /tmp/BackupSuite.log
		echo " "
		$SHOW "message10" ; echo "$MAINDEST" 	# USB Image created in: 
		$SHOW "message23"		# "The content of the folder is:"
		ls "$MAINDEST" -e1h | awk {'print $3 "\t" $7'}
		ls -e1 "$MAINDEST" >> /tmp/BackupSuite.log
		echo " "
		$SHOW "message11" ; echo "$EXTRA"		# and there is made an extra copy in:
		echo " "
		if [ ${MODEL:0:3}x00 = "et9x00" -o $MODEL = "et6500" ] ; then 
			$SHOW "message12" 		# directions for a ET9x00/ET6500 series
		elif [ ${MODEL:0:3}x00 = "et5x00" -o $MODEL = "et6000" -o $MODEL = "xp1000" ] ; then 
			$SHOW "message13" 	# directions for a ET5X00/ET6000/XP1000 series
		else 
			$SHOW "message14" 	# Please check te manual of the receiver on how to restore the image.
		fi
	else
		echo -n $RED
		$SHOW "message15" 		# Image creation FAILED!
		echo $WHITE
	fi

#################### END OF THE ET AND XP1000 SERIES PART #####################
 
 



#################### CHECKING FOR AN EXTRA BACKUP STORAGE #####################
if  [ $HARDDISK = 1 ]; then						# looking for a valid usb-stick
	for candidate in /media/sd* /media/mmc* /media/usb* /media/*
	do
		if [ -f "${candidate}/"*[Bb][Aa][Cc][Kk][Uu][Pp][Ss][Tt][Ii][Cc][Kk]* ]
		then
		TARGET="${candidate}"
		fi    
	done
	if [ "$TARGET" != "XX" ] ; then
		echo $GREEN
		$SHOW "message17"  	# Valid USB-flashdrive detected, making an extra copy
		echo " "
		TOTALSIZE="$(df -h "$TARGET" | tail -n 1 | awk {'print $2'})"
		FREESIZE="$(df -h "$TARGET" | tail -n 1 | awk {'print $4'})"
		$SHOW "message09" ; echo -n "$TARGET ($TOTALSIZE, " ; $SHOW "message16" ; echo "$FREESIZE)"
		if [ $TYPE = "ET" ] ; then				# ET detected
			rm -rf "$TARGET/${MODEL:0:3}x00"		
			mkdir -p "$TARGET/${MODEL:0:3}x00"
			cp -r "$MAINDEST" "$TARGET"
			echo " " >> /tmp/BackupSuite.log
			echo "MADE AN EXTRA COPY IN: $TARGET" >> /tmp/BackupSuite.log
			df -h "$TARGET"  >> /tmp/BackupSuite.log
		elif [ $TYPE = "XP" ] ; then # xp
			rm -rf "$TARGET/$MODEL"	
			mkdir -p "$TARGET/$MODEL"
			cp -r "$MAINDEST" "$TARGET"
			echo " " >> /tmp/BackupSuite.log
			echo "MADE AN EXTRA COPY IN: $TARGET" >> /tmp/BackupSuite.log
			df -h "$TARGET"  >> /tmp/BackupSuite.log
		elif [ $TYPE = "e3hd"] ; then # e3hd detected
			rm -rf "$TARGET/e3hd"	
			mkdir -p "$TARGET/e3hd"
			cp -r "$MAINDEST" "$TARGET"
			echo " " >> /tmp/BackupSuite.log
			echo "MADE AN EXTRA COPY IN: $TARGET" >> /tmp/BackupSuite.log
			df -h "$TARGET"  >> /tmp/BackupSuite.log
		elif [ $TYPE = "odinm7"] ; then # odin7 detected
			rm -rf "$TARGET/en2"	
			mkdir -p "$TARGET/en2"
			cp -r "$MAINDEST" "$TARGET"
			echo " " >> /tmp/BackupSuite.log
			echo "MADE AN EXTRA COPY IN: $TARGET" >> /tmp/BackupSuite.log
			df -h "$TARGET"  >> /tmp/BackupSuite.log
		fi
    sync
	$SHOW "message19" 	# Backup finished and copied to your USB-flashdrive
	fi
fi
######################### END OF EXTRA BACKUP STORAGE #########################


################## CLEANING UP AND REPORTING SOME STATISTICS ##################
umount /tmp/bi/root					# And as last some cleaning and reporting
rmdir /tmp/bi/root
rmdir /tmp/bi
rm -rf "$WORKDIR"
sleep 5
END=$(date +%s)
DIFF=$(( $END - $START ))
MINUTES=$(( $DIFF/60 ))
SECONDS=$(( $DIFF-(( 60*$MINUTES ))))
if [ $SECONDS -le  9 ] ; then 
	SECONDS="0$SECONDS"
fi
echo -n $YELLOW
$SHOW "message24"  ; echo -n "$MINUTES.$SECONDS " ; $SHOW "message25"
echo "BACKUP FINISHED IN $MINUTES.$SECONDS MINUTES" >> /tmp/BackupSuite.log
echo -n $WHITE
exit 
#-----------------------------------------------------------------------------
