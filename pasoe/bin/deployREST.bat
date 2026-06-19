@echo off
SETLOCAL
rem
rem Script to deploy a REST descriptor to a given OEABL Application
rem
rem

set _exitstatus=1

if ""%2"" == """" goto doUsage

rem Read the cmdLine Arguments
:doSetArgs
set DESCLOC=%~1
set APPNAME=%~2
set OPT_UNDEP=%~3

rem Determine the correct directory where OpenEdge is installed
:checkDLC
if not defined DLC (
set DLC=C:\DLC\128
)
if exist "%DLC%\version" goto checkCATALINA
   echo.
   echo DLC environment variable not set correctly - Please set DLC variable
   echo.
   goto ERR

:checkCATALINA
rem Check for the tailored CATALINA_HOME environment variable
rem CATALINA_HOME environment variable is tailored during the PAS install process
rem CATALINA_BASE is tailored during PAS instance creation process    
set CATALINA_HOME=C:\DLC\128\servers\pasoe
set CATALINA_BASE=C:\Projets\KEYCLO~1\pasoe

if not defined CATALINA_HOME (
    echo Tomcat installation directory ^(CATALINA_HOME^) is defined as ""
    goto ERR
)
if not defined CATALINA_BASE (
set CATALINA_BASE=C:\Projets\KEYCLO~1\pasoe
    set _removeCatBase=y
)

if exist "%CATALINA_BASE%" ( 
    set CATALINA_WEBAPPS=%CATALINA_BASE%\webapps
    goto checkJAVA
)
echo Cannot find a Tomcat installation in directory: "%CATALINA_HOME%"
goto ERR

rem Check if Java enviornment is available
:checkJAVA
REM set JAVA_HOME by calling java_env
call "%CATALINA_HOME%\bin\javacfg.bat"

if exist "%JAVA_HOME%\bin\java.exe" goto doExtractFileName
   echo Java could not be found.
   echo.
   echo JAVA_HOME environment variable may not be set correctly.
   echo Java not found: "%JAVA_HOME%\bin\java.exe"
   echo.
   goto ERR

:doExtractFileName
rem Determine if the Service Directory exists or else create
echo Using DLC:                 "%DLC%"
echo Using CATALINA_HOME:       "%CATALINA_HOME%"
echo Using CATALINA_WEBAPPS:    "%CATALINA_WEBAPPS%"
echo Using JDK_HOME:            "%JAVA_HOME%"
echo Using JRE_HOME:            "%JRE_HOME%"

set DEPLOYMGRCLASS="com.progress.appserv.manager.util.deployREST"
set CLASSPATH=%CATALINA_HOME%\common\lib\*
set APPDIR=%CATALINA_WEBAPPS%\%APPNAME%

rem Begin Splitting FilePath to Extract name and extenstion
    setlocal ENABLEDELAYEDEXPANSION
    set FILE_PATH=%DESCLOC%
	
:loopForDelimiter
    if "!FILE_PATH!" EQU "" goto getFileName

    REM Tokenize Full Path based on \ "Seperator". Set the first Token to FNAME_WEXT
    for /f "delims=\" %%a in ("!FILE_PATH!") do set substring=%%a
        set FNAME_WEXT=!substring!

:loopEachSubstring
    REM Get Lead Character from the Input Full Path
    set LEAD_CHAR=!FILE_PATH:~0,1!
    REM Remove Lead Character from the Input Full Path
    set FILE_PATH=!FILE_PATH:~1!
    REM If remaining string is empty we reached END of Input Full Path. Go Back.
    if "!FILE_PATH!" EQU "" goto loopForDelimiter
    REM If Lead Character is \ give back the remaining string to First Loop for Tokenization.
    if "!LEAD_CHAR!" NEQ "\" goto loopEachSubstring
    goto loopForDelimiter

:getFileName
    set fileName=!FNAME_WEXT!
    REM Tokenize the FNAME_WEXT based on '.'. Seperate out file Name and Extension
    for /f "tokens=1 delims=." %%a in ("!FNAME_WEXT!") do set PAARNAME=%%a
	goto checkService
endlocal
rem END PAARNAME EXTRACTION
	
rem Check whether the target OEABL WebApp directory exists	
:checkService
    if exist "%APPDIR%" goto checkOpt
    echo "%APPDIR%"
    echo No services deployed with name %APPNAME%
    echo.
    goto ERR
	
rem Check whether this request is deploy/undeploy/invalid 		
:checkOpt
    if "%OPT_UNDEP%" == "-undeploy" (
      echo Undeploying
      goto undeployService
    ) else (
      if "%OPT_UNDEP%" == "" (
        echo Deploying
	    goto checkSrcDesc
      ) else (
        echo "Unknown option: %OPT_UNDEP%"
        goto ERR
      )
    )

rem Determine if the Source Descriptor File exists
:checkSrcDesc
if exist "%DESCLOC%" goto copySrcDesc
    echo.
    echo Unable to locate file "%DESCLOC%"
    echo.
    goto ERR
    
rem Start creating the Directory with the PAARName and copy
:copySrcDesc
    set SERVICEDIR=%APPDIR%\WEB-INF\adapters\rest\%PAARNAME%
    if exist "%SERVICEDIR%" (
      echo "%SERVICEDIR%"
      if exist "%SERVICEDIR%\%FNAME_WEXT%" (
        echo File "%FNAME_WEXT%" Already Exists.
        echo Updating.
        goto deployService
      )
      if not exist "%SERVICEDIR%\%FNAME_WEXT%" ( 
        echo "%SERVICEDIR%\%FNAME_WEXT%"
        echo No Service found in service Directory.
        echo Copying and Updating.
        goto deployService
      )
    )
    if not exist "%SERVICEDIR%" ( 
      echo Creating Directory "%SERVICEDIR%"
      mkdir "%SERVICEDIR%"
      echo Copying and Updating.
      goto deployService
      if not errorlevel 0 goto ERR
    )
    goto end
    
rem Start updating web.xml for deploy
:deployService
    "%JAVA_HOME%\bin\java.exe" -Dlogback.configurationFile=%CATALINA_BASE%\conf\logging-restdeploy.xml -cp "%CLASSPATH%" %DEPLOYMGRCLASS% -artifact "%DESCLOC%" -webapploc "%CATALINA_WEBAPPS%" -service %APPNAME% -deploy
    set _exitstatus=%errorlevel%
    goto end    
	
rem Start updating web.xml for undeploy	
:undeployService
    "%JAVA_HOME%\bin\java.exe" -Dlogback.configurationFile=%CATALINA_BASE%\conf\logging-restdeploy.xml -cp "%CLASSPATH%" %DEPLOYMGRCLASS% -artifact "%DESCLOC%" -webapploc "%CATALINA_WEBAPPS%"  -service %APPNAME% -undeploy
    set _exitstatus=%errorlevel%
    goto end 
	
rem List out the correct options to run the utility
:doUsage
    echo Utility to deploy or undeploy a REST service from an OEABL WebApp
    echo.
    echo Usage:  deployREST [Descriptor or ServiceName] [OEABL WebApp Name] [Options]
    echo.
    echo Source Descriptor           Path of the Source Descriptor [.paar] OR
    echo                             Rest Service Name when used with -undeploy
    echo OEABL WebApp Name           Name of the OEABL Web Application
    echo Options                     -undeploy
    echo.
    echo Examples:
    echo Deploy 'test.paar' to OEABL WebApp named 'ROOT'
    echo     "deployREST C:\temp\test.paar ROOT"
    echo.
    echo Undeploy an existing REST service named 'test' from OEABL WebApp 'ROOT'
    echo     "deployREST test ROOT -undeploy"

:ERR
    set _exitstatus=1

:end
    if defined _removeCatBase (
set CATALINA_BASE=C:\Projets\KEYCLO~1\pasoe
        set _removeCatBase=
    )

exit /b %_exitstatus%

