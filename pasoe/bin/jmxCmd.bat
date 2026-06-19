@echo off 
set basedir=%~dp0
set EXECUTABLE=PowerShell.exe -executionpolicy bypass -File "%basedir%/jmxCmd.ps1" %*

%EXECUTABLE%
