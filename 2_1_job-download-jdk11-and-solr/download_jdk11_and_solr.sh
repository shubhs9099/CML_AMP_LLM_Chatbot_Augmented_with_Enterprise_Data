#!/bin/bash
# This script will help in downloading jdk11 and solr.

JDK_TARGZ=openjdk-11+28_linux-x64_bin.tar.gz
if [ ! -f $JDK_TARGZ ];then
  wget https://download.java.net/openjdk/jdk11/ri/${JDK_TARGZ}
fi
tar zxvf ${JDK_TARGZ}

export JAVA_HOME=/home/cdsw/jdk-11
export PATH=$PATH:$JAVA_HOME/bin

VERSION=9.3.0
SOLRTARGZ=solr-${VERSION}.tgz
solr-${VERSION}/bin/solr stop -all
rm -rf solr-${VERSION}
if [ ! -f ${SOLRTARGZ} ]; then
  wget --no-check-certificate "https://www.apache.org/dyn/closer.lua/solr/solr/${VERSION}/solr-${VERSION}.tgz?action=download" -O ${SOLRTARGZ}
fi
tar xfz ${SOLRTARGZ}