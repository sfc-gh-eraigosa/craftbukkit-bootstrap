#!/bin/bash
pushd "$(dirname $0)" > /dev/null 2<&1
CURRENT_DIR=`pwd`
#settings
uname -s|grep -i win > /dev/null
if [ $? == 0 ] ; then
  export PS_BIN="procps"
  export PS_OPTS='-wwFAH'
else
  export PS_BIN="ps"
  export PS_OPTS='-efH'
fi


export SERVICE='craftbukkit.jar'
#export OPTIONS='nogui'
export USERNAME=$(whoami)
export WORLD='world'
export MCPATH=${CURRENT_DIR}/server
export BACKUPPATH=${CURRENT_DIR}/backup
export MAXHEAP=768
export MINHEAP=512
export HISTORY=768
export CPU_COUNT=1
export MC_JAR="${CURRENT_DIR}/server/craftbukkit.jar"
if [ -L "${MC_JAR}" ] ; then
  export MC_JAR_RUN=$(readlink "${MC_JAR}");
else
  export MC_JAR_RUN="${MC_JAR}";
fi
MC_JAR_FILE=$(basename "${MC_JAR_RUN}")
export INVOCATION="java -Xmx${MAXHEAP}M -Xms${MINHEAP}M -XX:+UseConcMarkSweepGC \
-XX:+CMSIncrementalPacing -XX:ParallelGCThreads=$CPU_COUNT -XX:+AggressiveOpts \
-jar $MC_JAR_FILE $OPTIONS"
echo $INVOCATION


ME=`whoami`
as_user() {
  if [ "$ME" == "$USERNAME" ] ; then
    bash -x -v -c "$1"
  else
    su - $USERNAME -c "$1"
  fi
}


#pushd server
#java -Xms512M -Xmx2G -jar ./craftbukkit.jar
#popd
mc_start() {
  $PS_BIN $PS_OPTS|grep -v grep |grep $MC_JAR_FILE > /dev/null
  if [ $? -eq 0 ] ; then
   echo "$SERVICE is already running!"
  else
    echo "Starting $SERVICE..."
    cd "$MCPATH"
    as_user "cd \"$MCPATH\" && screen -h $HISTORY -dmS minecraft $INVOCATION"
    sleep 10

    $PS_BIN $PS_OPTS|grep -v grep |grep $MC_JAR_FILE > /dev/null
    if [ $? -eq 0 ] ; then
      echo "$SERVICE is now running."
    else
      echo "Error! Could not start $SERVICE!"
    fi
  fi
}

mc_saveoff() {
  $PS_BIN $PS_OPTS|grep -v grep |grep $MC_JAR_FILE > /dev/null
  if [ $? -eq 0 ] ; then
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
  $PS_BIN $PS_OPTS|grep -v grep |grep $MC_JAR_FILE > /dev/null
  if [ $? -eq 0 ] ; then
    echo "$SERVICE is running... re-enabling saves"
    as_user "screen -p 0 -S minecraft -X eval 'stuff \"save-on\"\015'"
    as_user "screen -p 0 -S minecraft -X eval 'stuff \"say SERVER BACKUP ENDED. Server going read-write...\"\015'"
  else
    echo "$SERVICE is not running. Not resuming saves."
  fi
}

mc_stop() {
  $PS_BIN $PS_OPTS|grep -v grep |grep $MC_JAR_FILE > /dev/null
  if [ $? -eq 0 ] ; then
    echo "Stopping $SERVICE"
    as_user "screen -p 0 -S minecraft -X eval 'stuff \"say SERVER SHUTTING DOWN IN 10 SECONDS. Saving map...\"\015'"
    as_user "screen -p 0 -S minecraft -X eval 'stuff \"save-all\"\015'"
    sleep 10
    as_user "screen -p 0 -S minecraft -X eval 'stuff \"stop\"\015'"
    sleep 7
  else
    echo "$SERVICE was not running."
  fi
  $PS_BIN $PS_OPTS|grep -v grep |grep $MC_JAR_FILE > /dev/null
  if [ $? -eq 0 ] ; then
    echo "Error! $SERVICE could not be stopped."
  else
    echo "$SERVICE is stopped."
  fi
}

