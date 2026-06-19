#!/bin/bash

scriptdir=`dirname $0`

verbose=0
knownCommand=""
command=""

if [ $# -gt 0 ]; then
    command=$1
    shift
fi
#Refresh agents
if [ "$command" = "refreshagents" ]; then
    knownCommand="1"
    appname=""
    waitForAppName=""
    if [ $# -lt 2 ]; then
        echo "Error. Not enough parameters for command refreshagents"
        echo "Command format: refreshagents -appname <application name> [-v]"
        exit
    fi
    
    while [ $# -gt 0 ]
    do
        if [ ! "$waitForAppName" = "" ]; then 
            appname=$1
            waitForAppName=""
            shift
            continue
        fi
        key=$1
        if [ "$key" = "-v" ]; then
            verbose=1
            shift
            continue
        fi
        if [ "$key" = "-appname" ]; then
            waitForAppName="1"
            shift
            continue
        fi
        echo "Error. Unknown parmeter $key"
        echo "Command format: refreshagents -appname <application name>"
        exit
    done
    
    if [ "$appname" = "" ]; then
        write-output "Error. Application name not provided"
        exit
    fi
    query="{{\"O\":\"PASOE:type=OEManager,name=AgentManager\",\"M\":[\"refreshAgents\",\"$appname\"]}"
    #result=`./oejmx.sh -Q $query`
    result=`$scriptdir/oejmx.sh -Q $query 2>&1`
    if [ $verbose -eq 1 ]; then
        echo "$result"
    else
        resultTemplate='{"refreshAgents":{"agents"'
        if [[ "$result" == "$resultTemplate"* ]]; then 
            echo "success"
        else 
            echo "failure. Set -v key to display jmx result"
        fi
    fi
        
fi 
#Refresh Web Handlers
if [ "$command" = "refreshWeb" ]; then
    knownCommand="1"
    appname=""
    webappname=""
    waitForAppName=""
    waitForWebAppName=""
    if [ $# -lt 4 ]; then
        echo "Error. Not enough parameters for command refreshWeb"
        echo "Command format: refreshWeb -appname <application name> -webappname <webapp name> [-v]"
        exit
    fi
    
    while [ $# -gt 0 ]
    do
        if [ ! "$waitForAppName" = "" ]; then 
            appname=$1
            waitForAppName=""
            shift
            continue
        fi
        if [ ! "$waitForWebAppName" = "" ]; then 
            webappname=$1
            waitForWebAppName=""
            shift
            continue
        fi
        key=$1
        if [ "$key" = "-v" ]; then
            verbose=1
            shift
            continue
        fi
        if [ "$key" = "-appname" ]; then
            waitForAppName="1"
            shift
            continue
        fi
        if [ "$key" = "-webappname" ]; then
            waitForWebAppName="1"
            shift
            continue
        fi
        echo "Error. Unknown parmeter: $key"
        echo "Command format: refreshWeb -appname <application name> -webappname <webapp name> [-v]"
        exit
    done
    
    if [ "$appname" = "" ]; then
        echo "Error. Application name not provided"
        exit
    fi
    if [ "$webappname" = "" ]; then
        echo "Error. Webapp name not provided"
        exit
    fi
    query="{{\"O\":\"PASOE:type=OEManager,name=WebTransportManager\",\"M\":[\"refreshWebHandlers\",\"$appname\",\"$webappname\"]}"
    #echo $query 
    result=`$scriptdir/oejmx.sh -Q $query 2>&1`
    if [ $verbose -eq 1 ]; then
        echo "$result"
    else
        resultTemplate='{"refreshWebHandlers":{"handlers"'
        if [[ "$result" == "$resultTemplate"* ]]; then 
            echo "success"
        else 
            echo "failure. Set -v key to display jmx result"
        fi
    fi
fi 
if [ "$knownCommand" = "" ]; then
    
    if [ "$command" = "" ]; then 
        echo "Error. No command provided"
    else 
        echo "Error. Unknown command $command"
    fi
   echo "Implemented commands: "
   echo "  refreshagents"
   echo "  refreshWeb"
   
fi
