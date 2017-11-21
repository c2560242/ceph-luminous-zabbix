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

