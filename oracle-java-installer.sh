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
        echo "This option requires root permissions."
        exit 1
    fi
    
    mkdir -p jdk-Oracle
    
    # extract and removes first directory
    tar -xvzf $f -C jdk-Oracle --strip-components=1

    # rename the directory
    VERSION=`grep "JAVA_VERSION=" jdk-Oracle/release | cut -d\" -f2`
    ARCH=`grep "OS_ARCH=" jdk-Oracle/release | cut -d\" -f2`
    VERSION="java-$VERSION-oraclejdk-$ARCH"
    mv jdk-Oracle $VERSION

    # move directory
    mkdir -p /usr/lib/jvm
    mv $VERSION /usr/lib/jvm/ || exit
    # change permissions
    chown -R root:root /usr/lib/jvm/$VERSION

    # delete current .jinfo file
    cd /usr/lib/jvm
    rm /usr/lib/jvm/.$VERSION.jinfo

    #echo "name=$VERSION" >> .$VERSION.jinfo
    echo "name=java-`echo $VERSION | cut -d\. -f2`-oraclejdk-$ARCH" 2>&1 | tee --append .$VERSION.jinfo
    echo "alias=$VERSION" 2>&1 | tee --append .$VERSION.jinfo
    echo "priority=$PRIORITY_LEVEL" 2>&1 | tee --append .$VERSION.jinfo
    # echo "section=main" 2>&1 | tee --append .$VERSION.jinfo
    echo "section=non-free" 2>&1 | tee --append .$VERSION.jinfo
    echo "" 2>&1 | tee --append .$VERSION.jinfo

    
    ###JRE BIN ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    cd /usr/lib/jvm/$VERSION/jre/bin/ || exit
    
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
    cd /usr/share/man || exit
    if [[ -L "man19" && -d "man19" ]]; then
        echo "deleting previous symlink to java man pages" 2>&1
        rm man19
    fi
    echo "creating symlink to java man pages" 2>&1
    ln -s /usr/lib/jvm/$VERSION/man/man1 man19 2>&1
    
        
    # current browsers don't support the java plugin
        # # java plugin
        # mkdir -p /usr/lib/mozilla/plugins
        # update-alternatives --install /usr/lib/mozilla/plugins/libjavaplugin.so mozilla-javaplugin.so /usr/lib/jvm/$VERSION/jre/lib/$ARCH/libnpjp2.so 1 2>&1
        # echo "plugin mozilla-javaplugin.so /usr/lib/jvm/$VERSION/jre/lib/$ARCH/libnpjp2.so" 2>&1 | tee --append /usr/lib/jvm/.$VERSION.jinfo

    
    # set JAVA variables
    mv /etc/profile.d/jdk.sh /etc/profile.d/jdk.`date +%F`.bak
    echo "export J2SDKDIR=/usr/lib/jvm/$VERSION" 2>&1 | tee /etc/profile.d/jdk.sh
    echo "export J2REDIR=/usr/lib/jvm/$VERSION/jre" 2>&1 | tee --append /etc/profile.d/jdk.sh
    # echo "export PATH=\$PATH:/usr/lib/jvm/$VERSION/bin:/usr/lib/jvm/$VERSION/db/bin:/usr/lib/jvm/$VERSION/jre/bin" 2>&1 | tee --append /etc/profile.d/jdk.sh
    echo "export JAVA_HOME=/usr/lib/jvm/$VERSION" 2>&1 | tee --append /etc/profile.d/jdk.sh
    # echo "export DERBY_HOME=/usr/lib/jvm/$VERSION/db" 2>&1 | tee --append /etc/profile.d/jdk.sh
    
    export JAVA_HOME=/usr/lib/jvm/$VERSION
    source /etc/profile.d/jdk.sh
    
    # final touch
    update-java-alternatives --set $VERSION 2>&1
    exit
}

######################################
# remove_jdk function
######################################
remove_jdk() {

    if ! [ $(id -u) = 0 ]; then
        echo "This option requires root permissions."
        exit 1
    fi

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
    echo "$0 --install jdk-VERSION-linux-x64.tar.gz"
    echo "$0 --remove java-VERSION-oraclejdk-amd64"
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
    -s | --status )
        status
        ;;
    *)
        print_help
        exit
        ;;
esac
exit



