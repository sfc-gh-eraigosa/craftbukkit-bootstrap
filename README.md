craftbukkit-bootstrap
=====================

Bootstrap your craftbukkit server.

The kids want a working bukkitcraft server from : http://dl.bukkit.org/downloads/craftbukkit/

Yep, no problem, here are a copule scripts for ubuntu that can be run using your cloud account.

Manual work:
* Update security groups or firewall to enable port 25565
* Add a DNS entry for the server to make it easier to find.
 
 
Setup:
 
 1 - clone this repository to the server : git clone https://github.com/wenlock/craftbukkit-bootstrap.git
 2 - mv ./craftbukkit-bootstrap ./craftbukkit
 3 - cd ./craftbukkit
 4 - ./download.sh
 5 - ./start.sh install
 6 - ./start.sh start
 
 Have fun!
 
Uninstall:

 1 - ./start.sh stop
 2 - ./start.sh uninstall
 3 - cd ..;rm -rf ./craftbukkit
 
 Backups:
 
 1 - ./start.sh backup
 2 - echo "$(pwd)/start.sh backup" > /etc/cron.hourly/bukkit_backup
 3 - chmod +x /etc/cron.hourly/bukkit_backup
 4 - save or clone the craftbukkit/backups folder
 
 
 
