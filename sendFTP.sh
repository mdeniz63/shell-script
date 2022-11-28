# FTP send script save as sendFtp.sh
#!/bin/sh
HOST=192.168.1.10
USER=USERNAME
PASS=PASSWORD
FILE=FILENAME
LOCALPATH=/backup/
REMOTEPATH=.
ftp -inv <<EOF
open $HOST
user "$USER" "$PASS"
lcd "$LOCALPATH"
cd "$REMOTEPATH"
put $FILE
$@
EOF