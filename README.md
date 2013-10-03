craftbukkit-bootstrap
=====================

Bootstrap your craftbukkit server.

The kids want a working bukkitcraft server from : http://dl.bukkit.org/downloads/craftbukkit/

Yep, no problem, here are a copule scripts for ubuntu that can be run using your cloud account.
Use at your leasure and you owe me a beer if you make money with this.

Manual work:
* Update security groups or firewall to enable port 25565
* Add a DNS entry for the server to make it easier to find.
 
 
Setup:
clone this repository to the server : 

            git clone https://github.com/wenlock/craftbukkit-bootstrap.git
            mv ./craftbukkit-bootstrap ./craftbukkit
            cd ./craftbukkit
            ./download.sh
            ./start.sh install
            ./start.sh start
 
Have fun!
 
Uninstall:

            ./start.sh stop
            ./start.sh uninstall
            cd ..;rm -rf ./craftbukkit
 
Backups:
 
            ./start.sh backup
            echo "$(pwd)/start.sh backup" > /etc/cron.hourly/bukkit_backup
            chmod +x /etc/cron.hourly/bukkit_backup
            save or clone the craftbukkit/backups folder
 
## Features ##
### start.sh configuration ###
If you didn't setup these scripts with a birnami image, then you will likely need to make some updates.  We may move this
configuration out of the start.sh later to make it more flexible with other images.
Update the following parameters in start.sh if you are using different user:

           export USERNAME='bitnami'

### start.sh ###
Controls all functions for your minecraft bukkit server on the running system.
### start.sh install | uninstall ###
* Install start.sh as an init job (currently broken)
* Install some tools (hpcli)
* Install puppet cron jobs : backups and server date message.  Good place for other scheduled task for your minecraft server.
* Uninstall is still experimental and lacking a way to remove cron jobs.

### start.sh start|stop|restart ###
* controls the current run-time state of your server and saves work you have in progress.
* sends a helpfull message to users currently on the server.

### start.sh status ###
* check the current status for the server.

### start.sh command ###
* Issue a command on the running minecraft server as op.

### start.sh update ###
* This feature is still experimental, our goal is to provide a good way to update minecraft to the next release.  We currently ignore plugins.
* Check amazonaws download site and update minecraft_server.jar with a new version.





