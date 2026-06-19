@echo off
rem Startup the CATALINA_HOME/bin/tcmanager.bat script after setting the correct
rem CATALINA_BASE and CATALINA_HOME

rem Insert a point where installers can set a fixed CATALINA_HOME location
set CATALINA_HOME=C:\DLC\128\servers\pasoe

rem Allow an tcman create command tailor CATALINA_BASE
set CATALINA_BASE=C:\Projets\KEYCLO~1\pasoe

rem Allow tailoring of where temp files are accessed, but 
rem allow the individual's environment to supercede tailoring
if "%CATALINA_TMPDIR%" == "" goto gottmp
set CATALINA_TMPDIR=C:\Projets\KEYCLO~1\pasoe\temp

:gottmp

if defined CATALINA_HOME goto testexist
echo CATALINA_HOME is not defined or points to an invalid server installation
exit /b 1

:testexist
if exist "%CATALINA_HOME%" goto testps
echo CATALINA_HOME refers to an invalid directory path
exit /b 1

:testps
rem The Powershell.exe program must be accessible for any tailoring
rem to run, so test it now and exit with an error if it cannot
rem be found.
for %%X in (Powershell.exe) do (set pwrshell=%%~$PATH:X)
if defined pwrshell goto mkpath
echo Powershell.exe cannot be found in the process PATH 
exit /b 1

:mkpath
set PRGDIR=%CATALINA_HOME%\bin\tcmanager.ps1
set EXECUTABLE=PowerShell.exe -nologo -noprofile -executionpolicy bypass -File "%PRGDIR%"

if exist "%PRGDIR%" goto javacfg
echo Cannot find %PRGDIR% that is needed to run this program
exit /b 1

:javacfg
rem Define a place where the JAVA_HOME and/or JRE_HOME process environment
rem variables can be customized before executing JAVA related operations.
rem This script will call out to the javacfg.bat script in the CATALINA_HOME
rem directory to do the work so that it is in sync with the tcmanager utility 
rem version.
if exist "%CATALINA_HOME%\bin\javacfg.bat" (
    call "%CATALINA_HOME%\bin\javacfg.bat"
)

rem check if JAVA_HOME is valid
if exist "%JAVA_HOME%\bin\java.exe" goto doexec
   echo Java could not be found.
   echo.
   echo JAVA_HOME environment variable may not be set correctly.
   echo Java not found: "%JAVA_HOME%\bin\java.exe"
   echo.
   goto end

:doexec
set PS_START=%TIME%
rem gather all arguments into a single variable, prefixed with a static
rem value 'tcman' (which is required) so that none of the remaining
rem variable substitutions fail due to an empty variable in an 'if' test
rem note: DOS auto removes quotes if the value does not have a space in it
set args=tcman %*

rem powershell escape double-quotes to get past DOS argument passing
rem does not work.  To pass double quotes use triple quotes
rem     DOS         property="this is """a""" test"
rem     Powershell  property=this is "a" test
rem

rem powershell does not accept DOS escape characters, so substitute 
rem with powershell escape characters
set args=%args:^=`%

rem If we end up with double powershell escapes, reduce back to one
set args=%args:``=`%

rem echo args: %args%
%EXECUTABLE% %args%
:end
set PS_START=
set PRGDIR=
set EXECUTABLE=

exit /b %errorlevel%

