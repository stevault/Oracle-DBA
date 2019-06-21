#!/bin/ksh

LOCALHOST=`hostname`
HOST=$LOCALHOST

######################################################

while [ $# -ge 1 ];do

  opt=$1
  shift

  case $opt in
     -h) HOST=$1; shift ;;
      *) echo "I don't know what $opt is...\n" ; exit 2;;
  esac

done

 case $HOST in 
    $LOCALHOST)  ;;
             *)  ssh $HOST "/home/oracle/awdba/show_swap" ; exit $?;; 
 esac

######################################################




