#!/bin/sh
# Test for a user defined private CATALINA_HOME
if [ -z "$CATALINA_HOME" ] 
then
    # Allow an install tailored CATALINA_HOME to be used if the user
    # has not already defined their own private location
    CATALINA_HOME=""
    export CATALINA_HOME
    if [ -z "$CATALINA_HOME" ]
    then
        echo "CATALINA_HOME is not defined or points to an invalid server installation"
        exit 1
    fi
fi

PRGDIR="$CATALINA_HOME"/bin
EXECUTABLE=oests_tailor.sh
if [ ! -x "$PRGDIR"/"$EXECUTABLE" ]; then
    echo "Cannot find $PRGDIR/$EXECUTABLE that is needed to run this program"
    exit 1
fi

# Allow an tcman create command tailor CATALINA_HOME 
CATALINA_BASE=""
export CATALINA_BASE

# Allow tailoring of where temp files are accessed, but 
# allow the individual's environment to supercede tailoring
if [ -z "$CATALINA_TMPDIR" ] ; then
CATALINA_TMPDIR=""
export CATALINA_TMPDIR
fi

# Define a place where the JAVA_HOME and/or JRE_HOME process environment
# variables can be customized before executing JAVA related operations.
# This script will call out to the javacfg.sh script in the CATALINA_HOME
# directory to do the work so that it is in sync with the tcmanager utility 
# version.
if [ -f "$CATALINA_HOME/bin/javacfg.sh" ] ; then
    . "$CATALINA_HOME/bin/javacfg.sh"
fi

exec "$PRGDIR"/"$EXECUTABLE" "$@" 

