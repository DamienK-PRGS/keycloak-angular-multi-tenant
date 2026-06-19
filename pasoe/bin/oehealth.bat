@echo off 

set basedir=%~dp0
set EXECUTABLE=PowerShell.exe -executionpolicy bypass -File "%basedir%/oehealth.ps1" %*

%EXECUTABLE%
