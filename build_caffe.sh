#!/bin/bash

BOOSTSRC=boost_1_56_0.tar.gz
BOOSTVER=`echo $BOOSTSRC | perl -ne '@l=split(/\./,$_);@m=split(/_/,@l[0]);print "@m[1].@m[2].@m[3]"'`


# quiet pushd
mypush() 
{
  pushd $1 >& /dev/null
  if [ $? -ne 0 ]; then
    echo "Error! Directory $1 does not exist."
    exit 1
  fi
}

# quiet popd
mypop() 
{
  popd >& /dev/null
}

# get it from the archive if it is there; else online
getcode()
{
  if [ -f $ARCHIVE/$1 ]; then
    echo "Retrieving code from archive..."
    mv $ARCHIVE/$1 .
    tar -xvzf $1 >& /dev/null
    mv $1 $ARCHIVE
  else
    echo "Downloading code from the internet..."
    if [ $# -eq 2 ]; then
      $WGET $2/$1 >& /dev/null
    elif [ $# -eq 3 ]; then
      $WGET $2/$1/$3
      # $WGET $2/$1/$3 >& /dev/null  # for boost, basically
    fi
    tar -xvzf $1 >& /dev/null
    mv $1 $ARCHIVE
  fi
}

# Make sure the archive area is set up.
if [[ ! -d archive ]]; then
  mkdir archive
  mypush archive
  ARCHIVE=`pwd`
  echo "Saving source tarballs to $ARCHIVE"
  mypop  # archive
fi

WGET=`which wget`
if [ "$WGET" == "" ]; then
  echo "This script is not clever enough to live without wget yet."
  echo "Please edit it and replace wget with whatever executable you"
  echo "have that is appropriate. You could track down the binaries"
  echo "and put them in the archive directory instead as a work-around."
fi


ENVFILE="setup_environment.sh"
echo -e "\043\041/bin/bash" > $ENVFILE

# Build OpenBLAS
if [[ -d "OpenBLAS" ]]; then
  echo "OpenBLAS directory already exists, skipping this step."
else
  git clone git@github.com:xianyi/OpenBLAS.git
  mypush OpenBLAS
  echo "export OPENBLASDIR=`pwd`" >> $ENVFILE
  make >& log.make
  mypop  # OpenBLAS
fi

BOOSTDIR=`basename ${BOOSTSRC} .tar.gz`
BOOSTROOT=boost
if [ -d $BOOSTROOT ]; then
  echo "$BOOSTROOT directory already exists, skipping this step."
else
  mkdir $BOOSTROOT
  mypush $BOOSTROOT
  echo "Building boost $BOOSTVER in $PWD..."
  BOOSTINST=`pwd`
  echo "Boost install directory is $BOOSTINST..."
  getcode $BOOSTSRC http://sourceforge.net/projects/boost/files/boost/${BOOSTVER} download
  echo "Header-only libraries! Not building anything..."
  mypush $BOOSTDIR
  BOOST_ROOT=`pwd`
  mypop  # $BOOSTDIR
  mypop  # $BOOSTROOT
  echo "Boost root is $BOOST_ROOT..."
  echo "export BOOST_ROOT=$BOOST_ROOT" >> $ENVFILE
fi
