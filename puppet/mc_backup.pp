$mc_install_root='/home/bitnami/craftbukkit'
notice("installing hourly crontab for : /home/${::id}/craftbukkit/start.sh backup")
cron { 'mc_backup':
    command => "/bin/bash ${mc_install_root}/start.sh backup",
    minute  => '*/60',
    user    => "${::id}",
    ensure  => present,
  }

