#!/bin/bash

ceph="/usr/bin/ceph"
logfile="/tmp/ceph-osd.log"

###
. ceph-functions.sh

### do not edit below
_dump() {
	osd=( `$ceph osd tree|awk '/osd/ {print $4" "$5}'` )
	echo ${osd[@]} >$logfile
}

_updown() {
	awk '{ for (x=1;x<=NF;x++) if ($x ~ "'"$1"'") print $(x+1) }' $logfile
}

###
case $1 in
	"dump") _dump; _check_w && _check_r ;;
	$1) _updown $1 ;;
	*)
esac
