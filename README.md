# install-java-ubuntu

Script to install jdk-8uVERSION-linux-x64.tar.gz on Ubuntu.
You need to download the jdk-8uVERSION-linux-x64.tar.gz file from [oracle web page](https://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)

Tested on (K)Ubuntu 18.04 x64


# Usage

Options:

**Install tar.gz file**

```bash
java-install-0.1.sh --install jdk-<VERSION>-linux-x64.tar.gz
```

**Remove** 

```bash
java-install-0.1.sh --remove java-<VERSION>-oraclejdk-amd64"
```

**See current default java instalation**

```bash
java-install-0.1.sh --status
```


## Why this script

In order to run the [Autopsy forensic browser](https://www.sleuthkit.org/autopsy/download.php) on Linux you need to install the latest version of java 1.8 from Oracle.

Unfortunately, as of April 16 2019, the preferred method **no longer works**:
```bash
$ sudo add-apt-repository ppa:webupd8team/java
$ sudo apt-get update
$ sudo apt-get install oracle-java8-installer
```
You can read more about this [here](https://launchpad.net/~webupd8team/+archive/ubuntu/java).

