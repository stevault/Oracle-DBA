DB=$ORACLE_SID
THRESHSEC=1000
KILL='N'
REFRESH=N
ORIGINAL_COMMAND_LINE="$0 $*"
REFSEC=3

##################################################################################
while [ $# -ge 1 ]; do

  opt=$1
  shift

  case $opt in
      -d) DB=$1; shift ;;
      -k) KILL='Y' ;;
      -s) THRESHSEC=$1; shift ;;
     -eq) OPERATOR=$1; shift ;;
-refresh) REFRESH=Y; REFSEC=$1; shift ;;
       *) echo "I don't know what $opt is...\n" ; exit 2;;
  esac

done

if [ "$REFRESH" = "Y" ]; then

 while :
 do

   clear
   NEW_COMMAND_LINE=`echo "$ORIGINAL_COMMAND_LINE" | sed 's;-refresh [0-9]*;;'`
   $NEW_COMMAND_LINE
   sleep $REFSEC

 done

fi

