#!/bin/bash
# Script to deploy a SOAP application to a given SERVER Instance

# List out the correct options to run the utility

HELP()
{
    echo "Utility to deploy or undeploy a SOAP service                                  "
	echo "Usage:                                                                        "
    echo "deploySOAP.sh <WSM or ServiceName> <WebApp> [-undeploy] or [<Optional argumens>] "
    echo "   WSM            - WSM File path (if no -undeploy argument)                   "
	echo "   ServiceName    - Deployed SOAP Service Name (if -undeploy  used)            "
    echo "   WebApp         - Web Application Name                                       "
    echo "   -undeploy      - invokes undeployment of the SOAP service                   " 
	echo "   Optional arguments:                                                         "
	echo "     -name:<name>     - UI name. Overwrites WSM service name                   "
	echo "     -tns:<namesapce> - Target Namespace. Overwrites WSM target namespace      "
    echo "     -enc:<encoding>  - SOAP encoding type. Overwrites WSM encoding type:      "
    echo "                           1-RPC enoded, 2-RPC literal, 3-Domument literal     "
    echo " Examples:                                                                     "
    echo "   Deploy 'test.wsm' to OEABL WebApp named 'ROOT'                              "
    echo "      deploySOAP.sh /tmp/test.wsm ROOT                                         "
    echo "   Deploy 'test.wsm' to OEABL WebApp named 'ROOT', set RPC literal encoding    "
    echo "      deploySOAP.sh /tmp/test.wsm ROOT -enc:2                                  "
    echo "   Undeploy 'test' SOAP service  from WebApp 'ROOT'                 "
    echo     "deploySOAP test ROOT -undeploy"


}

# Read Command Line Arguments
SRCDESCLOC=$1
APPNAME=$2
OPT_UNDEP=$3
user=$4

if [ "$OPT_UNDEP" != "-undeploy" ]
then
    echo $OPT_UNDEP | grep ":" >> /dev/null
    if [ $? = 0 ]
    then
        OPT_UNDEP=$user
        user=$3
    fi
fi
if [ "$user" = "" ]
then
        user="null:null"
fi

# Extract the file name from the source path 
# FNAME_WEXT is the file name with extension
# PAARNAME is the file name without extension
GET_NAME()
{
    # PATH_SEG=$(echo $SRCDESCLOC | tr "/" "\n")
    PATH_SEG=`echo $SRCDESCLOC | tr "/" "\n"`
    for SEG in $PATH_SEG
    do
        FNAME_WEXT=$SEG
    done

    #PAARNAME=$(echo $FNAME_WEXT | cut -d '.' -f1)
    PAARNAME=`echo $FNAME_WEXT | cut -d '.' -f1`
    EXTNAME=`echo $FNAME_WEXT | cut -d '.' -f2`
    echo $PAARNAME
}

# Function to read the DNS Name 
loadDNSName() {
_dnsname=..
_new=..
_hostname=..
    if [ "`uname`" = "AIX" ] ; then
        _new="-n"
    else
        _new=""
    fi
    _tmpfil="$CATALINA_BASE/temp/host$$.dat"
    _hostname=`uname -n | cut -d " " -f 1`
    host ${_new} ${_hostname} > $_tmpfil 2>&1
    if [ $? = 0 ] ; then
        _dnsname=`cat $_tmpfil | cut -d " " -f 1 | tail -1`
    else
        _dnsname="127.0.0.1"
    fi
    if [ -f $_tmpfil ] ; then
                rm $_tmpfil
    fi
}

# Check if command is properly constructed
if [ -z "$2" ] 
then
    HELP
    exit
fi

# Allow an tcman create command tailor CATALINA_BASE
CATALINA_BASE=""
export CATALINA_BASE

