echo ---    Windows 11 x64 Oracle 19.16 Instant Client Installation   ---
REM Author : Mahmut Deniz
REM Oracle Clients Links Adress :  https://www.oracle.com/co/database/technologies/instant-client/winx64-64-downloads.html
REM Save as OracleInstantClientInstall.bat
echo off
set OracleClientDir=C:\OracleClient\instantclient_19_16
set TNSDir="%OracleClientDir%\network\admin"
mkdir %OracleClientDir%
mkdir %TNSDir% 
cd %OracleClientDir%
REM Set Links to Variables
set BasicLightPackage="https://download.oracle.com/otn_software/nt/instantclient/1916000/instantclient-basiclite-windows.x64-19.16.0.0.0dbru.zip"
set SQLPlusPackage="https://download.oracle.com/otn_software/nt/instantclient/1916000/instantclient-sqlplus-windows.x64-19.16.0.0.0dbru.zip"
set ToolsPackage="https://download.oracle.com/otn_software/nt/instantclient/1916000/instantclient-tools-windows.x64-19.16.0.0.0dbru.zip"
set SDKPackage="https://download.oracle.com/otn_software/nt/instantclient/1916000/instantclient-sdk-windows.x64-19.16.0.0.0dbru.zip"
set JDBCSupplementPackage="https://download.oracle.com/otn_software/nt/instantclient/1916000/instantclient-jdbc-windows.x64-19.16.0.0.0dbru.zip"
cls
echo Downloading...
curl %BasicLightPackage% -s -o BasicLightPackage.zip
curl %ToolsPackage% -s -o ToolsPackage.zip
curl %SQLPlusPackage% -s -o SQLPlusPackage.zip
curl %SDKPackage% -s -o SDKPackage.zip
curl %JDBCSupplementPackage% -s -o JDBCSupplementPackage.zip
echo Extracting...
tar -xvzf BasicLightPackage.zip -C C:\OracleClient\
tar -xvzf ToolsPackage.zip -C C:\OracleClient\
tar -xvzf SQLPlusPackage.zip -C C:\OracleClient\
tar -xvzf SDKPackage.zip -C C:\OracleClient\
tar -xvzf JDBCSupplementPackage.zip -C C:\OracleClient\
echo Enviroment Variables...
setx /m NLS_LANG "TURKISH_TURKEY.TR8MSWIN1254"
setx /m TNS_ADMIN "%TNSDir%"
setx /m PATH "%PATH%;%OracleClientDir%"
echo "Installatiopn Completed"
del BasicLightPackage.zip
del ToolsPackage.zip
del SQLPlusPackage.zip
del SDKPackage.zip
del JDBCSupplementPackage.zip
echo Dont forget to copy tnsnames.ora file to %TNSDir% !!!
pause
