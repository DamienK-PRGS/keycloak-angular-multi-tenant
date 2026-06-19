#!/bin/sh
# Catalina environment setup specific to the OpenEdge product set.
# This scripts adds in the Java system properties (-Dpsc.oe.<name>=<val>)
# that are global and used by OpenEdge web applications and catalina
# extensions

# Make it easy for the OpenEdge installer to tailor the DLC and WRKDIR
# locations so that they can be easily preserved when creating 
# AppServer instances and/or clones
if [ "${DLC}" = "" ] ; then
    DLC=""
    export DLC
fi
if [ "${WRKDIR}" = "" ] ; then
    WRKDIR="${CATALINA_BASE}/work"
    export WRKDIR
fi

# Load environment variables from OpenEdge's WRKDIR/proset.env, if it exists
if [ "${WRKDIR}" != "" -a -f "${WRKDIR}"/proset.env ]
then
    . "${WRKDIR}"/proset.env
fi

# Turn on extended client logging in the
# multi-session Agent.  
# If not defined enhlogging is off [ "DE" ]. 
# If defined enhanced logging is enabled and the value controls :
# { D|d| }
#    D=ISO date/time  
#    d=AVM date/time  
#    undefined=D
#
# { E|e| }
#    E=enhanced log format 
#    e=AVM common format
#    undefined=E
ENHLOGGINGOPTS=ED; export ENHLOGGINGOPTS

# Now add those as Java system properties to JAVA_OPTS environment variable
_oeopts="-Dpsc.as.oe.dlc=${DLC}"
_oeopts="${_oeopts} -Dpsc.as.oe.wrkdir=${WRKDIR}"
_oeopts="${_oeopts} -Dlogback.ContextSelector=JNDI"
_oeopts="${_oeopts} -Dlogback.configurationFile=file:///${CATALINA_BASE}/conf/logging.xml"
#_oeopts="${_oeopts} -Dpsc.as.uid=`id -u`" -- YK: Doesn't work on Solaris
#_oeopts="${_oeopts} -Dpsc.as.whoami=`id -un`" -- YK:  Doesn't work on Solaris
uidstr=`exec id`
_oeopts="${_oeopts} -Dpsc.as.uid=`echo $uidstr | sed 's/uid=//' | sed 's/(.*//'`"
_oeopts="${_oeopts} -Dpsc.as.whoami=`echo $uidstr | sed 's/uid=[0-9]*(//'  | sed 's/).*//'`"

#Speeds up search for TransformerFactory implementation (uses to parse SOAP message)
_oeopts="${_oeopts}  -Djavax.xml.transform.TransformerFactory=net.sf.saxon.TransformerFactoryImpl"


# set network buffer size to 60K
_oeopts="${_oeopts} -DPROGRESS.Session.NetworkBufferSize=60000"

# this is needed for the health scanner
_oeopts="${_oeopts} --add-opens jdk.management/com.sun.management.internal=ALL-UNNAMED"

# this is needed to supress 1padapter warning on Windows console
_oeopts="${_oeopts} --add-opens java.base/java.lang=ALL-UNNAMED"

# Optional system property to enable instrumentation
# _oeopts="${_oeopts} -Dpsc.as.oe.instrument=true"


#if [ `uname` = "AIX" ]
#then

# _oeopts="${_oeopts} -Djavax.xml.soap.MessageFactory=com.sun.xml.messaging.saaj.soap.ver1_1.SOAPMessageFactory1_1Impl
#-Djavax.xml.soap.SOAPFactory=com.sun.xml.messaging.saaj.soap.ver1_1.SOAPFactory1_1Impl
#-Djavax.xml.soap.SOAPConnectionFactory=com.sun.xml.messaging.saaj.client.p2p.HttpSOAPConnectionFactory
#-Djavax.xml.soap.MetaFactory=com.sun.xml.messaging.saaj.soap.SAAJMetaFactoryImpl"

#fi

JAVA_OPTS="${JAVA_OPTS} ${_oeopts}" ; export JAVA_OPTS
