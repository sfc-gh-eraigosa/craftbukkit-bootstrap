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
 
 
 
