#!/usr/bin/sh

BEGIN {
    fmt = "%-22s %-16s %s"
    printf fmt"\n", "[Access Time]", "[IP address]", "[File]"
}

$7 ~ "^/[0-9]{8}/SqlInterface.*.php" {
    key = substr($7, 2, 8)
    if (key in keyList) {
        next
    }

    keyList[key] = ""
    printf fmt"\n", substr($4, 2), $1, $7
}