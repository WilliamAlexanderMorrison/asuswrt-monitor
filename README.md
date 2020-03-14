# asuswrt-monitor
Instructions for having AsusWRT write a system monitoring logfile to another system on the network.

## Set up SSH Keys
***Note: I am using PowerShell in Windows 10 to write these instructions.*** 
  * Start by generating SSH keys using `ssh-keygen` in Open SSH 
    * Instructions for enabling OpenSSH and using `ssh-keygen` can be found here: https://www.techrepublic.com/blog/10-things/how-to-generate-ssh-keys-in-openssh-for-windows-10/

## Configure SSH Settings in Your ASUS Router
  * Configure your router with the SSH keys generated earlier as described here: https://www.htpcguides.com/enable-ssh-asus-routers-without-ssh-keys/

## SSH into Your Main Router
  * Use the `ssh` command while referencing your SSH key, your router's user name, and your router's SSH port with `ssh -i PATH\TO\SSHKEY -l USERNAME -p PORT ROUTERIP` 
    * Mine looked like `ssh -i .\ssh\asuswrt-pc-key -l username -p 22 192.168.1.1`

## Configure the script
  * Copy the `asuswrt_monitor.sh` script from this repository into a text editor
  * Modify the two constants at the top of the file
    * `LOGHOST` is the hostname or IP of the system where you wish to store logs
    * `LOGPATH` is the path on that system where you wish to store the logs
  * Copy the script from your text editor into your system clipboard

## Navigate to the persistent directory and add in scripts and directories
***Note: Shell limitations*** The ASUS routers have a really lightweight bash shell called busybox. It is missing many of the commands I expected (I am a linux novice), so it was a bit of a learning curve. I will provide very explicit instructions because it felt a lot like trial and error. I will likely need to follow my instructions at some point in the future, as well.
### Navigate to the persistent directory and add the script with vi
***Note: Most of the router's file system resets every time it reboots.*** Any files you add or change will disappear, unless those files are contained in the persistent `/jffs/` directory. 
  * Navigate to the `/jffs/` directory with `cd /jffs`
  * Open the vi text editor to create a new file with `vi asuswrt_monitor.sh`
  * Press the `insert` key on your keyboard to switch vi into insert mode
  * `Right click` your mouse to paste the contents of the system clipboard into vi
  * Press the `escape` key on your keyboard to switch vi into command mode
  * Type `:wq` to open the command, save the file, and quit
  * Make the shell script executable with `chmod 700 asuswrt_monitor.sh`
### Create the SSH storage directory
  * Navigate to the `/jffs/` directory with `cd /jffs`
  * Create the user directory with `mkdir root`
  * Create the ssh directory with `mkdir root/.ssh

## Use dropbear to generate SSH keys for the main router
  * Determine your system name with `nvram get computer_name`
  * Generate a SSH key into the `/jffs/` directory using the computer name with `dropbearkey -t rsa -f /jffs/root/.ssh/id_ROUTERNAME`
    * Mine looked like `dropbearkey -t rsa -f /jffs/root/.ssh/id_RT-ASUS5300-E380`
  * There will be an output in the console that reads 
```text
Public key portion is:
ssh-rsa AAAA....... USERNAME@ROUTERNAME
```
  * Copy the entire line starting with `ssh-rsa`
    * Drag over the line with your mouse to highlight it, and then `right click` to store it in your system clipboard
### Save the public key in the persistent directory
  * Navigate to the ssh folder with `cd /jffs/root/.ssh`
  * Open the vi text editor to create a new file with `vi id_ROUTERNAME.pub`
    * Mine looked like `vi id_RT-ASUS-5300-E380.pub`
  * Press the `insert` key on your keyboard to switch vi into insert mode
  * `Right click` your mouse to paste the contents of the system clipboard into vi
  * Press the `escape` key on your keyboard to switch vi into command mode
  * Type `:wq` to open the command, save the file, and quit

## Add the public key to your logging device's authorized keys file
On your system which will be holding the logs, add the public key file you just saved into the logging system's authorized keys file
  * Generic instructions are available here: https://stackoverflow.com/questions/12392598/how-to-add-rsa-key-to-authorized-keys-file

## Test your SSH connection on the router
  * SSH into your router. 
  * Verify that you can connect to your logging system with `ssh -i /jffs/root/.ssh/id_ROUTERNAME -l USERNAME HOSTNAME`
    * Mine looked like `ssh -i /jffs/root/.ssh/id_RT-ASUS5300-E380 -l username 192.168.1.109`
  * The SSH client should indicate that your host is not in the trusted hosts file. Type `yes` to continue connecting. 
    * This will also add the host in the trusted hosts file.

## Copy the trusted hosts file into the jffs directory for long term storage
  * The trusted hosts file must be current or the 'your host is not in the trusted hosts' message will cause the script to fail
  * Every time the router reboots, the trusted hosts file is removed
  * So, we need to store the trusted hosts file in the persistent storage so that the script can reference it
    * If the file is missing after a reboot, the script will update it with the stored trusted hosts file
  * Use the copy command to copy the trusted hosts file into your jffs ssh directory `cp /tmp/home/root/.ssh/known_hosts /jffs/root/.ssh/cat_known_hosts`

## Test the script to ensure it populate the log file on your logging host as expected
  * Navigate to the jffs directory with `cd /jffs/`
  * Run the script with `./asuswrt_monitor`
  * Check your host machine, there should be a log file in the desired directory named ROUTERNAME.log that contains the system monitor data
  
## Ensure everything turns back on after every reboot
***Note: fighting back after reboots*** In addition to everything not in the `/jffs/` directory being removed all of the files in the `/jffs/` directory have their permissions changed so that they are no longer executable
  * There is one workaround to run scripts to repopulate non `/jffs/` directories and files and re-permission scripts
    * Whenever a USB device is mounted, which automatically happens after each reboot, whatever script is included in the `script_usbmount` NVRAM variable is run
    * Provided that a USB drive is connected to your router, this script can return the system to expected behavior for the logging script
### Navigate to the persistent directory and in the reboot script  
  * Copy the `exec_at_reboot.sh` script from this repository into a text editor
  * Navigate to the `/jffs/` directory with `cd /jffs`
  * Open the vi text editor to create a new file with `vi exec_at_reboot.sh`
  * Press the `insert` key on your keyboard to switch vi into insert mode
  * `Right click` your mouse to paste the contents of the system clipboard into vi
  * Press the `escape` key on your keyboard to switch vi into command mode
  * Type `:wq` to open the command, save the file, and quit
  * Make the shell script executable with `chmod 700 exec_at_reboot.sh`
  * Execute the shell script to set the NVRAM variable with `./exec_at_reboot.sh`
  * Verify the cron tab is loaded with `cru -l`
    * It should read `* * * * * /jffs/asuswrt_monitor.sh #SYSMNTR#`
    
    
    
    
    
## Clean up your logs
  * Logs will be generated once a minute for each router in your system
  * Consider automating your logging system to delete old logs
    * Generic instructions can be found here: https://unix.stackexchange.com/a/310873
