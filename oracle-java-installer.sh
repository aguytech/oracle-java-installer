#!/bin/bash
# 
# DESCRIPTION:
# 
#   Script to install Oracle JDK.
#   Needs root permissions.
#
#   Examples:
#       ./oracle-java-installer.sh --help
#       ./oracle-java-installer.sh --status
#       sudo ./oracle-java-installer.sh --install jdk-8u211-linux-x64.tar.gz
#       sudo ./oracle-java-installer.sh --remove java-1.8.0_212-oraclejdk-amd64
#
# 
# Copyright (C) 2019
#   original script by João Sousa (https://github.com/joaosousa1/install-java-ubuntu)
#   modified by Miguel Frade
#
#
# LICENSE:
# 
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
# 
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
# 
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.
#


export f=$2
export PRIORITY_LEVEL=1

######################################
# install_jdk function
######################################
install_jdk() {

    if ! [ $(id -u) = 0 ]; then
        echo "[ERROR] This option requires root permissions."
        exit 1
    fi
    
    if ! [ -f "$f" ]; then
        echo "[ERROR] file $f doesn't exists."
        exit 1
    fi
    
    # get the name of the first dir
    echo "[INFO ] Getting version number..."
    TOP_DIR=`tar -tf $f | head -1 | cut -f1 -d"/"`
    mkdir -p jdk-Oracle
    # extract only release file
    # too slow, but works
    tar -xvzf $f -C jdk-Oracle --strip-components=1 --skip-old-files $TOP_DIR/release

    # get version info
    NUMBER=`grep "JAVA_VERSION=" jdk-Oracle/release | cut -d\" -f2`
    ARCH=`grep "OS_ARCH=" jdk-Oracle/release | cut -d\" -f2`
    VERSION="java-$NUMBER-oraclejdk-$ARCH"
    DEST_DIR="/usr/lib/jvm/$VERSION/jre/bin/"
    
    SYSTEM_ARCH=`dpkg --print-architecture`
    if ! [ $SYSTEM_ARCH == $ARCH ]; then
        echo "[ERROR] This java version is for \"$ARCH\","
        echo "[ERROR] but your system is \"$SYSTEM_ARCH\"."
        exit 1
    fi
    
    if [ -d "$DEST_DIR" ]; then
        echo "[ERROR] $VERSION is already installed."
        # print status
        $0 -s
        exit 1
    fi
    
    
    # extract and removes first directory
    echo "[INFO ] Extracting files from $f..."
    tar -xvzf $f -C jdk-Oracle --strip-components=1 --skip-old-files 
    echo "[INFO ] Files extracted from $f."
    
    mv jdk-Oracle $VERSION

    # move directory
    mkdir -p /usr/lib/jvm
    
    
    echo "[INFO ] Installing $VERSION ..."
    mv $VERSION /usr/lib/jvm/ || exit
    # change permissions
    chown -R root:root /usr/lib/jvm/$VERSION

    # delete current .jinfo file
    cd /usr/lib/jvm
    [ -f /usr/lib/jvm/.$VERSION.jinfo ] && rm /usr/lib/jvm/.$VERSION.jinfo

    #echo "name=$VERSION" >> .$VERSION.jinfo
    echo "name=java-`echo $VERSION | cut -d\. -f2`-oraclejdk-$ARCH" 2>&1 | tee --append .$VERSION.jinfo
    echo "alias=$VERSION" 2>&1 | tee --append .$VERSION.jinfo
    echo "priority=$PRIORITY_LEVEL" 2>&1 | tee --append .$VERSION.jinfo
    # echo "section=main" 2>&1 | tee --append .$VERSION.jinfo
    echo "section=non-free" 2>&1 | tee --append .$VERSION.jinfo
    echo "" 2>&1 | tee --append .$VERSION.jinfo

    
    ###JRE BIN ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    cd $DEST_DIR || exit
    
    echo "[INFO ] Adding $VERSION to update-alternatives..."
    #update-alternatives install java bin files jre
    for JAVA_EXE_FILE in * 
    do
        update-alternatives --install "/usr/bin/$JAVA_EXE_FILE" "$JAVA_EXE_FILE" "/usr/lib/jvm/$VERSION/jre/bin/$JAVA_EXE_FILE" $PRIORITY_LEVEL 2>&1
        echo "jre $JAVA_EXE_FILE /usr/lib/jvm/$VERSION/jre/bin/$JAVA_EXE_FILE" 2>&1 | tee --append /usr/lib/jvm/.$VERSION.jinfo
        chmod a+x /usr/bin/$JAVA_EXE_FILE 2>&1
    done

    #jexec
    update-alternatives --install "/usr/bin/jexec" "jexec" "/usr/lib/jvm/$VERSION/jre/lib/jexec" $PRIORITY_LEVEL 2>&1
    echo "jre jexec /usr/lib/jvm/$VERSION/jre/lib/jexec" 2>&1 | tee --append /usr/lib/jvm/.$VERSION.jinfo

    
    ###JDK BIN ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    cd /usr/lib/jvm/$VERSION/bin/ || exit
    #update-alternatives install java bin files jdk
    for JAVA_EXE_FILE in * 
    do
        if [ -e /usr/lib/jvm/$VERSION/jre/bin/$JAVA_EXE_FILE ] ; then
            echo "the file \'$JAVA_EXE_FILE\' already exixts" 2>&1
        else
            update-alternatives --install "/usr/bin/$JAVA_EXE_FILE" "$JAVA_EXE_FILE" "/usr/lib/jvm/$VERSION/bin/$JAVA_EXE_FILE" $PRIORITY_LEVEL 2>&1
            echo "jdk $JAVA_EXE_FILE /usr/lib/jvm/$VERSION/bin/$JAVA_EXE_FILE" 2>&1 | tee --append /usr/lib/jvm/.$VERSION.jinfo
            chmod a+x /usr/bin/$JAVA_EXE_FILE 2>&1
        fi
    done

    ###man pages ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    echo "[INFO ] Adding $VERSION man pages..."
    cd /usr/share/man || exit
    if [[ -L "man19" && -d "man19" ]]; then
        echo "deleting previous symlink to java man pages" 2>&1
        rm man19
    fi
    echo "creating symlink to java man pages" 2>&1
    ln -s /usr/lib/jvm/$VERSION/man/man1 man19 2>&1

    echo "[INFO ] Setting JAVA variables..."
    # set JAVA variables
    [ -f /etc/profile.d/jdk.sh ] && mv /etc/profile.d/jdk.sh /etc/profile.d/jdk.`date +%F`.bak
    echo "export J2SDKDIR=/usr/lib/jvm/$VERSION" 2>&1 | tee /etc/profile.d/jdk.sh
    echo "export J2REDIR=/usr/lib/jvm/$VERSION/jre" 2>&1 | tee --append /etc/profile.d/jdk.sh
    echo "export JAVA_HOME=/usr/lib/jvm/$VERSION" 2>&1 | tee --append /etc/profile.d/jdk.sh
    # echo "export DERBY_HOME=/usr/lib/jvm/$VERSION/db" 2>&1 | tee --append /etc/profile.d/jdk.sh
    
    export JAVA_HOME=/usr/lib/jvm/$VERSION
    source /etc/profile.d/jdk.sh
    
    # final touch
    update-java-alternatives --set $VERSION 2>&1
    
    
    echo "[INFO ] Install of $VERSION complete."
    
    # print status
    $0 -s
    exit
}

