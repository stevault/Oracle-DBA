
TEMPFILE=show_all_users.tmp
OUTFILE=show_all_users.log 

> $OUTFILE

DATABASE_LIST="ca_dev ca_prd ca_prddr ca_qa ca_st ca_uat calldev CALLDEV_DR dw_dev dw_prd dw_qa dw_st dw_uat dw_udev IV_DEV IV_PRD IV_PRDDR iv_qa IV_ST iv_uat IV_UDEV IV_UUAT OS_DEV os_prd OS_PRDDR os_qa os_st os_uat OS_UDEV"

for DB in $DATABASE_LIST
do

   show_users $DB 1>$TEMPFILE 2>&1
   if [ $? -eq 0 ]; then 
      cat $TEMPFILE >> $OUTFILE
   fi

done

   
