#!/bin/bash

ceph="/usr/bin/ceph"
logfile="/tmp/ceph-mons.log"
check="checkrw.sh"

###
_dump() {
	$ceph -s|awk '/mon: / {print}' > $logfile
}

_mons() {
	raw=( `cat $logfile` )
	mons=( `echo ${raw[@]}|awk -F",| " '{ for (x=6;x<=NF;x++) if ($x!="out" && $x!="of" && $x!="quorum:") print $(x) }'` )
}

_disc_mons() {
	echo -en \{\\n\\t\"data\": \[\\n ;
	for ((i=0;i<${#mons[@]};i++)); do
		echo -en \\t\\t\{\\n\\t\\t\\t\"\{\#MON\}\": \"${mons[$i]}\"\\n\\t\\t\};
		if test $i -lt $((${#mons[@]}-1)); then
			echo ,
		fi
	done
	echo -en \\n\\t\]\\n\}\\n
}

_mon_out() {
	echo ${raw[@]}|grep "out of quorum:" >/dev/null
	if test $? -eq 0; then
		for ((i=0;i<${#raw[@]};i++)); do
			if test ${raw[$i]} == "quorum:"; then
				mark=$i;
			fi;
		done
		echo ${raw[@]}|awk -F",| " '/'$1'/ { for (x='$mark';x<=NF;x++) if ($x ~ "'$1'") print $(x) }'
	fi
}

###
case $1 in
	"dump") . $check; _dump; _check_w && _check_r ;;
	"discovery") _dump; _mons; _disc_mons ;;
	"out") _mons; _mon_out $2 ;;
	*)
esac
