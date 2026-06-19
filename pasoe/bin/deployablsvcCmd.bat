@echo off 

set basedir=%~dp0

rem Check for the tailored CATALINA_HOME environment variable
rem CATALINA_HOME environment variable is tailored during the PAS install process
rem CATALINA_BASE is tailored during PAS instance creation process   
:checkCatalina
set CATALINA_HOME=C:\DLC\128\servers\pasoe
set CATALINA_BASE=C:\Projets\KEYCLO~1\pasoe

if not defined CATALINA_HOME (
    echo CATALINA_HOME environment variable is not set
    goto ERR
)
if not defined CATALINA_BASE (
    echo CATALINA_BASE environment variable is not set
    goto ERR
)
:checkJava
REM set JAVA_HOME by calling java_env
call "%CATALINA_HOME%\bin\javacfg.bat"
if exist "%JAVA_HOME%\bin\java.exe" goto EXEC
   echo Java could not be found.
   echo.
   echo JAVA_HOME environment variable may not be set correctly.
   echo Java not found: "%JAVA_HOME%\bin\java.exe"
   echo.
   goto ERR

echo Cannot find a Tomcat installation in directory: "%CATALINA_BASE%"
goto ERR
:EXEC
set EXECUTABLE=PowerShell.exe -executionpolicy bypass -File "%basedir%/deployablsvcCmd.ps1" %*

%EXECUTABLE%
goto END

:ERR
  set _exitstatus=1
:END
exit /b %_exitstatus%

