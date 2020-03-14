# asuswrt-monitor
Instructions for writing a logfile to do systems monitoring on AsusWRT


## Set up SSH Keys
I am using PowerShell in Windows10 as my console of choice. Start by generating SSH keys using `ssh-keygen` in Open SSH of Powershell
generate SSH powershell in windows 10. Instructions for enabling OpenSSH and using `ssh-keygen` can be found here: (https://www.techrepublic.com/blog/10-things/how-to-generate-ssh-keys-in-openssh-for-windows-10/)

## Configure SSH Settings in Your ASUS Router
I am writing this guide to accomodate the AiMesh system (a 'main' router and 'node' routers), although the instructions should be perfectly applicable for a single router without any nodes. Configure your router with the SSH keys generated earlier as described here: (https://www.htpcguides.com/enable-ssh-asus-routers-without-ssh-keys/)

## SSH into Your Main Router
Again, I am using PowerShell in Windows10 as my console of choice. Use the `ssh` command referencing your SSH key, your router's user name, and your router's SSH port with `ssh -i PATH\TO\SSHKEY -l USERNAME -p PORT ROUTERIP`. Mine looked like 'ssh -i .\ssh\asuswrt-pc-key -l username -p 22 192.168.1.1'

## Navigate to the persistent directory and add in scripts and directories
### Configure the script
Copy the asuswrt_monitor.sh script from this repository into a text editor
Modify the two constants at the top of the file 
`LOGHOST` should by the hostname or IP of the system where you wish to store logs
`LOGPATH` is the path on that system where you wish to store the logs
Copy the script from your text editor into your system clipboard
### Outdated busybox bash limitations
The ASUS routers have a really lightweight bash shell called busybox. It is missing many of the commands I expected (I am a linux novice), so it was a bit of a learning curve. I will provide very explicit instructions because it felt a lot like trial and error. I will likely need to follow my instructions at some point in the future, as well.
### Navigate to the persistent directory
Most of the router's file system resets every time it reboots, so any files you add or change will disappear. The only exceptions are those files contained in the /jffs/ directory. Navigate to the /jffs/ directory with `cd /jffs`
### Add the script to the directory with vi
Open the vi text editor to create a new file with `vi asuswrt_monitor.sh`
On your keyboard, press the `insert` key to switch vi into insert mode
With your mouse, `right click` to paste the contents of the system clipboard into vi
On your keyboard, press the `escape` key to switch vi into command mode
On your keyboard, type `:wq` to open the command, save the file, and quit
### Create the SSH storage directory
The following may be be simplified. I was working along with the instructions found here: https://forums.whirlpool.net.au/archive/9jw1vnn3. The author advocated for system linking SSH directories, so I followed his example for the directory structure. Since I am not worried about getting anywhere other than back to the host, the system linking won't provide much benefit.
Create the user directory with `mkdir root`
Create the ssh directory with `mkdir root/.ssh

## Use dropbear to generate SSH keys for the main router
Determine your system name with `nvram get computer_name`
Generate a SSH key into the jffs directory using the computer name with `dropbearkey -t rsa -f /jffs/root/.ssh/id_ROUTERNAME` mine looked like `dropbearkey -t rsa -f /jffs/root/.ssh/id_RT-ASUS5300-E380`
There will be an output in the console that reads 
```text
Public key portion is:
ssh-rsa AAAA....... USERNAME@ROUTERNAME
```
Copy the entire line of the console output by dragging over it with your mouse to highlight it, and then `right click` to store it in your keyboard
### Save the public key in your /jffs/ directory
Navigate to the ssh folder with `cd /jffs/root/.ssh`
Open the vi text editor to create a new file with `vi id_ROUTERNAME.pub`
On your keyboard, press the `insert` key to switch vi into insert mode
With your mouse, `right click` to paste the contents of the system clipboard into vi
On your keyboard, press the `escape` key to switch vi into command mode
On your keyboard, type `:wq` to open the command, save the file, and quit

## Add your public key to your logging device's authorized keys file
Generic instructions are available here: https://stackoverflow.com/questions/12392598/how-to-add-rsa-key-to-authorized-keys-file

## Test your SSH connection on the router
First, if you aren't already, SSH back into your router. Then use the ssh command to verify that you can connect to your logging host. Use the `ssh -i /jffs/root/.ssh/id_ROUTERNAME -l USERNAME HOSTNAME` mine looked like `ssh -i /jffs/root/.ssh/id_RT-ASUS5300-E380 -l username 192.168.1.109`
The SSH client should indicate that your host is not in the trusted hosts file. Type `yes` to continue connecting. This will also put the host in the trusted hosts file.

## Copy the trusted hosts file into the jffs directory for long term storage
The script will check to see if the trusted hosts file is current each time it runs. It does so such that the script doesn't fail after reboots. If the file is missing or doesn't contain the trusted host, it will be added. 
Use the copy command to copy the trusted hosts file into your jffs ssh directory `cp /tmp/home/root/.ssh/known_hosts /jffs/root/.ssh/cat_known_hosts`

## Test the script to ensure it populate the log file on your logging host as expected
Navigate to the jffs directory with `cd /jffs/`
Run the script with `./asuswrt_monitor`
Check your host machine, there should be a script in the directory you configured in the script named ROUTERNAME.log that contains the system monitor data











