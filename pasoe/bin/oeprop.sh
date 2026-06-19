#!/bin/sh
#
# Shell wrapper to execute the PAS oeprop utility
#

# the oeprop utility runs from the main PAS server installation directory
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

# the oeprop utility needs to know the instance being modified
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

# get variables from config files into JAVA_OPTS
if [ -r "$CATALINA_BASE/bin/setenv.sh" ]; then
  . "$CATALINA_BASE/bin/setenv.sh"
elif [ -r "$CATALINA_HOME/bin/setenv.sh" ]; then
  . "$CATALINA_HOME/bin/setenv.sh"
fi

# Define a place where the JAVA_HOME and/or JRE_HOME process environment
# variables can be customized before executing JAVA related operations.
# This script will call out to the javacfg.sh script in the CATALINA_HOME
# directory to do the work so that it is in sync with the expand utility version.
if [ -f "$CATALINA_HOME/bin/javacfg.sh" ] ; then
    . "$CATALINA_HOME/bin/javacfg.sh"
fi

# A version of JAVA is required
if [ "$JAVA_HOME" = "" ] ; then
    if [ "$JRE_HOME" = "" ] ; then
        echo "JAVA_HOME is not defined"
        exit 1
    else
        JAVART=$JRE_HOME
    fi
else
    JAVART=$JAVA_HOME
fi

# Where Main is located
if [ "$OEPROP_JAR" = "" ] ; then
    # Fill in a default if the location was not already set
    # in the environment
    OEPROP_JAR="$CATALINA_HOME/bin/oeprop*.jar"
fi

# Execute it now
# -Dorg.slf4j.simpleLogger.defaultLogLevel=trace
$JAVART/bin/java $JAVA_OPTS -Dcatalina.base=$CATALINA_BASE -jar $OEPROP_JAR ${1+"$@"}
