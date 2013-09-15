#!/bin/bash
pushd "$(dirname $0)" > /dev/null 2<&1
CURRENT_DIR=`pwd`
#settings

export SERVICE='craftbukkit.jar'
#export OPTIONS='nogui'
export USERNAME='bitnami'
export WORLD='world'
export MCPATH=${CURRENT_DIR}/server
export BACKUPPATH=${CURRENT_DIR}/backup
export MAXHEAP=768
export MINHEAP=512
export HISTORY=768
export CPU_COUNT=1
export INVOCATION="java -Xmx${MAXHEAP}M -Xms${MINHEAP}M -XX:+UseConcMarkSweepGC \
-XX:+CMSIncrementalPacing -XX:ParallelGCThreads=$CPU_COUNT -XX:+AggressiveOpts \
-jar $SERVICE $OPTIONS"

ME=`whoami`
as_user() {
  if [ $ME == $USERNAME ] ; then
    bash -c "$1"
  else
    su - $USERNAME -c "$1"
  fi
}


#pushd server
#java -Xms512M -Xmx2G -jar ./craftbukkit.jar
#popd
mc_start() {
  if  pgrep -u $USERNAME -f $SERVICE > /dev/null
  then
    echo "$SERVICE is already running!"
  else
    echo "Starting $SERVICE..."
    cd $MCPATH
    as_user "cd $MCPATH && screen -h $HISTORY -dmS minecraft $INVOCATION"
    sleep 7
    if pgrep -u $USERNAME -f $SERVICE > /dev/null
    then
      echo "$SERVICE is now running."
    else
      echo "Error! Could not start $SERVICE!"
    fi
  fi
}

mc_saveoff() {
  if pgrep -u $USERNAME -f $SERVICE > /dev/null
  then
    echo "$SERVICE is running... suspending saves"
    as_user "screen -p 0 -S minecraft -X eval 'stuff \"say SERVER BACKUP STARTING. Server going readonly...\"\015'"
    as_user "screen -p 0 -S minecraft -X eval 'stuff \"save-off\"\015'"
    as_user "screen -p 0 -S minecraft -X eval 'stuff \"save-all\"\015'"
    sync
    sleep 10
  else
    echo "$SERVICE is not running. Not suspending saves."
  fi
}

mc_saveon() {
  if pgrep -u $USERNAME -f $SERVICE > /dev/null
  then
    echo "$SERVICE is running... re-enabling saves"
    as_user "screen -p 0 -S minecraft -X eval 'stuff \"save-on\"\015'"
    as_user "screen -p 0 -S minecraft -X eval 'stuff \"say SERVER BACKUP ENDED. Server going read-write...\"\015'"
  else
    echo "$SERVICE is not running. Not resuming saves."
  fi
}

mc_stop() {
  if pgrep -u $USERNAME -f $SERVICE > /dev/null
  then
    echo "Stopping $SERVICE"
    as_user "screen -p 0 -S minecraft -X eval 'stuff \"say SERVER SHUTTING DOWN IN 10 SECONDS. Saving map...\"\015'"
    as_user "screen -p 0 -S minecraft -X eval 'stuff \"save-all\"\015'"
    sleep 10
    as_user "screen -p 0 -S minecraft -X eval 'stuff \"stop\"\015'"
    sleep 7
  else
    echo "$SERVICE was not running."
  fi
  if pgrep -u $USERNAME -f $SERVICE > /dev/null
  then
    echo "Error! $SERVICE could not be stopped."
  else
    echo "$SERVICE is stopped."
  fi
}

mc_update() {
  if pgrep -u $USERNAME -f $SERVICE > /dev/null
  then
    echo "$SERVICE is running! Will not start update."
  else
    MC_SERVER_URL=http://s3.amazonaws.com/MinecraftDownload/launcher/minecraft_server.jar?v=`date | sed "s/[^a-zA-Z0-9]/_/g"`
    as_user "cd $MCPATH && wget -q -O $MCPATH/minecraft_server.jar.update $MC_SERVER_URL"
    if [ -f $MCPATH/minecraft_server.jar.update ]
    then
      if `diff $MCPATH/$SERVICE $MCPATH/minecraft_server.jar.update >/dev/null`
      then
        echo "You are already running the latest version of $SERVICE."
      else
        as_user "mv $MCPATH/minecraft_server.jar.update $MCPATH/$SERVICE"
        echo "Minecraft successfully updated."
      fi
    else
      echo "Minecraft update could not be downloaded."
    fi
  fi
}

mc_world_backup() {
   BACKUP_FILE=$2
   as_user "tar -C \"$MCPATH\" -rf \"$BACKUP_FILE\" ${1}"
}

