@echo off 
rem Starts oejmx.ps1, a monitoring tool, which uses jmx services to access Tomcat beans:
rem  - generates a list of bean operations and attributes exposed to jmx
rem  - invokes bean operations and reads bean attributes.
rem Accepts four optional attributes
rem -C - signals to generate a list of bean operations/attributes 
rem -Q <query parameter> -
rem    query parameter could be either a path to a file with a set of JMX queries or a single JMX query 
rem    Find example JMX queries file default.qry in <CATALINA_BASE>\bin\jmxqueries directory
rem    A single JMX query is a JSON string like in default.qry with escaped quote characters. For example:
rem         {\"O\":\"PASOE:type=OEManager,name=AgentManager\",\"M\":[\"getAgents\",\"oepas1\"]}
rem    This parameter is ignored if -C attribute present.  
rem -O <file name> - output file name (with path). <file name> is ouptional
rem    If no file name provided then the output directed to the console
rem    The file name may include timestamp template: {TIMESTAMP} or {TIMESTAMP:<java type datetime format>}
rem    Default values:
rem      If -C argument presents: <PASOE Temp Dir>\beanInfo{TIMESTAMP:yyMMdd-HHmm}.txt
rem      If no -C argument:  <PASOE Temp Dir>\queries-out-{TIMESTAMP:yyMMdd-HHmmss}.txt
rem    This parameter is ignored if a single JMX query used
rem -R - signals write into output file results only. Otherwise output file also includes query texts. 
rem    Ignored if -C argument is present or a single JMX query used

rem Insert a point where installers can set a fixed CATALINA_HOME location
set CATALINA_HOME=C:\DLC\128\servers\pasoe

rem Allow tailoring of CATALINA_BASE
set CATALINA_BASE=C:\Projets\KEYCLO~1\pasoe

:TESTHOME
if exist "%CATALINA_HOME%" goto TESTBASE
echo CATALINA_HOME refers to an invalid directory path
exit /b 1

:TESTBASE
if exist "%CATALINA_BASE%" goto JAVACFG
echo CATALINA_BASE refers to an invalid directory path
exit /b 1


:JAVACFG
rem Define a place where the JAVA_HOME and/or JRE_HOME process environment
rem variables can be customized before executing JAVA related operations.
rem This script will call out to the javacfg.bat script in the CATALINA_HOME
rem directory to do the work
if exist "%CATALINA_HOME%\bin\javacfg.bat" (
    call "%CATALINA_HOME%\bin\javacfg.bat"
)

set basedir=%~dp0
set EXECUTABLE=PowerShell.exe -executionpolicy bypass -File "%basedir%/oejmx.ps1" %*

%EXECUTABLE%
