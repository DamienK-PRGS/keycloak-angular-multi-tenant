@echo off

rem Catalina environment setup specific to the OpenEdge product set.
rem This scripts adds in the Java system properties (-Dpsc.oe.<name>=<val>)
rem that are global and used by OpenEdge web applications and catalina
rem extensions
rem

rem Make it easy for the OpenEdge installer to tailor the DLC and WRKDIR
rem locations so that they can be easily preserved when creating 
rem AppServer instances and/or clones

if not defined DLC (
set DLC=C:\DLC\128
)
if not defined WRKDIR (
set WRKDIR=C:\DLC\WRK\128
)

rem Load environment variables from OpenEdge's WRKDIR/proset.env, if it exists

if exist "%WRKDIR%" (
    if exist "%WRKDIR%"\proset.bat (
        if defined CATALINA_DEBUG echo dbg: openedge_setenv.bat calling "%WRKDIR%"\proset.bat
        call "%WRKDIR%"\proset.bat
    )
)

rem Turn on extended client logging in the
rem multi-session Agent.  
rem If not defined enhlogging is off [ "DE" ]. 
rem If defined enhanced logging is enabled and the value controls :
rem { D|d| }
rem    D=ISO date/time  
rem    d=AVM date/time  
rem    undefined=D
rem
rem { E|e| }
rem    E=enhanced log format 
rem    e=AVM common format
rem    undefined=E
set ENHLOGGINGOPTS=ED

rem Now add those as Java system properties to JAVA_OPTS environment variable
set _oeopts=-Dpsc.as.oe.dlc="%DLC%"
set _oeopts=%_oeopts% -Dpsc.as.oe.wrkdir="%WRKDIR%"
set _oeopts=%_oeopts% -Dlogback.ContextSelector="JNDI"
set _oeopts=%_oeopts% -Dlogback.configurationFile="file:///%CATALINA_BASE%/conf/logging.xml"
rem set network buffer size to 60K
set _oeopts=%_oeopts% -DPROGRESS.Session.NetworkBufferSize="60000"

rem Speeds up search for TransformerFactory implementation (uses to parse SOAP message)
set _oeopts=%_oeopts% -Djavax.xml.transform.TransformerFactory=net.sf.saxon.TransformerFactoryImpl

rem get the current user's login ID & user account SID
if not exist "%windir%\System32\whoami.exe" goto whoamiWarn
for /f "tokens=1,2 USEBACKQ delims= " %%f in (`%windir%\System32\whoami.exe /USER /NH`) do set uid=%%f & set sid=%%g
set _oeopts=%_oeopts% -Dpsc.as.uid=%sid%
set _oeopts=%_oeopts% -Dpsc.as.whoami=%uid%

rem this is needed for the health scanner
set _oeopts=%_oeopts% --add-opens=jdk.management/com.sun.management.internal=ALL-UNNAMED

rem this is needed to supress 1padapter warning on Windows console
set _oeopts=%_oeopts% --add-opens=java.base/java.lang=ALL-UNNAMED

if not defined sid goto whoamiWarn
if not defined uid goto whoamiWarn
goto setOpts

:whoamiWarn
echo WARNING: could not set the user and account id properties

:setOpts
rem Now add the accumulated Java properties to the original list
set JAVA_OPTS=%JAVA_OPTS% %_oeopts%

if defined CATALINA_DEBUG echo dbg: openedge_setenv.bat updated JAVA_OPTS to %JAVA_OPTS%

exit /b 0
