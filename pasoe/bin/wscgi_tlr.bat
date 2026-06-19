@echo off
rem Verify %DLC% and %WRKDIR% are set, if not exit 
if exist "%DLC%"\servers goto wrkdir
echo ***** DLC is not set or incorrect
exit /b 1

:wrkdir
if exist "%WRKDIR%" goto cathome 
echo ***** WRKDIR is not set or incorrect
exit /b 1

rem Set CATALINA_HOME
:cathome
set CATALINA_HOME=C:\DLC\128\servers\pasoe
goto catbase

:catbase
rem Allow an tcman create command tailor CATALINA_BASE
set CATALINA_BASE=C:\Projets\KEYCLO~1\pasoe

rem Verify CATALINA_BASE is set
if DEFINED CATALINA_BASE goto cattemp
echo ***** CATALINA_BASE is not set or incorrect
exit /b 1 

:cattemp
rem Allow tailoring of where temp files are accessed, but 
rem allow the individual's environment to supercede tailoring
if "%CATALINA_TMPDIR%" == "" goto gottmp
set CATALINA_TMPDIR=

:gottmp
if defined CATALINA_HOME goto testexist
echo CATALINA_HOME is not defined or points to an invalid server installation
exit /b 1

:testexist
if exist "%CATALINA_HOME%" goto testps
echo CATALINA_HOME refers to an invalid directory path
exit /b 1

if exist "%CATALINA_BASE%" goto testps
echo CATALINA_BASE refers to an invalid directory path
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
set "PRGDIR=%CATALINA_HOME%\bin\wscgi_tailor.ps1"
set "EXECUTABLE=PowerShell.exe -executionpolicy bypass -File %PRGDIR%"

if exist "%PRGDIR%" goto doexec
echo Cannot find %PRGDIR% that is needed to run this program
exit /b 1

:doexec
%EXECUTABLE% %*
:end

