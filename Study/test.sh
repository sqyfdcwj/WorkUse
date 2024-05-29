#!/bin/sh

filename=test.txt
x=1
sed -e "$(expr `wc -l < $filename | bc` + 2 - $x)d" $filename