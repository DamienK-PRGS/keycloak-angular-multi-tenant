#!/bin/sh
#
# Shell wrapper to execute the PAS watcher utility
#

# the oewatcher utility runs from the main PAS server installation directory
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

# the oewatcher utility needs to know the instance being modified
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

# the oewatcher utility needs tcman
TCDIR="$CATALINA_BASE"/bin
TCMAN=tcman.sh
if [ ! -x "$TCDIR/$TCMAN" ]; then
    echo "Cannot find $TCDIR/$TCMAN needed to run this program"
    exit 1
fi
PASOEPID=`exec sh $TCDIR/tcman.sh env pid`
if [ "$PASOEPID" = "" ]; then
    echo "Cannot find PASOE pid value"
    exit 1
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
    echo "JAVA_HOME is not defined"
    exit 1
fi

OEJARSPATH=${OEJARSPATH-$CATALINA_HOME/common/lib}
OEBINPATH=${OEBINPATH-$CATALINA_HOME/bin}

_oejmxjar=`find $OEBINPATH -name "oejmx-*.jar"`
_oepropjar=`find $OEBINPATH -name "oeprop.*.jar"`
OECP="${_oepropjar}:${_oejmxjar}:${OEJARSPATH}/*"


JAVAPATH=$JAVA_HOME/bin/java
WATCHERPID=$CATALINA_BASE/temp/oewatcher.pid
WATCHERCONF=${WATCHERCONF-$CATALINA_BASE/conf/oewatcher.conf}
WATCHERLOG=${WATCHERLOG-$CATALINA_BASE/logs/oewatcher.err}

case $1 in
    start)
        # echo "Starting oewatcher ..."
        if [ ! -f $WATCHERPID ]; then
            # Execute it now
            nohup $JAVAPATH -Dcatalina.base=$CATALINA_BASE -cp $OECP -Dlogback.configurationFile=$CATALINA_BASE/conf/watcher-logging.xml com.progress.appserv.util.oewatcher.OEWatcherUtil $WATCHERCONF $PASOEPID > $WATCHERLOG 2>&1 &
            WPID=$!
            sleep 3
            ps -p $WPID > /dev/null
            if [ $? == 1 ]; then
		echo "oewatcher did not start"
		exit 1
	    fi

	    # save watcher pid to file
            echo "${WPID}" > $WATCHERPID
            # echo "oewatcher started"
        else
            echo "oewatcher is already running"
        fi
    ;;
    stop)
        if [ -f $WATCHERPID ]; then
            PID=`exec cat $WATCHERPID`;
            # echo "Stopping oewatcher ..."
            kill $PID;
            # echo "oewatcher stopped"
            rm $WATCHERPID
        else
            echo "oewatcher is not running"
        fi
    ;;
    *)
        echo "usage: oewatcher [start|stop]"
esac 
