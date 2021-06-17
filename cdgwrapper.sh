#!/bin/bash
#
# Wrapper script for cdrdao and cdgrip.py for all-in-one rip
#
# (P) & (C) 2021-2021 by Peter Bieringer <pb@bieringer.de>
#
# License: GPLv2
#
# 20210617/bieringp: initial version

CDROM="${CDROM:-/dev/cdrom}" # default

showhelp() {
	cat <<END
Usage: $(basename "$0") [-D <device>] [-I] [-R [-c]] <name>
	-D $CDROM	CD device (default)
	-I		Create image using 'cdrdao'
	-e		Eject disk
	-R		Rip tracks from  image using 'cdgrip.py'
	-c		Clean toc/bin file after rip'
END
}

while getopts "D:N:IRceh?" opt; do
	case $opt in
	   D)
		if [ ! -e "$OPTARG" ]; then
			echo "ERROR : given CDROM device is not existing: $OPTARG"
			exit 1
		fi
		CDROM="$OPTARG"
		;;
	   I)
		echo "NOTICE: action 'create image' selected"
		do_image=1
		;;
	   e)
		echo "NOTICE: eject disk after image is created"
		do_image_eject=1
		;;
	   R)
		echo "NOTICE: action 'rip tracks' selected"
		do_rip=1
		;;
	   c)
		echo "NOTICE: clean toc/bin files after rip selected"
		do_rip_clean=1
		;;
	   h|\?)
		showhelp
		exit 2
		;;
	esac
done

shift $[ $OPTIND - 1 ]

if [ -z "$1" ]; then
	echo "ERROR : <name> is required"
	showhelp
	exit 1
fi
NAME="$1"

NAME_TOC="$NAME.toc"
NAME_DATA="$NAME.bin"

if [ "$do_image" = "1" ]; then
	## cdrdao
	echo "INFO   : call now 'cdrdao' with datafile=$NAME_DATA and tocfile=$NAME_TOC from device=$CDROM"
	cdrdao read-cd --driver generic-mmc-raw --device $CDROM --read-subchan rw_raw --datafile $NAME_DATA $NAME_TOC
	rc=$?

	if [ $rc -eq 0 ]; then
		echo "INFO   : 'cdrdao' was successful with datafile=$NAME_DATA and tocfile=$NAME_TOC"
	else
		echo "ERROR  : 'cdrdao' was NOT successful with datafile=$NAME_DATA and tocfile=$NAME_TOC (rc=$rc)"
		exit $rc
	fi
fi

if [ "$do_rip" = "1" ]; then
	## cdgrip
	echo "INFO   : call now 'cdgrip.py' with prefix='$NAME-' and tocfile=$NAME_TOC"
	cdgrip.py ${do_rip_clean:+--delete-bin-toc} --track-prefix "$NAME-" $NAME_TOC
	rc=$?

	if [ $rc -eq 0 ]; then
		echo "INFO   : 'cdgrip.py' was successful with tocfile=$NAME_TOC"
	else
		echo "ERROR  : 'cdgrip' was NOT successful with tocfile=$NAME_TOC (rc=$rc)"
		exit $rc
	fi
fi

if [ "$do_image_eject" = "1" ]; then
	echo "INFO   : call now 'eject' with device=$CDROM"
	eject $CDROM
fi
