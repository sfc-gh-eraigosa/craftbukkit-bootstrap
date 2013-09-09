    
    import './puppet-java/manifests/init.pp'
    class{ 'puppet-java::java':
        version => '1.7.0_25',
        tarfile =>  $::architecture ? {
            'amd64' => 'jdk-7u25-linux-x64.tar.gz',
            default => 'jdk-7u25-linux-i586.tar.gz',
        },
        force   => false
    }