mc_update() {
  CB_DL_URL=http://dl.bukkit.org

  $PS_BIN $PS_OPTS|grep -v grep |grep $MC_JAR_FILE > /dev/null
  if [ $? -eq 0 ] ; then
    echo "$SERVICE is running! Will not start update."
  else
    as_user "wget -q -O /tmp/rb.txt $CB_DL_URL/downloads/craftbukkit/list/rb/"
    DL_URL=${CB_DL_URL}$(grep craftbukkit.jar /tmp/rb.txt|grep downloads|head -1|awk -F'"' '{print $2}'|tr -d '\n')

    as_user "pushd \"$MCPATH\" && wget -q -O \"$MCPATH/craftbukkit.jar.update\" ${DL_URL}"
    if [ -f "$MCPATH/craftbukkit.jar.update" ]
    then
      if `diff "$MCPATH/$SERVICE" "$MCPATH/craftbukkit.jar.update" >/dev/null`
      then
        echo "You are already running the latest version of $SERVICE."
      else
        as_user "mv \"$MCPATH/craftbukkit.jar.update\" \"$MCPATH/$SERVICE\""
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
   HPCLOUD_BIN=$(which hploud)
   if [ $? != 0 ] ; then
       echo "WARNING: unable to continue hpcloud backup, missing cli"
       return
   fi
   older_backup=$(((pushd "$BACKUPPATH" > /dev/null 2<&1;find . -mtime +3 -type f|sed 's/^\.\///g'|tail -1;popd >/dev/null 2<&1) && (pushd "$BACKUPPATH" > /dev/null 2<&1;ls -t | tail -1;popd > /dev/null 2<&1))|sort -g | tail -1)
   pushd "$BACKUPPATH" > /dev/null 2<&1
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
     pushd "$BACKUPPATH" > /dev/null 2<&1
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
   if [ -d "$BACKUPPATH" ] ; then
      pushd "$BACKUPPATH"
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
  [[ ! -L /etc/init.d/bukkit ]] && sudo ln -s "$CURRENT_DIR/start.sh" /etc/init.d/bukkit
  sudo chmod +x /etc/init.d/bukkit
  sudo update-rc.d bukkit defaults 98 02
  chmod +x "$CURRENT_DIR/hpcloud-cli-install.sh"
  "$CURRENT_DIR/hpcloud-cli-install.sh"
# install crontab
  PUPPET_MODULES=/etc/puppet/modules
  sudo puppet apply --modulepath=$PUPPET_MODULES ./puppet/mc_backup.pp 
  sudo puppet apply --modulepath=$PUPPET_MODULES ./puppet/mc_showdate.pp 
}
#
mc_uninstall() {
  find /etc/rc?.d -name ???bukkit|xargs -i sudo rm -f {}
  sudo rm -f /etc/init.d/bukkit
}
mc_command() {
  command="$1";
  $PS_BIN $PS_OPTS|grep -v grep |grep $MC_JAR_FILE > /dev/null
  if [ $? -eq 0 ] ; then
    pre_log_len=`wc -l "$MCPATH/server.log" | awk '{print $1}'`
    echo "$SERVICE is running... executing command"
    as_user "screen -p 0 -S minecraft -X eval 'stuff \"$command\"\015'"
    sleep .1 # assumes that the command will run and print to the log file in less than .1 seconds
    # print output
    tail -n $[`wc -l "$MCPATH/server.log" | awk '{print $1}'`-$pre_log_len] "$MCPATH/server.log"
  fi
}
#
#set -x -v
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
    if pgrep -u "$USERNAME" -f $SERVICE > /dev/null
    then
      echo "$SERVICE is running."
    else
      echo "$SERVICE is not running."
    fi
    ;;
  command)
    if [ $# -gt 1 ]; then
      shift;
      mc_command "$*";
    else
      echo "Must specify server command \(try \'help\'\?\)";
    fi
    ;;
  *)
    echo "Usage: $0 {start|stop|update|backup|status|restart|install|uninstall|command 'server command'}"
    exit 1
  ;;
esac

popd
exit 0

