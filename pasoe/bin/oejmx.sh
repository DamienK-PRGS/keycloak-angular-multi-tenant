#!/bin/bash
# A monitoring tool. Uses jmx services to access Tomcat beans:
#  - generates a list of bean operations and attributes exposed to jmx
#  - invokes bean operations and reads bean attributes.
# Accepts four optional attributes
# -C - signals to generate a list of bean operations/attributes 
# -Q <query parameter> -
#    query parameter could be either a path to a file with a set of JMX queries or a single JMX query 
#    Find example JMX queries file default.qry in <CATALINA_BASE>\bin\jmxqueries directory
#    A single JMX query is a JSON string like in default.qry with escaped quote and curly bracket characters. For example:
#         \{\"O\":\"PASOE:type=OEManager,name=AgentManager\",\"M\":[\"getAgents\",\"oepas1\"]\}
#    This parameter is ignored if -C attribute present. Default value: <PASOE Base Dir>/bin/queries/queries.txt.   
# -O [<file name>] - output file name (with path). 
#    If no file name provided then the output directed to the console
#    The file name may include timestamp template: {TIMESTAMP} or {TIMESTAMP:<java type datetime format>}
#    Default values if no -O key used:
#      If -C argument presents: <PASOE Temp Dir>/beanInfo{TIMESTAMP:yyMMdd-HHmm}.txt
#      If no -C argument:  <PASOE Temp Dir>/queries-out-{TIMESTAMP:yyMMdd-HHmmss}.txt
#    This parameter is ignored if a single JMX query used
# -R - signals write into output file results only. Otherwise output file also includes query texts. 
#    Ignored if -C argument is present or a single JMX query used
# Get the script directory

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

dbg=""
javahome=""
tmpdir=""
pasoepid=""
pasoehome=""
pasoebase=""
beanInfo=""
resultOnly=""
resultOnlyArg=""
queriesArg=""
jacksoncore=""
jacksondatabind=""
jacksonannotations=""
oejmx=""
qResults=""
queryFile=""
queryJSON=""

scriptPath=`dirname $0`
if [ ! "$dbg" = "" ]; then
	echo "scriptPath:  $scriptPath"
fi


if [ "$CATALINA_HOME" = "" ] ; then
    # Install tailoring will fill in this location of CATALINA_HOME
    CATALINA_HOME=""
    # If install tailoring did not run, then stop here
    if [ "$CATALINA_HOME" = "" ] ; then
        echo "CATALINA_HOME is not defined"
        exit 1
    fi
    export CATALINA_HOME
fi


if [ "$CATALINA_BASE" = "" ] ; then
    # tcman create will fill in the location of CATALINA_BASE
    CATALINA_BASE=""
    # If tcman create did not run, then stop here
    if [ "$CATALINA_BASE" = "" ] ; then
        echo "CATALINA_BASE is not defined"
        exit 1
    fi
    export CATALINA_BASE
fi

#Define a place where the JAVA_HOME and/or JRE_HOME process environment
# variables can be customized before executing JAVA related operations.
# This script will call out to the javacfg.sh script in the CATALINA_HOME
# directory to do the work so that it is in sync with the expand utility version.
if [ -f "$CATALINA_HOME/bin/javacfg.sh" ] ; then
    . "$CATALINA_HOME/bin/javacfg.sh"
fi

# A version of JAVA is required
if [ "$JAVA_HOME" = "" ] ; then
    echo "JAVA_HOME is not defined"
    exit 1
fi

javahome=$JAVA_HOME
tmpdir=$CATALINA_BASE/temp
pasoehome=$CATALINA_HOME
pasoebase=$CATALINA_BASE
CATALINA_PID="$tmpdir"/catalina-`basename ${pasoebase}`.pid

# Check if pid file exists
if [ ! -f $CATALINA_PID ]; then
    echo "Error! Cannot find pid file $CATALINA_PID. Server must be running to execute oejmx script.";
    exit 1;
fi

pasoepid=`cat ${CATALINA_PID}`

if [ ! "$dbg" = "" ]; then
	echo "javahome: $javahome"
	echo "tmpdir: $tmpdir"
	echo "pasoepid: $pasoepid"
	echo "pasoehome: $pasoehome"
fi

# Check is server is running
kill -0 $pasoepid > /dev/null 2>&1
_ret=$?
if [ $_ret -gt 0 ] ; then
    echo "Error! Cannot find running process with pid: $pasoepid. Server must be running to execute oejmx script.";
    exit 1;
fi

# Check if server is running using lifecycle file
lifecycle="$tmpdir/*.lifecycle"
if [ ! -f $lifecycle ]; then
    echo "Error! Cannot find lifecycle file in $tmpdir. Server must be running to execute oejmx script.";
    exit 1;
fi


