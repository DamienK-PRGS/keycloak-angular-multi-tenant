#!/bin/bash

# Function to extract all propertis form  localJvm.properties
# set _jvmArgs value
getJvmScriptProperities() {
    _propfile="${pasoebase}/conf/localJvm.properties"
    _jvmArgs=""
    if [[ -f $_propfile ]] ; then
        while IFS= read -r _line
        do
            # display line or do somthing on $line
            _nline=`echo $_line | sed 's/ *$//g'`
            if ! [[ $_nline == "#"* ]] ; then 
            _jvmArgs="$_jvmArgs $_nline"
            fi
        done <"$_propfile"
    fi
}

findJar() {
    jarName=$1
    jars=`ls $binDir/$jarName-[0-9\.]*\.jar 2>/dev/null`
    jars=`echo "$jars" |  tr "\n" " "`
for ff in  $jars; do
  jar=$ff 
done

}

# Allow an tcman create command tailor CATALINA_BASE
CATALINA_BASE=""
export CATALINA_BASE

# Check for the tailored CATALINA_HOME environment variable
if [ -z "$CATALINA_HOME" ] 
then
    ## This is where the [ANT] Tailors & injects the value of
    #  CATALINA_HOME appropriate for this instance.
    #  If not explicitly set by user, pick up CATALINA_HOME 
    #  as inserted by the tailoring script.
    CATALINA_HOME=""
    export CATALINA_HOME
    if [ -z "$CATALINA_HOME" ]
    then
        echo "CATALINA_HOME is not defined or points to an invalid server installation"
        exit 1
    fi
fi


dbg=""

# Get parameters
args=""
while [ $# -gt 0 ]
do
  args="$args $1"
  shift
done


if [ ! "$dbg" = "" ]; then
	echo "args:   $args"
fi

commonLib="$CATALINA_HOME/common/lib"
commonLibBase="$CATALINA_BASE/common/lib"
binDir="$CATALINA_HOME/bin"

# get $_jvmArgs
_jvmArgs=""
getJvmScriptProperities 

# set the java environment
if [ ! -f $CATALINA_HOME/bin/javacfg.sh ]
then
    echo
    echo "JAVA environment not set correctly."
    echo
    exit 1
fi
# Set the JAVA environment
. $CATALINA_HOME/bin/javacfg.sh

if [ ! "$dbg" = "" ]; then
	echo "JAVA_HOME: $JAVA_HOME"
fi

findJar "deployablsvc"
deployablsvc=$jar


pasoeJmxCall="$JAVA_HOME/bin/java" 

logger="org.apache.commons.logging.impl.NoOpLog"  
logbackFile="$CATALINA_BASE/conf/logging-deployablsvc.xml"

command="$pasoeJmxCall $_jvmArgs -DCATALINA_BASE=$CATALINA_BASE -DCATALINA_HOME=$CATALINA_HOME -Dorg.apache.cxf.Logger=$logger -Dlogback.configurationFile=$logbackFile -jar $deployablsvc $args" 
if [ ! "$dbg" = "" ]; then
    echo "COMMAND: $command"
fi
$command
#echo "$ret"

