#!/bin/sh

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# -----------------------------------------------------------------------------
# Version Script for the CATALINA Server
# -----------------------------------------------------------------------------

# Better OS/400 detection: see Bugzilla 31132
os400=false
case "`uname`" in
OS400*) os400=true;;
esac

# resolve links - $0 may be a softlink
PRG="$0"

while [ -h "$PRG" ] ; do
  ls=`ls -ld "$PRG"`
  link=`expr "$ls" : '.*-> \(.*\)$'`
  if expr "$link" : '/.*' > /dev/null; then
    PRG="$link"
  else
    PRG=`dirname "$PRG"`/"$link"
  fi
done

PRGDIR=`dirname "$PRG"`
EXECUTABLE=catalina.sh

# Allow an install tailored CATALINA_HOME to be used if the user
# has not already defined their own private location
if [ -z "$CATALINA_HOME" ]
then
    CATALINA_HOME=""
    export CATALINA_HOME
fi

# Check that target executable exists
if [ ! -x "$PRGDIR"/"$EXECUTABLE" ]; then
    PRGDIR="$CATALINA_HOME"/bin
    if [ ! -x "$PRGDIR"/"$EXECUTABLE" ]; then
        echo "Cannot find $PRGDIR/$EXECUTABLE"
        echo "The file is absent or does not have execute permission"
        echo "This file is needed to run this program"
        exit 1
    fi
fi

# Allow an tcman create command tailor CATALINA_BASE 
CATALINA_BASE=""
export CATALINA_BASE

# Allow tailoring of where temp files are accessed, but 
# allow the individual's environment to supercede tailoring
if [ -z "$CATALINA_TMPDIR" ] ; then
CATALINA_TMPDIR=""
export CATALINA_TMPDIR
fi

# Always capture the PID of the created process to give the admin
# a chance at forcing Tomcat termination
if [ -z "$CATALINA_PID" ] ; then
    if [ -z "$CATALINA_BASE" ] ; then
        CATALINA_PID="$CATALINA_HOME/temp/catalina-`basename $CATALINA_HOME`.pid" ; export CATALINA_PID
    else
        CATALINA_PID="$CATALINA_BASE/temp/catalina-`basename $CATALINA_BASE`.pid" ; export CATALINA_PID
    fi
fi

exec "$PRGDIR"/"$EXECUTABLE" version "$@"
