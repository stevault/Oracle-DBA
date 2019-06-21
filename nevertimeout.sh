

dont_time_out () {

echo dont time out

counter=0

while [ $counter -lt 100 ]
do
   echo "."
   sleep 600
   
   let counter=counter+1

done
}

dont_time_out &
