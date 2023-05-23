###################################################
###		 RMAN BACKUP SCRIPT		###
###################################################
#!/bin/sh
ScriptFileName=`basename ${0}`
# First Load Linux Oracle Profile for Enviroment Variables
. /home/oracle/.oracle_profile
tarih=`date +%Y_%m_%d`
tarihsaat=`date +%Y_%m_%d_%H%M`

# Change variables below for using
FROM=test@domain.com
TO=dba@domain.com
command_id=$tarihsaat
dizin="/backup/RMAN/"
BackupFolder="$dizin/$tarih"
ControlFilesFolder="$dizin/ControlFiles"
LogFolder="$dizin/logs"
logfile="$LogFolder/rman_$1_$tarihsaat.log"
FormatFull="$BackupFolder/FULL_%d_%T_%s"
FormatIncr="$BackupFolder/incr_%d_%T_%s"
FormatArch="$BackupFolder/arch_%d_%T_%s"


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
   echo "  cros     		Crosscheck And Delete Expired"
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

# Script
mkdir -p {"$BackupFolder","$LogFolder","$ControlFilesFolder"}

FullBackup(){
rman log=$logfile << EOF
connect target /
set echo on;
run
{
sql 'alter system archive log current';
SET COMMAND ID TO '$command_id';
CONFIGURE DEVICE TYPE DISK PARALLELISM 32;
CONFIGURE CHANNEL DEVICE TYPE DISK MAXPIECESIZE 32G;
CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '$FormatFull';
SET CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '$ControlFilesFolder/cf_%F';
BACKUP AS COMPRESSED BACKUPSET INCREMENTAL LEVEL 0 DATABASE PLUS ARCHIVELOG FORMAT '$FormatFull' DELETE INPUT;
}
EOF
}

IncrementalBackup(){
rman log=$logfile << EOF
connect target /
set echo on;
run
{
sql 'alter system archive log current';
SET COMMAND ID TO '$command_id';
CONFIGURE DEVICE TYPE DISK PARALLELISM 16;
CONFIGURE CHANNEL DEVICE TYPE DISK MAXPIECESIZE 32G;
CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '$FormatIncr';
SET CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '$ControlFilesFolder/cf_%F'; 
BACKUP AS COMPRESSED BACKUPSET INCREMENTAL LEVEL 1 DATABASE PLUS ARCHIVELOG FORMAT '$FormatIncr' DELETE INPUT;
}
EOF
}

ArchiveLogBackup(){
rman log=$logfile << EOF
connect target /
set echo on;
run
{
sql 'alter system archive log current';
SET COMMAND ID TO '$command_id';
CONFIGURE DEVICE TYPE DISK PARALLELISM 2;
CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '$FormatArch';
SET CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '$ControlFilesFolder/cf_%F'; 
BACKUP AS COMPRESSED BACKUPSET ARCHIVELOG ALL FORMAT '$FormatArch';
}
EOF
}

ArchiveLogDelete(){
rman << EOF
connect target /
set echo off;
run
{
sql 'alter system archive log current';
delete noprompt archivelog until time 'sysdate -$Day';
}
EOF
}

CrosschekAndDeleteExpired(){
rman << EOF
connect target /
set echo on;
run
{
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
	CrosschekAndDeleteExpired
	SendRmanBackupStatusAsMail
	exit 0
   ;;
    "incr")
	echo "starting incremental backup  "
	IncrementalBackup
	CrosschekAndDeleteExpired
	SendRmanBackupStatusAsMail
	exit 0
   ;;
    "arch") 
	echo "starting archivelog backup  "
	ArchiveLogBackup
	CrosschekAndDeleteExpired
	exit 0
   ;;
    "del") 
	echo "deleting archivelogs until time sysdate - "$Day"  "
	exit 0
   ;;
    "cross") 
	CrosschekAndDeleteExpired
	exit 0
   ;;
   *)
	Help
    	exit 1 # Command to come out of the program with status 1
   ;;
esac
