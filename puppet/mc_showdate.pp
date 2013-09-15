#
# We're going to show the date on minecraft every 5minutes
$mc_showdate="It's \$(date), I still ove minecraft."
$mc_install_root='/home/bitnami/craftbukkit'
notice("installing periodic date : ${mc_install_root}/start.sh command")
cron { 'mc_showdate':
    command => "/bin/bash ${mc_install_root}/start.sh command '${mc_showdate}'",
    hour    => '*/5',
    user    => "${::id}",
    ensure  => present,
  }

