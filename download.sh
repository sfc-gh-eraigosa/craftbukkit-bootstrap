CRAFT_BUKKIT_DATE=02253
CRAFT_BUKKIT_VER=1.6.2-R0.1
JAVA_VERSION=7u25
JAVA_BUILD=b15
pushd "$(dirname "$0")"
CURRENT_DIR=$(pwd)
[[ ! -d ./server ]] && mkdir server
[[ ! -d ./backup ]] && mkdir backup
if [[ ! -f ./server/craftbukkit_${CRAFT_BUKKIT_VER}.jar ]] ; then
wget "http://dl.bukkit.org/downloads/craftbukkit/get/${CRAFT_BUKKIT_DATE}_${CRAFT_BUKKIT_VER}/craftbukkit-beta.jar" -O "./server/craftbukkit_${CRAFT_BUKKIT_VER}.jar"

ln -s $CURRENT_DIR/server/craftbukkit_${CRAFT_BUKKIT_VER}.jar $CURRENT_DIR/server/craftbukkit.jar
fi

if [[ ! -d ./config ]] ; then
git clone https://github.com/openstack-infra/config
else
pushd ./config
git pull
popd
fi
# best puppet bootstrap script ever!
sudo ./config/install_puppet.sh

# jdk deploy for java
[[ ! -d ./puppet ]] && mkdir puppet
PUPPET_MODULES=/etc/puppet/modules:$CURRENT_DIR/puppet
pushd ./puppet
wget --no-cookies --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com" "http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION}-${JAVA_BUILD}/jdk-${JAVA_VERSION}-linux-x64.tar.gz"
git clone https://github.com/objectcomputing/puppet-java
sudo puppet apply --modulepath=$PUPPET_MODULES ./java.pp
popd


popd
