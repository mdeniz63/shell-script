echo ---    Windows 11 x64 Oracle Latest Version Instant Client Installation   ---
REM Author : Mahmut Deniz
REM Save as OracleInstantClientInstall.bat
echo off
set OracleClientDir=C:\OracleClient\instantclient_19_16
set TNSDir="%OracleClientDir%\network\admin"
mkdir %OracleClientDir%
mkdir %TNSDir% 
cd %OracleClientDir%
REM Set Links to Variables
set BasicPackage="https://download.oracle.com/otn_software/nt/instantclient/instantclient-basic-windows.zip"
set SQLPlusPackage="https://download.oracle.com/otn_software/nt/instantclient/instantclient-sqlplus-windows.zip"
set ToolsPackage="https://download.oracle.com/otn_software/nt/instantclient/instantclient-tools-windows.zip"
set SDKPackage="https://download.oracle.com/otn_software/nt/instantclient/instantclient-sdk-windows.zip"
set JDBCSupplementPackage="https://download.oracle.com/otn_software/nt/instantclient/instantclient-jdbc-windows.zip"
set ODBCPackage="https://download.oracle.com/otn_software/nt/instantclient/instantclient-odbc-windows.zip"
cls
echo Downloading...
curl %BasicPackage% -s -o BasicPackage.zip
curl %ToolsPackage% -s -o ToolsPackage.zip
curl %SQLPlusPackage% -s -o SQLPlusPackage.zip
curl %SDKPackage% -s -o SDKPackage.zip
curl %JDBCSupplementPackage% -s -o JDBCSupplementPackage.zip
curl %ODBCPackage% -s -o ODBCPackage.zip
echo Extracting...
tar -xvzf BasicPackage.zip -C C:\OracleClient\
tar -xvzf ToolsPackage.zip -C C:\OracleClient\
tar -xvzf SQLPlusPackage.zip -C C:\OracleClient\
tar -xvzf SDKPackage.zip -C C:\OracleClient\
tar -xvzf JDBCSupplementPackage.zip -C C:\OracleClient\
tar -xvzf ODBCPackage.zip -C C:\OracleClient\
echo Enviroment Variables...
setx /m NLS_LANG "TURKISH_TURKEY.TR8MSWIN1254"
setx /m TNS_ADMIN "%TNSDir%"
setx /m PATH "%PATH%;%OracleClientDir%"
echo "Installatiopn Completed"
del BasicPackage.zip
del ToolsPackage.zip
del SQLPlusPackage.zip
del SDKPackage.zip
del JDBCSupplementPackage.zip
del ODBCPackage.zip
echo Dont forget to copy tnsnames.ora file to %TNSDir% !!!
pause
