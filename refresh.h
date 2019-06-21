REFRESH=N
ORIGINAL_COMMAND_LINE="$0 $*"

##################################################################################
while [ $# -ge 1 ]; do

  opt=$1
  shift

  case $opt in
-refresh) REFRESH=Y; REFSEC=$1; shift ;;
       *) echo "I don't know what $opt is...\n" ;;
  esac

done

#       *) echo "I don't know what $opt is...\n" ; exit 2;;

if [ "$REFRESH" = "Y" ]; then

 while :
 do

   clear
   NEW_COMMAND_LINE=`echo "$ORIGINAL_COMMAND_LINE" | sed 's;-refresh [0-9]*;;'`
   $NEW_COMMAND_LINE
   sleep $REFSEC

 done

fi


##################################################################################
echo "stuff"

exit 0

