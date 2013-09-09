pushd "$(dirname "$0")"
[[ ! -d ./server ]] && mkdir server
wget "http://dl.bukkit.org/downloads/craftbukkit/get/02253_1.6.2-R0.1/craftbukkit-beta.jar" -O "./server/craftbukkit.jar"
popd
