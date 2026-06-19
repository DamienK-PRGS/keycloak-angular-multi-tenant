healthQuery='{"O":"PASOE:type=OEManager,name=HealthServiceManager","A":"Health"}'
healthQueryDetail='{"O":"PASOE:type=OEManager,name=HealthServiceManager","M":["getView","details"]}'
query="$healthQuery"
dbg=""
javahome=""
pasoepid=""
pasoehome=""
jacksoncore=""
jacksondatabind=""
jacksonannotations=""
oejmx=""
qResults=""


scriptPath=`dirname $0`
if [ ! "$dbg" = "" ]; then
	echo "scriptPath:  $scriptPath"
fi

#get environment parameters using tcman.sh 
envVars=`exec sh $scriptPath/tcman.sh env  javahome pid home`
envVars=`echo "$envVars" |  tr "\n" " "`

for val in  $envVars; do
if [ "$javahome" = "" ]; then	javahome="$val";   else
if [ "$pasoepid" = "" ]; then 	pasoepid="$val"; else
 pasoehome="$val";  
fi  fi
done
if [ ! "$dbg" = "" ]; then
	echo "javahome: $javahome"
	echo "pasoepid: $pasoepid"
	echo "pasoehome: $pasoehome"
fi

# Get parameters

while [ $# -gt 0 ]
do
  if [ $1 = "-D" ]; then  query="$healthQueryDetail";  fi
  if [ $1 = "-O" ]; then  shift; if [ $# -gt 0 ]; then qResults=$1;	fi  fi
  shift
done
if [ ! "$dbg" = "" ]; then
	echo "query:   $query"
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


# check output file directory
if [ ! "$qResults" = "" ]; then 
    resultsDir=`dirname $qResults`
    if [ ! -d "$resultsDir" ]; then
         echo "Error! can not access reslut file directory '$resultsDir'"
         exit 1 
    fi
fi

pasoeJmxCall="$javahome/bin/java" 
pasoeJmxCallCp="-cp $jacksoncore:$jacksondatabind:$jacksonannotations:$oejmx"
pasoeJmxCallClass="com.progress.appserv.util.jmx.JmxQuery" 

command="$pasoeJmxCall $pasoeJmxCallCp $pasoeJmxCallClass $pasoepid '$query' $qResults" 

if [ ! "$dbg" = "" ]; then
	echo "COMMAND: $command"
fi

result=`eval $command`
echo $result
