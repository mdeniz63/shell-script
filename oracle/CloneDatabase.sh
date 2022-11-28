# Clone Database
# From Non CDB Database ==> To Pluggable Database
# Author	:  Mahmut Deniz
. /home/oracle/.oracle_profile
cd /oracle/script/
tarih=`date +%Y_%m_%d`
echo STARTING...
sqlplus / as sysdba <<EOF
set echo on
set heading on
ALTER PLUGGABLE DATABASE TEST CLOSE IMMEDIATE;
DROP PLUGGABLE DATABASE TEST INCLUDING DATAFILES;
create pluggable database TEST from <PROD_SID>@<PRODUCTION_DB_LINK_NAME>;
alter pluggable database TEST open;
alter session set container = TEST;
-- If copy from noncdb database
@/oracle/product/19.3/dbhome_1/rdbms/admin/noncdb_to_pdb.sql
-- You can modify clone data at new pluggable database with custom after_clone.sql
@/oracle/script/after_clone.sql;
alter system disable restricted session;
show pdb
exit;
EOF
echo FINISHED.