mc_backup_hpcloud() {
   # keep the last 3 backups and a +1 week oldest backup on CDN
   older_backup=$(((pushd $BACKUPPATH > /dev/null 2<&1;find . -mtime +3 -type f|sed 's/^\.\///g'|tail -1;popd >/dev/null 2<&1) && (pushd $BACKUPPATH > /dev/null 2<&1;ls -t | tail -1;popd > /dev/null 2<&1))|sort -g | tail -1)
   pushd $BACKUPPATH > /dev/null 2<&1
   last_few_backups=$(ls -tr |tail -1|sort | uniq -u)
   popd > /dev/null 2<&1
   echo "cleaning up all backups on offline storage"
   hpcloud ls :mcbackup|xargs -i hpcloud rm :mcbackup/{}

   hpcloud account:verify hp > /dev/null 2<&1
   if [[ $? -eq 0 ]] ; then
      echo "account verification passed."
      hpcloud list|grep mcbackup
      if [[ ! $? -eq 0 ]] ; then
           hpcloud containers:add mcbackup
      fi
      pushd $BACKUPPATH > /dev/null 2<&1
      echo "Last few backups $last_few_backups"
      for backup_tar in $last_few_backups
      do
           if [[ -f $backup_tar ]] ; then
              echo "offsite save of $backup_tar"
              hpcloud cp $backup_tar :mcbackup
           fi
      done
      if [[ -f $older_backup ]] ; then
         echo "saving older backup $older_backup"
         hpcloud cp $older_backup :mcbackup
      fi
      
   else
      echo "to backup with hpcloud run : hpcloud account:setup"
   fi
}

mc_backup() {

# remove the oldes 60 files
   if [ -d $BACKUPPATH ] ; then
      pushd $BACKUPPATH
      # clean up anything older than 3 days old
      (ls -t|head -n 72;ls)|sort|uniq -u|xargs rm
      popd
   fi

   mc_saveoff

   NOW=`date "+%Y-%m-%d_%Hh%M"`
   BACKUP_FILE="$BACKUPPATH/${WORLD}_${NOW}.tar"

   echo "Backing up $SERVICE"
   #as_user "cp \"$MCPATH/$SERVICE\" \"$BACKUPPATH/minecraft_server_${NOW}.jar\""
   as_user "tar -C \"$MCPATH\" -cf \"$BACKUP_FILE\" $SERVICE"

   echo "Backing up minecraft plugins..."
   as_user "tar -C \"$MCPATH\" -rf \"$BACKUP_FILE\" plugins"

   echo "Backing up minecraft worlds..."
   #as_user "cd $MCPATH && cp -r $WORLD $BACKUPPATH/${WORLD}_`date "+%Y.%m.%d_%H.%M"`"
   pushd "$MCPATH"
   for world in $(find . -maxdepth 2 -name session* |sed 's/\/session\.lock//g')
   do
       echo "Working on world $world"
       mc_world_backup $world $BACKUP_FILE
   done
   popd > /dev/null 2<&1

   mc_saveon

   echo "Compressing backup..."
   as_user "gzip -f \"$BACKUP_FILE\""

   mc_backup_hpcloud
   echo "Done."
}

mc_install() {
  [[ ! -L /etc/init.d/bukkit ]] && sudo ln -s $CURRENT_DIR/start.sh /etc/init.d/bukkit
  sudo chmod +x /etc/init.d/bukkit
  sudo update-rc.d bukkit defaults 98 02
  chmod +x $CURRENT_DIR/hpcloud-cli-install.sh
  $CURRENT_DIR/hpcloud-cli-install.sh
# install crontab
  PUPPET_MODULES=/etc/puppet/modules
  sudo puppet apply --modulepath=$PUPPET_MODULES ./puppet/mc_backup.pp 
}

mc_uninstall() {
  find /etc/rc?.d -name ???bukkit|xargs -i sudo rm -f {}
  sudo rm -f /etc/init.d/bukkit
}
mc_command() {
  command="$1";
  if pgrep -u $USERNAME -f $SERVICE > /dev/null
  then
    pre_log_len=`wc -l "$MCPATH/server.log" | awk '{print $1}'`
    echo "$SERVICE is running... executing command"
    as_user "screen -p 0 -S minecraft -X eval 'stuff \"$command\"\015'"
    sleep .1 # assumes that the command will run and print to the log file in less than .1 seconds
    # print output
    tail -n $[`wc -l "$MCPATH/server.log" | awk '{print $1}'`-$pre_log_len] "$MCPATH/server.log"
  fi
}

#Start-Stop here
case "$1" in
  start)
    mc_start
    ;;
  stop)
    mc_stop
    ;;
  restart)
    mc_stop
    mc_start
    ;;
  update)
    mc_stop
    mc_backup
    mc_update
    mc_start
    ;;
  backup)
    mc_backup
    ;;
  install)
    mc_install
    ;;
  uninstall)
    mc_uninstall
    ;;
  status)
    if pgrep -u $USERNAME -f $SERVICE > /dev/null
    then
      echo "$SERVICE is running."
    else
      echo "$SERVICE is not running."
    fi
    ;;
  command)
    if [ $# -gt 1 ]; then
      shift
      mc_command "$*"
    else
      echo "Must specify server command (try 'help'?)"
    fi
    ;;

  *)
  echo "Usage: $0 {start|stop|update|backup|status|restart|install|uninstall|command \"server command\"}"
  exit 1
  ;;
esac

popd
exit 0

