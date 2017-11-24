#!/bin/bash

_check_r() {
	if test ! -r $logfile; then
		echo READ; exit 1;
	fi
}

_check_w() {
	if test ! -w $logfile; then
		echo WRITE; exit 2;
	fi
}

_convert() {
	cut=`printf $took|tr -d TGMK`
	if [[ `echo $took|egrep G$` =~ "G" ]]; then
		echo $(($cut * 1024 * 1024 * 1024));
	elif [[ `echo $took|egrep T$` =~ "T" ]]; then
		echo $(($cut * 1024 * 1024 * 1024 * 1024));
	elif [[ `echo $took|egrep M$` =~ "M" ]]; then
		echo $(($cut * 1024 * 1024))
	elif [[ `echo $took|egrep K$` =~ "K" ]]; then
		echo $(($cut * 1024));
	fi
}

