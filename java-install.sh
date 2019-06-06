#!/bin/bash
# 
# DESCRIPTION:
# 
#   Script for install JDK Oracle amd64 only.
#   Needs root permissions.
#
#   Examples:
#       sudo ./java-oracle.sh --install jdk-8u45-linux-x64.tar.gz
#       sudo ./java-oracle.sh --remove java-1.8.0_45-oraclejdk-amd64
#
# 
# Copyright (C) 2019
#   original script by João Sousa (https://github.com/joaosousa1/install-java-ubuntu)
#   adapted by Miguel Frade
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

######################################
# install_jdk function
######################################
install_jdk() {

    # TODO:
    #   - set JAVA_HOME variable

    mkdir -p jdk-Oracle

    tar -xvzf $f -C jdk-Oracle --strip-components=1

    VERSION=`grep "JAVA_VERSION=" jdk-Oracle/release | cut -d\" -f2`
    ARCH=`grep "OS_ARCH=" jdk-Oracle/release | cut -d\" -f2`
    VERSION="java-$VERSION-oraclejdk-$ARCH"
    mv jdk-Oracle $VERSION

    mkdir -p /usr/lib/jvm
    mv $VERSION /usr/lib/jvm/ || exit
    # change permissions
    chown -R root:root /usr/lib/jvm/$VERSION

    # create file .jinfo
    cd /usr/lib/jvm
    rm /usr/lib/jvm/.$VERSION.jinfo

    #echo "name=$VERSION" >> .$VERSION.jinfo
    echo "name=java-`echo $VERSION | cut -d\. -f2`-oraclejdk-$ARCH" 2>&1 | tee --append .$VERSION.jinfo
    echo "alias=$VERSION" 2>&1 | tee --append .$VERSION.jinfo
    echo "priority=1" 2>&1 | tee --append .$VERSION.jinfo
    echo "section=main" 2>&1 | tee --append .$VERSION.jinfo
    echo "" 2>&1 | tee --append .$VERSION.jinfo

    ###JRE BIN ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    cd /usr/lib/jvm/$VERSION/jre/bin/ || exit
    #update-alternatives install java bin files jre
    for JAVA_EXE_FILE in * 
    do
        update-alternatives --install "/usr/bin/$JAVA_EXE_FILE" "$JAVA_EXE_FILE" "/usr/lib/jvm/$VERSION/jre/bin/$JAVA_EXE_FILE" 1 2>&1
        echo "jre $JAVA_EXE_FILE /usr/lib/jvm/$VERSION/jre/bin/$JAVA_EXE_FILE" 2>&1 | tee --append /usr/lib/jvm/.$VERSION.jinfo
        chmod a+x /usr/bin/$JAVA_EXE_FILE 2>&1
    done

    #jexec
    update-alternatives --install "/usr/bin/jexec" "jexec" "/usr/lib/jvm/$VERSION/jre/lib/jexec" 1 2>&1
    echo "jre jexec /usr/lib/jvm/$VERSION/jre/lib/jexec" 2>&1 | tee --append /usr/lib/jvm/.$VERSION.jinfo

    ###JDK BIN ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    cd /usr/lib/jvm/$VERSION/bin/ || exit
    #update-alternatives install java bin files jdk
    for JAVA_EXE_FILE in * 
    do
        if [ -e /usr/lib/jvm/$VERSION/jre/bin/$JAVA_EXE_FILE ] ; then
            echo "o binário $JAVA_EXE_FILE já existe" 2>&1
        else
            update-alternatives --install "/usr/bin/$JAVA_EXE_FILE" "$JAVA_EXE_FILE" "/usr/lib/jvm/$VERSION/bin/$JAVA_EXE_FILE" 1 2>&1
            echo "jdk $JAVA_EXE_FILE /usr/lib/jvm/$VERSION/bin/$JAVA_EXE_FILE" 2>&1 | tee --append /usr/lib/jvm/.$VERSION.jinfo
            chmod a+x /usr/bin/$JAVA_EXE_FILE 2>&1
        fi
    done

    ## java plugin -- deprecated
    # mkdir -p /usr/lib/mozilla/plugins
    # update-alternatives --install /usr/lib/mozilla/plugins/libjavaplugin.so mozilla-javaplugin.so /usr/lib/jvm/$VERSION/jre/lib/$ARCH/libnpjp2.so 1 2>&1
    # echo "plugin mozilla-javaplugin.so /usr/lib/jvm/$VERSION/jre/lib/$ARCH/libnpjp2.so" 2>&1 | tee --append /usr/lib/jvm/.$VERSION.jinfo

    update-java-alternatives --set $VERSION 2>&1
    exit
}

######################################
# remove_jdk function
######################################
remove_jdk() {
    VERSION="$f"
    ARCH=`echo $VERSION | rev | cut -d- -f1 | rev`

    cd /usr/lib/jvm/$VERSION/jre/bin/ || exit
    for JAVA_EXE_FILE in * 
    do
        update-alternatives --remove "$JAVA_EXE_FILE" "/usr/lib/jvm/$VERSION/jre/bin/$JAVA_EXE_FILE" 2>&1
    done

    cd /usr/lib/jvm/$VERSION/bin/ || exit
    for JAVA_EXE_FILE in * 
    do
        update-alternatives --remove "$JAVA_EXE_FILE" "/usr/lib/jvm/$VERSION/bin/$JAVA_EXE_FILE" 2>&1
    done

    #remove jexec
    update-alternatives --remove "jexec" "/usr/lib/jvm/$VERSION/jre/lib/jexec" 2>&1
    update-alternatives --remove "mozilla-javaplugin.so" /usr/lib/jvm/$VERSION/jre/lib/$ARCH/libnpjp2.so 2>&1
    rm -r /usr/lib/jvm/$VERSION 2>&1
    rm /usr/lib/jvm/.$VERSION.jinfo 2>&1
    exit
}

######################################
# print_help function
######################################
print_help () {
    echo "Options:"
    echo "$0 --install jdk-<VERSION>-linux-x64.tar.gz"
    echo "$0 --remove java-<VERSION>-oraclejdk-amd64"
    echo "$0 --status"
}

######################################
# status function
######################################
status () {
    # see status
    echo "=================================================="
    echo "Status:"
    java -version && update-java-alternatives -l
    echo "=================================================="
    echo ""
    echo "Default java:"
    update-java-alternatives -l | head -1 | cut -d' ' -f1
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
    -h | --status )
        status
        ;;
    *)
        print_help
        exit
        ;;
esac
exit



