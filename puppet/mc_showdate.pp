#
# We're going to show the date on minecraft every 5minutes
$mc_showdate="Its $(date) ... I still love minecraft."
$mc_install_root='/home/bitnami/craftbukkit'
notice("installing periodic date : ${mc_install_root}/start.sh command")
cron { 'mc_showdate':
    command => "/bin/bash ${mc_install_root}/start.sh command say \"${mc_showdate}\"",
    minute   => '*/5',
    user    => "${::id}",
    ensure  => present,
  }