# Get parameters
qResults=$tmpdir
queriesArg=""
parg=""
arg=""
known=""
while [ $# -gt 0 ]
do
  if [ "$1" = "-R" ]; then  resultOnlyArg="-R"; arg=$1; known="1"; fi
  if [ "$1" = "-C" ]; then  beanInfo="-C";  arg=$1; known="1"; fi
  if [ "$1" = "-Q" ]; then  arg=$1; known="1"; fi 
  if [ "$1" = "-O" ]; then  arg=$1; qResults="@"; known="1"; fi 

  if [ "$arg" = "" ]; then 
    if [ "$parg" = "-O" ]; then qResults=$1; known="1"; fi 
    if [ "$parg" = "-Q" ]; then queriesArg=$1; known="1"; fi 
  fi
  if [ "$known" = "" ]; then
     echo "Error! Unknown parameter $1"
     exit 1
  fi   
  parg=$arg
  arg=""
  known=""
  shift
done

if [ ! "$dbg" = "" ]; then
	echo "beanInfo:   $beanInfo"
	echo "resultOnlyArg: $resultOnlyArg"
	echo "queriesArg:    $queriesArg"
	echo "qResults:   $qResults"
fi

# validate jar file presents 
commonLib="$pasoehome/common/lib"
jacksonJars=`ls $commonLib/jackson-*-[0-9\.]*\.jar`
jacksonJars=`echo "$jacksonJars" |  tr "\n" " "`

for ff in  $jacksonJars; do
  nn=`expr match "$ff" ".*jackson-core-2.*"` 
  if [ ! "$nn" = "0" ]; then jacksoncore=$ff; else
   nn=`expr match "$ff" ".*jackson-databind.*"` 
  if [ ! "$nn" = "0" ]; then jacksondatabind=$ff; else
  nn=`expr match "$ff" ".*jackson-annotations.*"` 
  if [ ! "$nn" = "0" ]; then jacksonannotations=$ff; 
  fi fi fi
done 

if [ "$jacksoncore" = "" ] ; then
	echo "Error! Can't find jackson-core*.jar in directory $commonLib";
	exit 1
fi
if [ "$jacksondatabind" = "" ] ; then
	echo "Error! Can't find jackson-databind*.jar in directory $commonLib";
	exit 1
fi
if [ "$jacksonannotations" = "" ] ; then
	echo "Error! Can't find jackson-annotations*.jar in directory $commonLib";
	exit 1
fi


# find oejmx jar
binDir="$pasoehome/bin"
oejmxJars=`ls $binDir/oejmx-[0-9\.]*\.jar`
oejmxJars=`echo "$oejmxJars" |  tr "\n" " "`

for ff in  $oejmxJars; do
  oejmx=$ff 
done 

if [ "$oejmx" = "" ] ; then
	echo "Error! Can't find oejmx*.jar in directory $binDir";
	exit 1
fi

# check queries file
if [ "$beanInfo" = "" ]; then
if [ "$queriesArg" = "" ]; then 
	queryFile="$scriptPath/jmxqueries/default.qry"
else
    first=`echo "$queriesArg" | cut -c1`
    if [ "$first" = "{" ]; then
        queryJSON="$queriesArg"
    else
        queryFile="$queriesArg"
    fi
fi
resultOnly="$resultOnlyArg"
if [ ! "$queryFile" = "" ]; then
if [ ! -f "$queryFile" ]; then
     echo "Error! Cannot find queries file  '$queryFile'"
     exit 1 
fi
fi
fi

# get $_jvmArgs
_jvmArgs=""
getJvmScriptProperities 
#echo "JAVA ARGS: $_jvmArgs"


# run jmx query
pasoeJmxCall="$javahome/bin/java" 
pasoeJmxCallCp="-cp $jacksoncore:$jacksondatabind:$jacksonannotations:$oejmx"

if [ ! "$queryFile" = "" ]; then
    pasoeJmxCallClass="com.progress.appserv.util.jmx.PASOEWatch" 
    command="$pasoeJmxCall $_jvmArgs $pasoeJmxCallCp $pasoeJmxCallClass $pasoepid $queryFile $qResults $resultOnly $beanInfo"
    if [ ! "$dbg" = "" ]; then
        echo "COMMAND: $command"
    fi
    eval "$command"
fi
if [ ! "$beanInfo" = "" ]; then
    pasoeJmxCallClass="com.progress.appserv.util.jmx.PASOEWatch" 
    command="$pasoeJmxCall $_jvmArgs $pasoeJmxCallCp $pasoeJmxCallClass $pasoepid $queryFile $qResults $resultOnly $beanInfo"
    if [ ! "$dbg" = "" ]; then
        echo "COMMAND: $command"
    fi
    eval "$command"
fi
if [ ! "$queryJSON" = "" ]; then
    pasoeJmxCallClass="com.progress.appserv.util.jmx.JmxQuery" 
    command="$pasoeJmxCall $_jvmArgs $pasoeJmxCallCp $pasoeJmxCallClass $pasoepid $queryJSON"
    if [ ! "$dbg" = "" ]; then
        echo "COMMAND: $command"
    fi
    ret=`$command`
    echo "$ret"
fi

