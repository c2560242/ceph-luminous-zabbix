#!/bin/bash
 
cols=( `cat /proc/partitions ` )
 
out=( `x=1
for ((i=6;i<${#cols[@]};i=$(($i+4)))); do
    for j in {a..z}; do
        if test $x -le 2; then
            if test ${cols[$i]} -ge 250059096 &&
            test ${cols[$(($i+1))]} == "sd$j" ; then
                printf /dev/${cols[$(($i+1))]};
                x=$(($x+1))
            fi;
        else
            exit 0;
        fi
    done;
    for j in {a..z}; do
        if test $x -le 2; then
            if test ${cols[$i]} -ge 250059096 &&
            test ${cols[$(($i+1))]} == "sda$j" ; then
                printf /dev/${cols[$(($i+1))]};
                x=$(($x+1))
            fi;
        else
            exit 0;
        fi
    done;
    echo;
done` )
echo ${out[@]}