# Now find all the executable product shell scripts and execute them in
# the context of this shell process
if [ ! -z "${CATALINA_DEBUG}" ]; then echo "** setenv.sh executing product specific startup scripts"; fi
for _fspec in `find ${CATALINA_BASE}/bin -type f -name "*_setenv.sh" -print`
do
    if [ ! -z "${CATALINA_DEBUG}" ]; then echo "** executing: ${_fspec}"; fi
    . ${_fspec}
done

# Check if DLC environment is available
if [ "${DLC}" = "" ] ; then
    DLC=""
    export DLC
fi
if [ -z "$DLC" ]
then
    echo "DLC environment variable not set correctly - Please set DLC variable"
    exit
fi

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

# Function to extract all propertis form  localJvm.properties
# set _jvmArgs value
getJvmScriptProperities() {
    _propfile="${CATALINA_BASE}/conf/localJvm.properties"
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


# Function to read the property files and 
# extract the property Value for the given
# property Name
_propfiles="${CATALINA_BASE}/conf/catalina.properties ${CATALINA_BASE}/conf/appserver.properties"
getProperty() 
{
_propSrc=..
_propNam=..
_propVal=..

_rec=`grep ${1}= ${_propfiles}`

if [ $? -eq 0 ] ; then
        _tmp="`echo ${_rec} | cut -d ":" -f 1`"

        if [ "$_tmp" != "$_rec" ] ; then
            _propSrc="$_tmp"
            _targ="`echo ${_rec} | cut -d ":" -f 2`"
        fi
        _delim=`echo ${_targ} | grep "="`
        if [ $? -eq 0 ] ; then
            _propNam="`echo ${_targ} | cut -d "=" -f 1`"
            if [ "${_propNam}" != "" ] ; then
                _propVal="`echo ${_targ} | cut -d "=" -f 2`"
                _ret=0
            else
                _ret=2
            fi
        else
            # Missing equals delimiter, return an error
            _propNam="${_targ}"
            _ret=2
        fi
fi
}

## Resolve the Tomcat's webapps directory
#
#  OPENEDGE_WEBAPPS is an customizable directory where user deploys
#  openedge webapps
if [ "${OPENEDGE_WEBAPPS}" = "" ]
then
    getProperty psc.as.webappdir
    WEBAPPDIR=${_propVal}
    CATALINA_WEBAPPS="$WEBAPPDIR"
    if [ -f $CATALINA_WEBAPPS ]
    then 
        echo "CATALINA_WEBAPPS is not defined or points to an invalid server installation"
        exit 1
    fi
    export CATALINA_WEBAPPS
fi

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

JREHOME=$JAVA_HOME
export JREHOME
JVMEXE=java
export JVMEXE

if [ ! -f $JREHOME/bin/$JVMEXE ]
then
    echo "Progress $PROG Messages:"
    echo
    echo "Java Virtual Machine could not be found."
    echo
    echo "JREHOME environment variable may not be set correctly."
    echo "Set JREHOME variable to a valid directory."
    echo
    echo "JREHOME setting: $JREHOME"
    echo
    exit 1
fi

## Resolve the HOSTNAME and PORT from instance environment

#

#PSC_DNS_NAME=`$CATALINA_BASE/bin/tcman.sh config | grep "psc.as.dns.name" | cut -d '=' -f 2 | tr -d '"'`
#PSC_HTTP_PORT=`$CATALINA_BASE/bin/tcman.sh config | grep "psc.as.http.port" | cut -d '=' -f 2 | tr -d '"'`
#PSC_HTTPS_PORT=`$CATALINA_BASE/bin/tcman.sh config | grep "psc.as.https.port" | cut -d '=' -f 2 | tr -d '"'`

loadDNSName
PSC_DNS_NAME=${_dnsname}
getProperty psc.as.http.port
PSC_HTTP_PORT=${_propVal}
getProperty psc.as.https.port
PSC_HTTPS_PORT=${_propVal}

echo "Using DLC:                  $DLC"
echo "Using CATALINA_HOME:        $CATALINA_HOME"
echo "Using CATALINA_BASE:        $CATALINA_BASE"
echo "Using CATALINA_WEBAPPS:     $CATALINA_WEBAPPS"
echo "Using JDK_HOME:             $JAVA_HOME"
echo "Using JRE_HOME:             $JRE_HOME"
echo "Using INSTANCE_DNS_NAME:    $PSC_DNS_NAME"
echo "Using INSTANCE_HTTP_PORT:   $PSC_HTTP_PORT"
echo "Using INSTANCE_HTTPS_PORT:  $PSC_HTTPS_PORT"

# validate jar file presents 
oejmxjar=`find $CATALINA_HOME/bin -name "oejmx*.jar"`
if [ ! -f "$oejmxjar" ]; then echo "Error! can not find  oejmx*.jar"; exit  1; fi


# Set variables to build java command line
DEPLOYMGRCLASS="com.progress.appserv.util.camel.soap.restoe.DeploySOAP2"
CLASSPATH=.:$CATALINA_BASE/common/lib/*:$CATALINA_HOME/common/lib/*:$oejmxjar
APPDIR="$CATALINA_WEBAPPS/$APPNAME"
SCHEMADIR="$CATALINA_BASE"

if [ ! -d "$APPDIR" ]
then
    echo "No services deployed with name $APPNAME"
    exit 1
fi

# Call GET_NAME() to get the name of the New Descriptor that need to be added
GET_NAME
DEPLOY_SERVICE()
{
  # Check if input Deployment Descriptor exits
  if [ ! -f "$SRCDESCLOC" ]
  then
    echo "Unable to locate file $DESC_FILE"
    exit 1
  fi

  if [ ! -z "$PAARNAME" ]
  then
    if [ ! -z "$EXTNAME" ]
    then
      if [ "$EXTNAME" != "wsm" ]
      then
        echo "Please provide a valid .wsm file to deploy."
        exit 1
      fi
    fi

    echo "Updating."
    # get $_jvmArgs
    _jvmArgs=""
    getJvmScriptProperities 
    #echo "JAVA ARGS: $_jvmArgs"
    
    # run java
    $JAVA_HOME/bin/java $_jvmArgs -Dorg.apache.cxf.Logger=org.apache.commons.logging.impl.NoOpLog -DInstall.Dir=$SCHEMADIR -cp $CLASSPATH -Dcatalina.home=$CATALINA_HOME -Dcatalina.base=$CATALINA_BASE -Dpsc.as.host.name=$PSC_DNS_NAME -Dpsc.as.http.port=$PSC_HTTP_PORT  -Dpsc.as.https.port=$PSC_HTTPS_PORT -Dlogback.configurationFile=$CATALINA_BASE/conf/logging-soapdeploy.xml $DEPLOYMGRCLASS $@
    exitCode=$?
    
  fi
}

UNDEPLOY_SERVICE()
{

    # get $_jvmArgs
    _jvmArgs=""
    getJvmScriptProperities 

    # run java
    $JAVA_HOME/bin/java $_jvmArgs -Dorg.apache.cxf.Logger=org.apache.commons.logging.impl.NoOpLog -DInstall.Dir=$SCHEMADIR -cp $CLASSPATH -Dcatalina.home=$CATALINA_HOME -Dcatalina.base=$CATALINA_BASE -Dpsc.as.host.name=$PSC_DNS_NAME -Dpsc.as.http.port=$PSC_HTTP_PORT  -Dpsc.as.https.port=$PSC_HTTPS_PORT -Dlogback.configurationFile=$CATALINA_BASE/conf/logging-soapdeploy.xml $DEPLOYMGRCLASS $@
    exitCode=$?
 }

  if [ "$OPT_UNDEP" != "-undeploy" ]
  then
    echo "Deploying"
     DEPLOY_SERVICE $@
    exit $exitCode
else
    echo "Undeploying"
    UNDEPLOY_SERVICE $@
  exit $exitCode
fi

exit 1
