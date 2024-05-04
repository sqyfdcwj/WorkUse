#!/bin/sh

export PGPASSWORD='xtra!@#$%'

for fn in *.sql
do
    sql=`cat $fn`
    psql -h 10.169.6.241 -p 5438 -d erp_hingfat__20240420 -U postgres \
        -c "$sql" \
        -c '\q'
done