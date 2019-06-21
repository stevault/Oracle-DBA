if [ $# -lt 1 ]; then
  echo -e "(directory unspecified, using current...)"
  DIR=`pwd`
else
  DIR=$1
fi
 
if [ ! -d $DIR ]; then
   echo -e "ERROR:   $DIR is not a directory."
   exit 1
fi
 
if [ `echo -e $DIR | cut -c1` != "/" ]; then
   DIR=`pwd`/$DIR
fi
 
echo -e "\nGetting space usage for directory $DIR...\n"
 
echo -e "PCT subdirectory SIZE" | awk '{printf("%5s %-50s %8s MB\n",$1,$2,$3)}'
echo -e "===================================================================="
 
cd $DIR
 
du -x --summarize 2>/dev/null | read TOT dir

if [ $TOT -lt 100 ]; then
 du --summarize 2>/dev/null | read TOT dir
fi
let TOT=$TOT/2/1024
 
for i in `ls`
do
  du -x --summarize $i 2>/dev/null
done | sort -n | grep -v '^0' | while read spc dir
do
   let spc=$spc/2/1024
   let pct=100*$spc/$TOT
   if [ $spc -gt 0 ]; then
      echo -e "${pct}% $DIR/$dir $spc" | awk '{printf("%5s %-50s %8s MB\n",$1,$2,$3)}'
   fi
done
 
echo -e "===================================================================="
echo -e "TOTAL $DIR:  $TOT" | awk '{printf("%5s %-50s %8s MB\n",$1,$2,$3)}'
 
df $DIR | tail -1 | grep -q '^ '
[ $? = 0 ] && TAIL=2 || TAIL=1
 
n=0
for X in `df $DIR | tail -$TAIL`
do
    let n=n+1
    case $n in
        2) let SZ=$X/1024 ;;
        5) PU=$X ;;
        6) FS=$X ;;
    esac
 
done
 
echo -e "\nFilesystem $FS is $SZ MB, and $PU used"
echo -e $PU | sed 's;%;;g' | read FSPctUsed
 
i=0
 
if [ $FSPctUsed -lt 0 ]; then
   echo ugh
else
 
echo -e "[\c"

while [ $i -lt 100 ]; do
   let i=i+1
   [ $i -le $FSPctUsed ] && echo -e "X\c" || echo -e ".\c"
done
 
echo -e "]\n"

fi
