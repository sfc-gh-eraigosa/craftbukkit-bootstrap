notice("installing hourly crontab for : /home/${::id}/craftbukkit/start.sh backup")
cron { 'mc_backup':
    command => "/home/${::id}/craftbukkit/start.sh backup",
    hour    => '*/1',
    user    => "${::id}",
    ensure  => present,
  }

