#!/usr/bin/sh

# Change this variable
srvDir=/data/gratefulapi

htmlDir=$srvDir/public_html

if [ ! -d $htmlDir ]; then
    echo "No $htmlDir directory"
    exit 1
fi

dirs=(`ls $htmlDir | grep -E "^[0-9]{8}$"`)
fmt='%-22s %-16s %-10s %s';
printfcmd="printf \"$fmt\n\", substr(\$4, 2), \$1, substr(\$6, 2), \$7"
echo ""
printf "$fmt\n" "[Access Time]" "[IP address]" "[Method]" "[File]"
for dir in ${dirs[@]}; do 
    pattern="$dir/SqlInterface.*.php"
    tac $srvDir/access_log | awk "\$7 ~ \"$pattern\" { $printfcmd; exit; }"
done

echo ""