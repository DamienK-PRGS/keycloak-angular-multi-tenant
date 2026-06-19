@echo off
rem Licensed to the Apache Software Foundation (ASF) under one or more
rem contributor license agreements.  See the NOTICE file distributed with
rem this work for additional information regarding copyright ownership.
rem The ASF licenses this file to You under the Apache License, Version 2.0
rem (the "License"); you may not use this file except in compliance with
rem the License.  You may obtain a copy of the License at
rem
rem     http://www.apache.org/licenses/LICENSE-2.0
rem
rem Unless required by applicable law or agreed to in writing, software
rem distributed under the License is distributed on an "AS IS" BASIS,
rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
rem See the License for the specific language governing permissions and
rem limitations under the License.

if "%OS%" == "Windows_NT" setlocal
rem ---------------------------------------------------------------------------
rem Start script for the CATALINA Server
rem ---------------------------------------------------------------------------
rem Insert a point where installers can set a fixed CATALINA_HOME location
set CATALINA_HOME=C:\DLC\128\servers\pasoe

rem Guess CATALINA_HOME if not defined
set "CURRENT_DIR=%cd%"
if not "%CATALINA_HOME%" == "" goto gotHome
set "CATALINA_HOME=%CURRENT_DIR%"
if exist "%CATALINA_HOME%\bin\catalina.bat" goto okHome
cd ..
set "CATALINA_HOME=%cd%"
cd "%CURRENT_DIR%"
:gotHome
if exist "%CATALINA_HOME%\bin\catalina.bat" goto okHome
echo The CATALINA_HOME environment variable is not defined correctly
echo This environment variable is needed to run this program
goto end
:okHome

set "EXECUTABLE=%CATALINA_HOME%\bin\catalina.bat"

rem Check that target executable exists
if exist "%EXECUTABLE%" goto okExec
echo Cannot find "%EXECUTABLE%"
echo This file is needed to run this program
goto end
:okExec

rem Allow an tcman create command tailor CATALINA_BASE 
set CATALINA_BASE=C:\Projets\KEYCLO~1\pasoe

rem Allow tailoring of where temp files are accessed, but 
rem allow the individual's environment to supercede tailoring
if "%CATALINA_TMPDIR%" == "" goto gottmp
set CATALINA_TMPDIR=C:\Projets\KEYCLO~1\pasoe\temp
:gottmp

rem Get the alias name for the server we are starting and 
rem set CATALINA.BAT's TITLE variable so that we can
rem locate the running instance later based on the Windows
rem title name
if not defined CATALINA_BASE goto usehome
set _asprops=%CATALINA_BASE%\conf\appserver.properties
goto getalias
:usehome
set _asprops=%CATALINA_HOME%\conf\appserver.properties

:getalias
for /f "tokens=2 delims==" %%a in ('findstr psc.as.alias "%_asprops%"' ) do set _TMP=%%a
if "%_TMP%"=="" set _TMP="tomcat"
set _1chr=%_TMP:~0,1%
if "%_1chr" neq """" goto setTitle
set _TMP=%_TMP:~1%
set _ALIAS=%_TMP:~0,-1%
set TITLE=PAS-%_ALIAS%
goto docall

:setTitle
set TITLE=PAS-%_TMP%


:docall
call "%EXECUTABLE%" start %*
exit /b %ERRORLEVEL%

:end
exit /b 1