######################################
# remove_jdk function
######################################
remove_jdk() {

    if ! [ $(id -u) = 0 ]; then
        echo "[ERROR] This option requires root permissions."
        exit 1
    fi
    
    # $f = java-1.8.0_212-oraclejdk-amd64
    VERSION=$f
    IS_ORACLE=`echo $VERSION | cut -d- -f 3`
    
    if [ "$IS_ORACLE" == "openjdk" ]; then
        echo "[ERROR] $VERSION is from OpenJDK."
        echo "[ERROR] Use your system's packet manager instead to remove it."
        exit 1
    fi
    
    if [ "$IS_ORACLE" != "oraclejdk" ]; then
        echo "[ERROR] $VERSION is not known. Currently installed java JVM are:"
        $0 --status
        exit 1
    fi
    
    
    if ! [ -d "/usr/lib/jvm/$VERSION" ]; then
        echo "[ERROR] $VERSION doesn't exist. Currently installed java JVM are:"
        $0 --status
        exit 1
    fi
    
    PREVIOUS_DIR=`pwd`
    
    cd /usr/lib/jvm/$VERSION || exit 1
    
    echo "[INFO ] Removing update-alternatives entries ..."
    for JAVA_EXE_FILE in * 
    do
        update-alternatives --remove "$JAVA_EXE_FILE" "/usr/lib/jvm/$VERSION/jre/bin/$JAVA_EXE_FILE" 2>&1
    done

    cd /usr/lib/jvm/$VERSION/bin/ || exit 1
    for JAVA_EXE_FILE in * 
    do
        update-alternatives --remove "$JAVA_EXE_FILE" "/usr/lib/jvm/$VERSION/bin/$JAVA_EXE_FILE" 2>&1
    done

    #remove jexec
    update-alternatives --remove "jexec" "/usr/lib/jvm/$VERSION/jre/lib/jexec" 2>&1
    
    cd $PREVIOUS_DIR
    
    echo "[INFO ] Deleting $VERSION files ..."
    rm -r /usr/lib/jvm/$VERSION 2>&1
    rm /usr/lib/jvm/.$VERSION.jinfo 2>&1
    rm /etc/profile.d/jdk.sh 2>&1
    
    echo "[INFO ] Setup another java alternative."
    update-java-alternatives -a
    
    echo "[INFO ] $VERSION is removed."
    
    # print status
    $0 -s
    
    exit
}

######################################
# print_help function
######################################
print_help () {
    echo "Options:"
    echo "$0 --install jdk-VERSION-linux-x64.tar.gz"
    echo "$0 --remove java-VERSION-oraclejdk-amd64"
    echo "$0 --status"
}

######################################
# status function
######################################
status () {
    # see status
    echo "Status:"
    echo "=================================================="
    update-java-alternatives -l
    echo "--------------------------------------------------"
    java -version
    echo "=================================================="
    echo ""
    echo "Default java from update-java-alternatives:"
    update-java-alternatives -l | head -1 | cut -d' ' -f1
    echo ""
    echo "JAVA_HOME=$JAVA_HOME"
    echo ""
}


######################################
# main
######################################
case $1 in
    -i | --install)
        echo "INSTALL JDK"
        echo "tar.gz file: $2"
        install_jdk
        ;;
    -r | --remove)
        echo "REMOVE JDK"
        echo "Remove version: $2"
        remove_jdk
        ;;
    -h | --help )
        print_help
        ;;
    -s | --status )
        status
        ;;
    *)
        print_help
        exit
        ;;
esac
exit



