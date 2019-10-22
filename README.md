# DEPRECATED: oracle-java-installer [![No Maintenance Intended](http://unmaintained.tech/badge.svg)](http://unmaintained.tech/)

**The porpose of this script was to help the instalation of Autopsy for Linux, but since version 4.13 it changed to OpenJDK, so this script is no longer needed and for that reason it will no longer be updated!**

----------------------------
**Original description:**

Script to install `jdk-VERSION-linux-x64.tar.gz` on Ubuntu.
You need to download the `jdk-VERSION-linux-x64.tar.gz` file from the Oracle web page.
This script was developed with [java 8 from Oracle](https://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html) in mind, but should work with other versions also.

Tested on (K)Ubuntu 18.04 x64


# Usage

Options:

**Install tar.gz file**

```bash
$ sudo ./oracle-java-installer.sh --install jdk-VERSION-linux-x64.tar.gz
```

**Remove** 

```bash
$ sudo ./oracle-java-installer.sh --remove java-VERSION-oraclejdk-amd64"
```

**See current default java installation**

```bash
$ ./oracle-java-installer.sh --status
```


# Why this script

In order to run the [Autopsy forensic browser](https://www.sleuthkit.org/autopsy/download.php) on Linux you need to install the latest version of java 8 from Oracle. 
Unfortunately, since 2019-04-16 the preferred method for Ubuntu **no longer works**:
```bash
$ sudo add-apt-repository ppa:webupd8team/java
$ sudo apt update
$ sudo apt install oracle-java8-installer
```
You can read more about this [here](https://launchpad.net/~webupd8team/+archive/ubuntu/java).

# Share

Cite as:

Miguel Frade, & João Sousa. (2019, June 6). labcif/oracle-java-installer. Zenodo. http://doi.org/10.5281/zenodo.3240243 ([BibTeX file](oracle-java-installer.bib))
