#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

INSTALL_DIR="/usr/local/bin"
FILENAME="oracle-java-installer"

cp $FILENAME.sh $INSTALL_DIR/$FILENAME
chmod +x $INSTALL_DIR/$FILENAME

echo "Done"
