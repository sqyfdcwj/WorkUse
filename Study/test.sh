#!/bin/sh

filename=test.txt
sed -e "$(expr `wc -l < $filename | bc` + 1 - $x)d" $filename