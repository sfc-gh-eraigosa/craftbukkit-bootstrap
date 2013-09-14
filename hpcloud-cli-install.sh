#!/bin/bash
 _LOG=/dev/null
 _DL_SITE=https://docs.hpcloud.com/file
 RUBY_VERSION="1.9.1"
 HPFOG_VERSION=0.0.20
 HPCLOUD_VERSION=1.9.1

 function asRoot
 {
    if [ -z $1 ] ; then
	if [ ! $(id -u) -eq 0 ] ; then
             echo "sudo"
	fi
    else
	echo "sudo -u $1"
    fi
 }

 function CheckErrors
 {
   if [ ! $1 -eq 0 ] ; then
      echo "ERROR : $2 ( $1 )"
      exit $1
   fi
 }

 function ubuntu_install_apt
 {
  package_name=$1
  no_update=$2
  [ -z $no_update ] && no_update=0
  (dpkg -s $package_name | grep "Status: install ok installed") > $_LOG 2<&1
   if [ ! $? -eq 0 ] ; then
          echo "installing $package_name ... this may take a minute."
          [ $no_update -eq 0 ] && $(asRoot) aptitude update > $_LOG 2<&1
          $(asRoot) aptitude -y install $package_name > $_LOG 2<&1
          (dpkg -s $package_name | grep "Status: install ok installed") > $_LOG 2<&1
          CheckErrors $? " failed to install $package_name $(asRoot) aptitude -y install $package_name"
   fi
 }

 function gem_install
 {
    _package=$1
    _package_file=$2
    $(asRoot) gem list $_package|grep $_package > $_LOG 2<&1
    if [[ $? -eq 0 ]] ; then
    	echo "$_package already installed skipping"
    	return 0
    fi
		    
    if [[ ! -z $_package_file ]]; then
       $(asRoot) gem install $_package_file
    else
       $(asRoot) gem install $_package
    fi
 }

 function DownloadFile
 {
   DL_URL=$1
   DL_FILE=$2
   if [ ! -f $DL_FILE ] ; then
	wget --no-check-certificate $DL_URL -O $DL_FILE > $_LOG 2<&1
	CheckErrors $? "Unable to retrieve download $DL_URL"
   else
	echo "Using download file $DL_FILE"
   fi
 }
 SCRIPT_DIR=$(dirname $0)
 [[ ! -d $SCRIPT_DIR/bundles ]] && mkdir -p $SCRIPT_DIR/bundles
 ruby_packages="ruby${RUBY_VERSION}-dev rubygems ri \
                build-essential libssl-dev zlib1g-dev libxml2 \
                libxml2-dev libxslt1-dev libxslt1.1 sgml-base xml-core"
 for package in $ruby_packages
 do
    ubuntu_install_apt $package 1
 done
 gem_install "rdoc"
 $(asRoot) update-alternatives --install /usr/bin/ruby ruby /usr/bin/ruby${RUBY_VERSION} 400 \
          --slave   /usr/share/man/man1/ruby.1.gz ruby.1.gz            \
                    /usr/share/man/man1/ruby${RUBY_VERSION}.1.gz \
          --slave   /usr/bin/ri ri /usr/bin/ri${RUBY_VERSION}          \
          --slave   /usr/bin/irb irb /usr/bin/irb${RUBY_VERSION}       \
          --slave   /usr/bin/rdoc rdoc /usr/bin/rdoc${RUBY_VERSION}
                                           
 $(asRoot) update-alternatives --set ruby /usr/bin/ruby${RUBY_VERSION}
 $(asRoot) update-alternatives --set gem /usr/bin/gem${RUBY_VERSION}
 DownloadFile $_DL_SITE/hpfog-${HPFOG_VERSION}.gem $SCRIPT_DIR/bundles/hpfog-${HPFOG_VERSION}.gem
 gem_install "hpfog" $SCRIPT_DIR/bundles/hpfog-${HPFOG_VERSION}.gem
 DownloadFile $_DL_SITE/hpcloud-${HPCLOUD_VERSION}.gem $SCRIPT_DIR/bundles/hpcloud.gem
 gem_install "hpcloud" $SCRIPT_DIR/bundles/hpcloud.gem
 echo "configure hpcloud client with : account:setup"
 exit 0

