#!/bin/bash
# Script to deploy a REST application to a given SERVER Instance

# List out the correct options to run the utility

HELP()
{
    echo "  Utility to deploy or undeploy a REST service to/from an OEABL WebApp"
    echo
    echo "  Usage:  deployREST <Descriptor or ServiceName> <OEABL WebApp Name> [-undeploy]"
    echo
    echo "  Descriptor or ServiceName: "
	echo "       Path of the Source Descriptor [.paar] OR "
    echo "       Rest Service Name when used with -undeploy"
    echo "  OEABL WebApp Name: "
    echo "       Name of the OEABL Web Application"
    echo "  -undeploy - optional parameter to undeploy already deployed service"
    echo
    echo "  Examples: "
    echo "  Deploy 'test.paar' located in /tmp directory to OEABL WebApp named 'ROOT':"
    echo "        deployREST /tmp/test.paar ROOT"
    echo
    echo "  Undeploy an existing REST service named 'test' from OEABL WebApp 'ROOT':"
    echo "        deployREST test ROOT -undeploy"

}


# Read Command Line Arguments
SRCDESCLOC=$1
APPNAME=$2
OPT_UNDEP=$3
EXIT_CODE=0

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
}

# Display help
if  [ "$1" = "-h" -o "$1" = "--help" ]
then
HELP
exit 0
fi

# Check if command has no arguments
if [ -z "$1" ] 
then
 echo "No parameters provided. Displaying Help."
 echo
    HELP
    exit 1
fi

# Check if command is properly constructed
if [ -z "$2" ] 
then
 echo "Only one parameter provided. Should be 2 or 3. Displaying Help."
 echo
    HELP
    exit 1
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

if [ "${DLC}" = "" ] ; then
    DLC=""
    export DLC
fi
# Check if DLC environment is available
if [ -z "$DLC" -o ! -d "$DLC" ]
then
    echo "DLC environment variable is not defined or points to invalid directory. DLC=$DLC"
	echo "Please set DLC variable."
    exit 1
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
    if [ -z "$CATALINA_HOME" -o ! -d "$CATALINA_HOME" ]
    then
        echo "CATALINA_HOME is not defined or points to an invalid directory. CATALINA_HOME=$CATALINA_HOME"
        exit 1
    fi
fi

## Resolve the Tomcat's webapps directory
#
#  OPENEDGE_WEBAPPS is an customizable directory where user deploys
#  openedge webapps

if [ "${OPENEDGE_WEBAPPS}" = "" ]
#YK. Should we check CATALINA_WEBAPPS rather then OPENEDGE_WEBAPPS ???
then
    WEBAPPDIR=`$CATALINA_BASE/bin/tcman.sh config | grep "psc.as.webappdir" | cut -d '=' -f 2 | tr -d '"'`
	EXIT_CODE=$?	
	if [ $EXIT_CODE -ne 0 ]
	then
	   echo " Error attempting to execute WEBAPPDIR=\$CATALINA_BASE/bin/tcman.sh config | grep \"psc.as.webappdir\" | cut -d '=' -f 2 | tr -d '\"' "  
	   exit $EXIT_CODE
	fi
	
