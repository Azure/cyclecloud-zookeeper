# zookeeper cookbook

This cookbook configures a basic zookeeper ensemble. Since ZooKeeper doesn't
really have a security model worth talking about, we use stunnel to connect zookeeper clients
to the zookeeper "ensemble". Each zookeeper member will only accept connections that use the same
SSL certificate as its own. For that reason you need to copy the cycle.pem file located in this
cookbook in order to connect to one of the zookeeper servers created by it.

# Requirements

To connect your server to the zookeeper ensemble, use the `zookeeper::client` recipe in this cookbook. 
Then configure your zookeeper client to connect to `127.0.0.1:2181`.

Here is how to install stunnel on mac os x

1. `brew install stunnel`
2. copy the `cycle.pem` file from the [cycle-stunnel cookbook](https://git.cyclecomputing.com/common-chef-repo/blob/1MC/cookbooks/cycle-stunnel/files/default/cycle.pem) into your local machine.
3. create the stunnel.conf file (see below)
4. Run `stunnel stunnel.conf`

```
# stunnel.conf
# foreground = yes  # uncomment this run stunnel in the fg, by default it daemonizes
cert = /Users/hitman/tmp/cycle.pem
CAfile = /Users/hitman/tmp/cycle.pem
CApath = /Users/hitman/tmp
verify = 2
sslVersion = TLSv1
client = yes
delay = no
pid = /Users/hitman/tmp/zookeeper.stunnel4.pid
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
debug = 4
TIMEOUTconnect = 10
sessionCacheSize = 1024
sessionCacheTimeout = 3600

[zookeeper]
accept  = localhost:2181
failover = rr
connect = zk1:2181
connect = zk2:2181
connect = zk3:2181
connect = zk4:2181
connect = zk5:2181
```

# Usage

This cookbook can be used to create a single node cluster or multiple node cluster. It uses blackboard 
to discover the other members of an ensemble.

The `zookeeper::default` recipe configures a zookeeper server and an stunnel connection
for it. The `zookeeper::client` recipe discovers the members of the zookeeper ensemble and configures
and stunnel client connection to the members of the ensemble. The stunnel client connection works in a round-robin
manner.

# Attributes

* `node[:zookeeper][:mode]` - whether to run in standalone or ensemble mode, valid options here are 'standalone' or 'ensemble'.

# Recipes

* `zookeeper::default` - 
* `zookeeper::ec2` - ec
* `zookeeper::jdk` - dirt simple installation of JDK7
* `zookeeper::client` - installs stunnel and configures it to connect to the ensemble of the current cluster

# Author

Author:: Cycle Computing LLC (<bryan.berry@cyclecoputing.com>)