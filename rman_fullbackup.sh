
BACKUPROOT=/u01/app/oracle/fast_recovery_area/datastore/backup
#/cloudsfs1/backup

rman << EOF

connect target /

show all;

run {
    allocate channel c1 type disk;
    allocate channel c2 type disk;

    DELETE NOPROMPT OBSOLETE;

    backup as COMPRESSED BACKUPSET 
	incremental level 0
	format '$BACKUPROOT/%d_%T_L0_D_%u_s%s_p%p'
	database;

    backup as COMPRESSED BACKUPSET
	archivelog all
	format '$BACKUPROOT/%d_%T_L0_A_%u_s%s_p%p'
	delete all input;

    DELETE NOPROMPT OBSOLETE;

    DELETE NOPROMPT EXPIRED BACKUP;

      }


EOF

