#!/bin/sh
#the following line ensures the script only runs once per reboot cycle
mkdir /home/root/.asusrouterlock || exit
#after reboot, the scripts are made unexecutable, this allows them to execute
chmod 700 /jffs/*sh
#set the cron to run the system monitor every minute
cru a SYSMNTR "* * * * * /jffs/asuswrt_monitor.sh"
#run the monitor one time to get started
/jffs/asuswrt_monitor.sh
#set the USB mount on reboot script to THIS script
nvram set script_usbmount="sh /jffs/exec_at_reboot.sh"
#save the nvram variable
nvram commit