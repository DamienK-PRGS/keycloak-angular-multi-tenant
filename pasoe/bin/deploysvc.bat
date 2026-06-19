@echo off
rem
rem Shell wrapper to execute the PAS deploysvc utility from the PAS server
rem installation's bin directory
rem

set _exitstatus=1
rem Install tailoring will fill in this location of CATALINA_HOME
set CATALINA_HOME=C:\DLC\128\servers\pasoe

rem If install tailoring did not run, then stop here
if exist "%CATALINA_HOME%" goto chkbase
echo CATALINA_HOME is not defined or points to an invalid server installation
goto end

:chkbase
rem tcman tailoring will fill in this location of CATALINA_BASE
set CATALINA_BASE=C:\Projets\KEYCLO~1\pasoe

rem If install tailoring did not run, then stop here
if exist "%CATALINA_BASE%" goto chksetenv
rem Assume we are running out of $CATALINA_HOME
set CATALINA_BASE=C:\Projets\KEYCLO~1\pasoe

:chksetenv
rem Get standard environment variables
if not exist "%CATALINA_BASE%\bin\setenv.bat" goto checkSetenvHome
call "%CATALINA_BASE%\bin\setenv.bat"
goto initJava
:checkSetenvHome
if exist "%CATALINA_HOME%\bin\setenv.bat" call "%CATALINA_HOME%\bin\setenv.bat"

:initJava
rem Define a place where the JAVA_HOME and/or JRE_HOME process environment
rem variables can be customized before executing JAVA related operations.
rem This script will call out to the javacfg.sh script in the CATALINA_HOME
rem directory to do the work so that it is in sync with the expand utility version.
if exist "%CATALINA_HOME%\bin\javacfg.bat" ( 
    call "%CATALINA_HOME%\bin\javacfg.bat"
)

:chkjava
rem A version of JAVA is required
if not exist "%JAVA_HOME%" goto chkjre
set JAVART=%JAVA_HOME%
goto chkdeploysvc

:chkjre
if not exit  "%JRE_HOME%" goto nojava
set JAVART=%JRE_HOME%
goto chkdeploysvc

:nojava
echo "JAVA_HOME or JAVA_JRE is not defined"
goto end

:chkdeploysvc
rem Where Main is located
if exist "%DEPLOYSVC_JAR%" goto setArgs
rem Fill in a default if the location was not already set
rem in the environment
for /f "tokens=*" %%j in ('dir /b /on "%CATALINA_HOME%"\bin\deploysvc*.jar') do set DEPLOYSVC_JAR="%CATALINA_HOME%\bin\%%j"

:doexec
rem Execute it now

set _oeopts= -Dcatalina.base="%CATALINA_BASE%"
set JAVA_OPTS=%_oeopts% %JAVA_OPTS% 

"%JAVART%\bin\java.exe" %JAVA_OPTS% -jar "%DEPLOYSVC_JAR%" %*
set _exitstatus=%ERRORLEVEL%

:end
set DEPLOYSVC_JAR=
set JAVART=
set CMD_LINE_ARGS=
set JAVA_OPTS=
exit /b %_exitstatus%

