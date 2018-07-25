name             'zookeeper'
maintainer       'Cycle Computing LLC'
maintainer_email 'suppport@cyclecomputing.com'
license          'All rights reserved'
description      'Installs/Configures zookeeper'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

%w{ cyclecloud jdk jetpack }.each {|ckbk| depends ckbk }
