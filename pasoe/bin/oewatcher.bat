@echo off
rem Progress OpenEdge Watcher

rem Insert a point where installers can set a fixed CATALINA_HOME location
set CATALINA_HOME=C:\DLC\128\servers\pasoe

rem Allow tailoring of CATALINA_BASE
set CATALINA_BASE=C:\Projets\KEYCLO~1\pasoe

:TESTHOME
if exist "%CATALINA_HOME%" goto TESTBASE
echo CATALINA_HOME refers to an invalid directory path
exit /b 1

:TESTBASE
if exist "%CATALINA_BASE%" goto TESTPS
echo CATALINA_BASE refers to an invalid directory path
exit /b 1

:TESTPS
for %%X in (Powershell.exe) do (set pwrshell=%%~$PATH:X)
if defined pwrshell goto MKPATH
echo Powershell.exe cannot be found in the process PATH 
exit /b 1

:MKPATH
if exist "%CATALINA_HOME%\bin\%~n0.ps1" goto GETPID
echo Cannot find "%CATALINA_HOME%\bin\%~n0.ps1" needed to run this program
exit /b 1

rem get PASOE Process Id
:GETPID
if exist "%CATALINA_BASE%\bin\tcman.bat" goto GETPID1
echo Cannot find "%CATALINA_BASE%\bin\tcman.bat" needed to get PASOE PID
exit /b 1
:GETPID1
set PASOEPID=
for /F %%I in ('%CATALINA_BASE%\bin\tcman.bat env pid') do set PASOEPID=%%I
if not %PASOEPID%=="" goto JAVACFG
echo tcman.bat did not return PASOE pid value
exit /b 1


:JAVACFG
rem Define a place where the JAVA_HOME and/or JRE_HOME process environment
rem variables can be customized before executing JAVA related operations.
rem This script will call out to the javacfg.bat script in the CATALINA_HOME
rem directory to do the work
if exist "%CATALINA_HOME%\bin\javacfg.bat" (
    call "%CATALINA_HOME%\bin\javacfg.bat"
)

:LIB
if "%OEJARSPATH%"==""       set OEJARSPATH=%CATALINA_HOME%\common\lib
if exist "%OEJARSPATH%" goto BIN
echo The required library path does not exist: %OEJARSPATH%
goto END

:BIN
if "%OEBINPATH%"==""        set OEBINPATH=%CATALINA_HOME%\bin
if exist "%OEBINPATH%" goto FINDOEJMXJAR
echo The required library path does not exist: %OEBINPATH%
goto END

:FINDOEJMXJAR
rem locate the latest version of the oejmx jar
for /f "tokens=*" %%k in ('dir /b /on "%OEBINPATH%"\oejmx-*.jar') do set _oejmxjar=%%k 
if not "%_oejmxjar%"=="" goto SETCP
echo The required library could not be found:   oejmx-*.jar
goto END

:SETCP
set OECP="%OEBINPATH%\%_oejmxjar%";"%OEJARSPATH%\*"

rem logging configuration file path
set LOGBACK=%CATALINA_BASE%\conf\watcher-logging.xml
if exist "%LOGBACK%" goto START
echo WARNING. Logging file %LOGBACK% doesn't exist

:START
PowerShell.exe -NoProfile -ExecutionPolicy Bypass  "%CATALINA_HOME%\bin\%~n0.ps1"  %PASOEPID% %* 

:END
set OEJARSPATH=
set OEBINPATH=
