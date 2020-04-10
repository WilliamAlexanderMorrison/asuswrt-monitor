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
#initialize radio temp holders
temp1=0
temp2=0
temp3=0
tempRadio=0
successTemps=0
adapterStatus=""
#check to make sure the radio adapter is responding
if wl -i eth1 phy_tempsense
then
    #get radio temps in hex
    rawRadioTemp=`wl -i eth1 phy_tempsense | awk '{print $1}'`
    #convert hex temp to C
    temp1=`expr $rawRadioTemp / 2 + 20`
    #increment the number of successful temperatures gathered
    successTemps=`expr $successTemps + 1`
else
    #note in status if the radio adapter isn't responding
    adapterStatus=$adapterStatus'NO ETH1 '
fi
if wl -i eth2 phy_tempsense
then
    rawRadioTemp=`wl -i eth2 phy_tempsense | awk '{print $1}'`
    temp2=`expr $rawRadioTemp / 2 + 20`
    successTemps=`expr $successTemps + 1`
else
    adapterStatus=$adapterStatus'NO ETH2 '
fi
#handle dual 5ghz cell radios- 3 radio adapters to check
if wl -i eth3 phy_tempsense
then
    rawRadioTemp=`wl -i eth3 phy_tempsense | awk '{print $1}'`
    temp3=`expr $rawRadioTemp / 2 + 20`
    successTemps=`expr $successTemps + 1`
else
    adapterStatus=$adapterStatus'NO ETH3 '
fi
#get the average of the successful temp checks
if [ $successTemps -gt 0 ]
then
    tempRadio=`expr $temp1 + $temp2 + $temp3`
    tempRadio=`expr $tempRadio / $successTemps`
fi
#if there aren't any status messages mark ok
if [ -z $adapterStatus ]
then
    adapterStatus="OK"
fi

#get 1m CPU load
load1m=`cat /proc/loadavg | cut -d' ' -f 0`
#get the uptime in seconds
uptime=`cat /proc/uptime | cut -d' ' -f 0`

# build the log message JSON
logMsg='\{'
logMsg=$logMsg'\"tempcpu\":'$tempCpu','
logMsg=$logMsg'\"tempradio\":'$tempRadio','
logMsg=$logMsg'\"adapterstatus\":\"'$adapterStatus'\",'
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