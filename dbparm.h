DB=$ORACLE_SID
. /home/oracle/awdba/.sh_common
#OPTSB#####################################################

while [ $# -ge 1 ];do

  opt=$1
  shift

  case $opt in
     -d) DB=$1; shift ;;
  -opts) sh_show_opts ; exit 0 ;;
      *) echo "I don't know what $opt is...\n" ; exit 2;;
  esac

done

#OPTSE#####################################################
