###################################################
#		 RMAN BACKUP SCRIPT		  #
#                   Mahmut Deniz                  #
###################################################
#!/bin/sh
ScriptFileName=`basename ${0}`
# First Load Linux Oracle Profile for Enviroment Variables
. /home/oracle/.oracle_profile
tarih=`date +%Y_%m_%d`
tarihsaat=`date +%Y_%m_%d_%H%M`
command_id=$tarihsaat
# Change 5 variables for using
FROM=test@domain.com.tr
TO=dba@domain.com.tr
dizin="/backup/RMAN"
logdizin="/backup/RMAN/logs"
logfile="$logdizin/rman_$Type_$tarihsaat.log"
# Script
mkdir -p $logdizin

Help()
{
   echo "----------------------------------------"
   echo "         RMAN BACKUP SCRIPT"
   echo "----------------------------------------"
   echo
   echo " Syntax : ./$ScriptFileName Type [Day]" 
   echo
   echo " Type :"
   echo
   echo "  full     		Full Backup"
   echo "  incr     		Incremental Differential Backup"
   echo "  arch     		Archivelog Backup"
   echo "  del [day count]    	Archivelog Delete Until Sysdate - Days"
   echo
   echo "----------------------------------------"
   echo
}

if [ -z "$1" ]; then  # do something if argument is empty
  Help
  exit 1 
else
  Type=$1
fi

if [ -z "$2" ]; then
  Day=0
else
  Day=$2
fi

FullBackup(){
FullFormat=$dizin/%d_%T_%s
rman log=$logfile << EOF
connect target /
set echo on;
run
{
sql 'alter system archive log current';
SET COMMAND ID TO '$command_id';
CONFIGURE DEVICE TYPE DISK PARALLELISM 24;
CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '/backup/RMAN/FULL_%d_%T_%s';
SET CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '$dizin/cf_%F';
BACKUP AS COMPRESSED BACKUPSET INCREMENTAL LEVEL 0 DATABASE PLUS ARCHIVELOG FORMAT '$FullFormat' DELETE INPUT;
CROSSCHECK BACKUP;
CROSSCHECK ARCHIVELOG ALL;
CROSSCHECK BACKUPSET;
DELETE NOPROMPT OBSOLETE;
DELETE NOPROMPT EXPIRED BACKUP;
DELETE NOPROMPT EXPIRED ARCHIVELOG ALL;
DELETE NOPROMPT EXPIRED BACKUPSET;
}
EOF
}

IncrementalBackup(){
IncrementalFormat=$dizin/INCR_%d_%T_%s
rman log=$logfile << EOF
connect target /
set echo on;
run
{
sql 'alter system archive log current';
SET COMMAND ID TO '$command_id';
CONFIGURE DEVICE TYPE DISK PARALLELISM 16;
CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '/backup/RMAN/INCR_%d_%T_%s';
SET CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '$dizin/cf_%F';
BACKUP AS COMPRESSED BACKUPSET INCREMENTAL LEVEL 1 DATABASE PLUS ARCHIVELOG FORMAT '$IncrementalFormat';
CROSSCHECK BACKUP;
CROSSCHECK ARCHIVELOG ALL;
CROSSCHECK BACKUPSET;
DELETE NOPROMPT OBSOLETE;
DELETE NOPROMPT EXPIRED BACKUP;
DELETE NOPROMPT EXPIRED BACKUPSET;
}
EOF
}

ArchiveLogBackup(){
ArchiveFormat=$dizin/ARCH_%d_%T_%s
rman log=$logfile << EOF
connect target /
set echo on;
run
{
sql 'alter system archive log current';
SET COMMAND ID TO '$command_id';
CONFIGURE DEVICE TYPE DISK PARALLELISM 1;
CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '/backup/RMAN/ARCH_%d_%T_%s';
SET CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '$dizin/cf_%F'; 
BACKUP AS COMPRESSED BACKUPSET ARCHIVELOG ALL FORMAT '$ArchiveFormat';
}
EOF
}

ArchiveLogDelete(){
rman << EOF
connect target /
set echo on;
run
{
sql 'alter system archive log current';
delete noprompt archivelog until time 'sysdate-$Day';
}
EOF
}

RunSQL(){
sqlplus -s / as sysdba <<EOF
SET LINES 32000 PAGESIZE 0
SET TERMOUT OFF ECHO OFF NEWP 0 SPA 0 PAGES 0 FEED OFF HEAD OFF TRIMS ON TAB OFF
$1
exit
EOF
}

#SQL "begin send_rman_backup_status(''$command_id'',FALSE);end;";
SendRmanBackupStatusAsMail(){
BackupStatusQuery="SELECT STATUS FROM v\$rman_backup_job_details where COMMAND_ID='$command_id';"
BackupTypeQuery="SELECT INPUT_TYPE FROM v\$rman_backup_job_details where COMMAND_ID='$command_id';"
BackupTimeQuery="SELECT TIME_TAKEN_DISPLAY FROM v\$rman_backup_job_details where COMMAND_ID='$command_id';"
BackupSizeQuery="SELECT OUTPUT_BYTES_DISPLAY FROM v\$rman_backup_job_details where COMMAND_ID='$command_id';"
BackupStatus=$(RunSQL "$BackupStatusQuery")
BackupType=$(RunSQL "$BackupTypeQuery")
BackupTime=$(RunSQL "$BackupTimeQuery")
BackupSize=$(RunSQL "$BackupSizeQuery")
MailText="Elapsed Time :\t $BackupTime  \nBackup Size :\t $BackupSize \n\n$BackupType RMAN BACKUP $BackupStatus"

# Send mail with mailx command if completed only status if not completed successfully send status and log file.
if [ "$BackupStatus" = "COMPLETED" ]; then
    echo -e $MailText | mailx -r $FROM -s "$BackupStatus"  $TO
else
    echo -e $MailText | mailx -a $logfile -r $FROM -s "$BackupStatus"  $TO
fi

}
# Option Backup Type
case "$Type" in
    "full")
	echo "starting full backup  "
	FullBackup
	SendRmanBackupStatusAsMail
	exit 0
   ;;
    "incr")
	echo "starting incremental backup  "
	IncrementalBackup
	SendRmanBackupStatusAsMail
	exit 0
   ;;
    "arch") 
	echo "starting archivelog backup  "
	ArchiveLogBackup
	exit 0
   ;;
    "del") 
	echo "deleting archivelogs until time sysdate - "$Day"  "
	ArchiveLogDelete
	exit 0
   ;;
   *)
	Help
    	exit 1 # Command to come out of the program with status 1
   ;;
esac
