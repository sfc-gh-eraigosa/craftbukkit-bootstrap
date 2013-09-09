CRAFT_BUKKIT_DATE=02253
CRAFT_BUKKIT_VER=1.6.2-R0.1
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
./config/install_puppet.sh
sudo puppet apply ./puppet/java.pp

popd
