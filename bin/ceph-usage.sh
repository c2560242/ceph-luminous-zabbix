#!/bin/bash

# needs second column 'CLASS' for osds to be set;
# otherwise offset for osds must be decreased by 1.

logfile="/tmp/ceph-df.log"
ceph="/usr/bin/ceph"
check="checkrw.sh"

### DO NOT EDIT BELOW ###
_df() {
	df=( `$ceph osd df tree|\
		awk '$10 == "region" {print $4" "$5" "$7" "$10"-"$11}; \
		$10 == "host" {print $4" "$5" "$7" "$10"-"$11}; \
		$11 ~ /osd/ {print $5" "$6" "$8" "$11}'` )
}


_disc() {
	echo -en \{\\n\\t\"data\": \[\\n ;
	for ((i=0;i<${#df[@]};i=$(($i+4)))); do
		if [[ "${df[$(($i+3))]}" =~ region ]]; then
			region=`printf ${df[$(($i+3))]}|sed 's/region-//g'`
			echo -en \\t\\t\{\\n\\t\\t\\t\"\{\#REGION\}\": \"${df[$(($i+3))]}\",\\n;
			echo -en \\t\\t\\t\"\{\#REG_DESCR\}\": \"$region\"\\n\\t\\t\};
		elif [[ "${df[$(($i+3))]}" =~ host ]]; then
			host=`printf ${df[$(($i+3))]}|sed 's/host-//g'`
			echo -en \\t\\t\{\\n\\t\\t\\t\"\{\#HOST\}\": \"${df[$(($i+3))]}\",\\n;
			echo -en \\t\\t\\t\"\{\#HOST_DESCR\}\": \"$host\"\\n\\t\\t\};
		elif [[ "${df[$(($i+3))]}" =~ osd ]]; then
			echo -en \\t\\t\{\\n\\t\\t\\t\"\{\#OSD\}\": \"${df[$(($i+3))]}\",\\n;
			echo -en \\t\\t\\t\"\{\#OSD_DESCR\}\": \"${df[$(($i+3))]} on host $host\"\\n\\t\\t\};
		fi
		if test $i -lt $((${#df[@]}-4)); then
			echo ,
		fi
	done
	echo -en \\n\\t\]\\n\}\\n
}

_percent_usage() {
	awk '/'$1'/ { for (x=1;x<=NF;x++) if ($x == "'$1'") print 100 * $(x-1) }' $logfile
}

_usage() {
	usage=`awk '/'$1'/ { for (x=1;x<=NF;x++) if ($x == "'$1'") print $(x-2) }' $logfile`
	cut=`printf $usage|tr -d TGMK`
	if [[ `echo $usage|egrep G$` =~ "G" ]]; then
		echo $(($cut * 1024 * 1024 * 1024));
	elif [[ `echo $usage|egrep T$` =~ "T" ]]; then
		echo $(($cut * 1024 * 1024 * 1024 * 1024));
	elif [[ `echo $usage|egrep M$` =~ "M" ]]; then
		echo $(($cut * 1024 * 1024))
	elif [[ `echo $usage|egrep K$` =~ "K" ]]; then
		echo $(($cut * 1024));
	fi
}

_total() {
	total=`awk '/'$1'/ { for (x=1;x<=NF;x++) if ($x == "'$1'") print $(x-3) }' $logfile`
	cut=`printf $total|tr -d TGMK`
	if [[ `echo $total|egrep G$` =~ "G" ]]; then
		echo $(($cut * 1024 * 1024 * 1024));
	elif [[ `echo $total|egrep T$` =~ "T" ]]; then
		echo $(($cut * 1024 * 1024 * 1024 * 1024));
	elif [[ `echo $total|egrep M$` =~ "M" ]]; then
		echo $(($cut * 1024 * 1024))
	elif [[ `echo $total|egrep K$` =~ "K" ]]; then
		echo $(($cut * 1024));
	fi
}

###
case $1 in
	"discovery") _df; _disc; echo ${df[@]} >$logfile ;;
	"dump") _df; . $check ; _check_w && echo ${df[@]} >$logfile; _check_r ;;
	"percent") _percent_usage $2 ;; 
	"usage") _usage $2 ;; 
	"total") _total $2 ;;
	*)
esac