#### if [[ "$WEBAPPDIR" = /* ]] code doesn't work on Solaris (PSC00351936) >>>>	
#  if [[ "$WEBAPPDIR" = /* ]]
#	then
#	    CATALINA_WEBAPPS="$WEBAPPDIR"
#	else
#	    CATALINA_WEBAPPS="$CATALINA_BASE/$WEBAPPDIR"
#	fi
#### Replaced with  <<<<<
	case "$WEBAPPDIR" in
	   /*) CATALINA_WEBAPPS="$WEBAPPDIR" ;;
	    *) CATALINA_WEBAPPS="$CATALINA_BASE/$WEBAPPDIR" ;;
	esac
# Or it could be:
#  if echo "$WEBAPPDIR" | grep '^/' > /dev/null
#	then
#	    CATALINA_WEBAPPS="$WEBAPPDIR"
#	else
#	    CATALINA_WEBAPPS="$CATALINA_BASE/$WEBAPPDIR"
#	fi


    if [ ! -d "$CATALINA_WEBAPPS" ]
    then 
        echo "CATALINA_WEBAPPS is not defined or points to an invalid server directory. CATALINA_WEBAPPS=$CATALINA_WEBAPPS"
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


echo "Using DLC:                  $DLC"
echo "Using CATALINA_HOME:        $CATALINA_HOME"
echo "Using CATALINA_BASE:        $CATALINA_BASE"
echo "Using CATALINA_WEBAPPS:     $CATALINA_WEBAPPS"
echo "Using JAVA_HOME:            $JAVA_HOME"
echo "Using JRE_HOME:             $JRE_HOME $JRE_WARNING"


# Set variables to build java command line
DEPLOYMGRCLASS="com.progress.appserv.manager.util.deployREST"
CLASSPATH=.:$CATALINA_HOME/common/lib/*
APPDIR="$CATALINA_WEBAPPS/$APPNAME"
DEPLOYDESCPATH="$APPDIR/WEB-INF/web.xml"
ADPTRDIR="WEB-INF/adapters/rest"

# Check whether the target OEABL WebApp directory exists	
if [ ! -d "$APPDIR" ]
then
    echo "No oeabl application deployed with name $APPNAME"
    exit 1
fi

# Call GET_NAME() to get the name of the New Descriptor that need to be added
GET_NAME
SERVICEDIR="$APPDIR/$ADPTRDIR/$PAARNAME"

UNDEPLOY_SERVICE()
{
  #Check if the service directory exists under $CATALINA_BASE/webapps/$APPNAME/WEB-INF/adapters/rest
  UNDEPLOY_FROM_DIR="$APPDIR/$ADPTRDIR/$SRCDESCLOC"
  if [ -d "$UNDEPLOY_FROM_DIR" ]
  then
  
    $JAVA_HOME/bin/java -cp $CLASSPATH $DEPLOYMGRCLASS -artifact $SRCDESCLOC -webapploc $CATALINA_WEBAPPS -service $APPNAME -undeploy  
	EXIT_CODE=$?
	if [ $EXIT_CODE -ne 0 ]
	then 
		exit $EXIT_CODE
	else
		#validate that directory deleted
		if [ -d "$UNDEPLOY_FROM_DIR" ]
		then
			echo "Error. The service directory still exists: $UNDEPLOY_FROM_DIR"
			exit 1
		fi		
	fi

  else
    echo "Service $PAARNAME not found. No directory with name $UNDEPLOY_FROM_DIR"
	exit 1
  fi
}



DEPLOY_SERVICE()
{
  # Check if input Deployment Descriptor exits
  if [ ! -f "$SRCDESCLOC" ]
  then
    echo "Unable to locate file $SRCDESCLOC"
    exit 1
  fi

  # Check if we have successfully extracted the PAARNAME and EXTNAME 
  if [ ! -z "$PAARNAME" ]
  then
    if [ ! -z "$EXTNAME" ]
    then
      if [ "$EXTNAME" != "paar" ] && [ "$EXTNAME" != "zip" ]
      then
        echo "Invalid service file name $PAARNAME.$EXTNAME. The name should have .zip or .paar extension."
        exit 1
      fi
    fi

    #Check if the service directory exists under $CATALINA_BASE/webapps/$APPNAME/WEB-INF/adapters/rest
    if [ -d "$SERVICEDIR" ]
    then
      if [ -f "$SERVICEDIR/$FNAME_WEXT" ]
      then
        echo "File $FNAME_WEXT Already Exists."
        echo "Updating."
        $JAVA_HOME/bin/java -cp $CLASSPATH $DEPLOYMGRCLASS -artifact $SRCDESCLOC -webapploc $CATALINA_WEBAPPS -service $APPNAME -deploy
		EXIT_CODE=$?
      else
        echo "No Service found in service Directory. $SERVICEDIR"
        echo "Copying and Updating."
        $JAVA_HOME/bin/java -cp $CLASSPATH $DEPLOYMGRCLASS -artifact $SRCDESCLOC -webapploc $CATALINA_WEBAPPS -service $APPNAME -deploy
		EXIT_CODE=$?
      fi
    else
      echo "Creating Directory $SERVICEDIR"
      mkdir "$SERVICEDIR"
	  EXIT_CODE=$?
	  if [ $EXIT_CODE -ne 0 ]
	  then
		exit $EXIT_CODE
	  fi
	  
      echo "Copying and Updating."
      $JAVA_HOME/bin/java -cp $CLASSPATH $DEPLOYMGRCLASS -artifact $SRCDESCLOC -webapploc $CATALINA_WEBAPPS -service $APPNAME -deploy
	  EXIT_CODE=$?
    fi
  else
    echo "Unable to resolve File Name."
	exit 1
  fi
}


if [ ! -z "$OPT_UNDEP" ]
then
  if [ "$OPT_UNDEP" != "-undeploy" ]
  then
    echo "Unknown option: $OPT_UNDEP. Use -undeploy"
    exit 1
  else
    echo "Undeploying"
    UNDEPLOY_SERVICE
    exit $EXIT_CODE
  fi
else
  echo "Deploying"
  DEPLOY_SERVICE
  exit $EXIT_CODE

fi

exit 1

