#!/bin/bash

# get username and password
USER=w0140eef #Your username
PASS=Zy8BPNzFCq2h #Your password
HOST="dominikschreiber.de" #Keep just the address
LCD="./" #Your local directory
RCD="dominikschreiber.de" #FTP server directory

tar czvf archive.tar.gz $1

lftp -f "
set ftp:ssl-allow no
open $HOST
user $USER $PASS
lcd $LCD
mirror --continue --reverse --only-newer --verbose --exclude .* --exclude .*/ --include archive.tar.gz $LCD $RCD
bye
" 
