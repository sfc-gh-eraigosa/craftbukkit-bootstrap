CRAFT_BUKKIT_DATE=02633
CRAFT_BUKKIT_VER=1.7.9-R0.3
CRAFT_BUKKIT_REL=dev
FACTER_BIN=$(which facter)
if [ $? != 0 ] ; then
  echo "ERROR: please install facter first with gem install puppet"
  exit 1
fi
PUPPET_BIN=$(which puppet)
if [ $? != 0 ] ; then
  echo "ERROR: please install puppet first with gem install puppet"
  exit 1
fi

if [ "$1" != "" ] ; then
  CRAFT_BUKKIT_DATE=$1
fi
if [ "$2" != "" ] ; then
  CRAFT_BUKKIT_VER=$2
fi
function dosudo
{
  uname -s|grep -i win > /dev/null
  if [ $? != 0 ] ; then
     sudo "$@"
  else 
     eval "$@"
  fi
}

JAVA_VERSION=7u25
JAVA_BUILD=b15
pushd "$(dirname "$0")"
CURRENT_DIR=$(pwd)
[[ ! -d ./server ]] && mkdir server
[[ ! -d ./backup ]] && mkdir backup
if [[ ! -f ./server/craftbukkit_${CRAFT_BUKKIT_VER}.jar ]] ; then
wget "http://dl.bukkit.org/downloads/craftbukkit/get/${CRAFT_BUKKIT_DATE}_${CRAFT_BUKKIT_VER}/craftbukkit-${CRAFT_BUKKIT_REL}.jar" -O "./server/craftbukkit_${CRAFT_BUKKIT_VER}.jar"

fi
if [ ! -f "$CURRENT_DIR/server/craftbukkit.jar" ] ; then
  ln -s "$CURRENT_DIR/server/craftbukkit_${CRAFT_BUKKIT_VER}.jar" "$CURRENT_DIR/server/craftbukkit.jar"
fi

if [[ ! -d ./config ]] ; then
git clone https://github.com/openstack-infra/config
else
pushd ./config
git pull
popd
fi
# best puppet bootstrap script ever!
dosudo ./config/install_puppet.sh

# jdk deploy for java
[[ ! -d ./puppet ]] && mkdir puppet
PUPPET_MODULES=/etc/puppet/modules
pushd ./puppet

#if [[ ! -d ./puppet-java ]] ; then
#git clone https://github.com/objectcomputing/puppet-java
#fi

#if [[ ! -f ./puppet-java/jdk-${JAVA_VERSION}-linux-x64.tar.gz ]] ; then
#wget --no-cookies --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com" "http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION}-${JAVA_BUILD}/jdk-${JAVA_VERSION}-linux-x64.tar.gz" -O ./puppet-java/jdk-${JAVA_VERSION}-linux-x64.tar.gz
#fi


uname -s |grep -i win > /dev/null
if [ $? != 0 ] ; then
  dosudo puppet apply --modulepath=$PUPPET_MODULES ./java.pp 2>&1 | tee -a java_install.log
  dosudo rm -f /etc/alternatives/java
  dosudo ln -s /usr/lib/jvm/java-7-openjdk-amd64/jre/bin/java /etc/alternatives/java
else
  JAVA_BIN=$(which java)
  if [ $? != 0 ] ; then
      echo "ERROR : missing java, please install"
      exit 1
  fi
fi

popd


popd
