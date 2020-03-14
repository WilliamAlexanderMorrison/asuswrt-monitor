#!/bin/sh

#constants
LOGHOST="192.168.1.109"
LOGPATH="/home/pi/hassio/homeassistant/.storage/asus-monitor-logs/"

#get the router name and remove trailing spaces if any
routerName=`nvram get computer_name | sed 's/ *$//g'`
#build router name strings to keep things consistent across aimesh nodes
clientTag=$routerName".local"
logTag=$LOGPATH$routerName".log"
sshTag="id_"$routerName
#look up the IP of this router in the hosts file
localhostIP=`grep $clientTag /etc/hosts | awk '{print $1}'`
#look up the main router's IP address
logserverIP=`nvram get lan_ipaddr_rt`

#get cpu temp
tempCpu=`cat /proc/dmu/temperature | awk {'print substr($4,1,2)'}`
#get radio temps and convert to C by dividing by 2 and adding 20
e1=`wl -i eth1 phy_tempsense | awk '{print $1}'`
tempRadio=`expr $e1 / 2 + 20`
e2=`wl -i eth2 phy_tempsense | awk '{print $1}'`
tempRadio=`expr $e2 / 2 + 20 + $tempRadio`
#handle both single and dual 5ghz cell radio temperatures
e3=`wl -i eth3 phy_tempsense | awk '{print $1}'`
if [ -n "$e3" ] && [ "$e3" -eq "$e3" ] 2>/dev/null
then
  tempRadio=`expr $e3 / 2 + 20 + $tempRadio`
  tempRadio=`expr $tempRadio / 3`
else
  tempRadio=`expr $tempRadio / 2`
fi
#get 1m CPU load
load1m=`cat /proc/loadavg | cut -d' ' -f 0`
#get the uptime in seconds
uptime=`cat /proc/uptime | cut -d' ' -f 0`

# build the log message JSON
logMsg='\{'
logMsg=$logMsg'\"tempcpu\":'$tempCpu','
logMsg=$logMsg'\"tempradio\":'$tempRadio','
logMsg=$logMsg'\"load1m\":'$load1m','
logMsg=$logMsg'\"uptime\":'$uptime
logMsg=$logMsg'\}'

#ensure the known hosts file is populated so the script doesn't hang
catKnownHost=`cat /jffs/root/.ssh/cat_known_hosts`
if grep -q "$catKnownHost" /tmp/home/root/.ssh/known_hosts
then
    true
else
    cat /jffs/root/.ssh/cat_known_hosts >> /tmp/home/root/.ssh/known_hosts
fi


#establish the remote command
rcmd="echo "$logMsg" | sudo tee -a "$logTag";"
#ssh to the rpi and execute the command
ssh -i /jffs/root/.ssh/$sshTag -l pi $LOGHOST $rcmd