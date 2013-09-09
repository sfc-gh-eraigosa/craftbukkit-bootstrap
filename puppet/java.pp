class stableJDK {
    class{ 'java':
        version => '1.7.0_21',
        tarfile =>  $::architecture ? {
            'amd64' => 'jdk-7u21-linux-x64.tar.gz',
            default => 'jdk-7u21-linux-i586.tar.gz',
        },
        force   => false
    }
}

class stableJRE {
    class{ 'java':
        version => '1.7.0_21',
        tarfile =>  $::architecture ? {
            'amd64' => 'jre-7u21-linux-x64.tar.gz',
            default => 'jre-7u21-linux-i586.tar.gz',
        },
        force   => false
    }
}
