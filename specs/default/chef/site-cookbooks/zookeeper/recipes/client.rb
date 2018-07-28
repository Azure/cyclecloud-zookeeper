#
# Cookbook Name:: zookeeper
# Recipe:: client
#
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
#
include_recipe 'zookeeper::default'

if node['zookeeper']['client'].nil? or node['zookeeper']['client']['cluster_name'].nil?
  cluster_UID = node[:cyclecloud][:cluster][:name]
else
  cluster_UID = node['zookeeper']['client']['cluster_name']
end

template '/etc/zookeeper/zoo.cfg' do
  source 'zoo.cfg.erb'
  owner 'zookeeper'
  variables lazy {
    {
      :members => ZooKeeper::Helpers.find_members(node, cluster_UID)
    }
  }
end

link '/opt/zookeeper/current/conf/zoo.cfg' do
  to '/etc/zookeeper/zoo.cfg'
  owner 'zookeeper'
  not_if { ::File.exists?('/opt/zookeeper/current/conf/zoo.cfg') }
end


template '/etc/profile.d/zookeeper.sh' do
  source 'zookeeper.sh.erb'
  variables lazy {
    {
      :members => ZooKeeper::Helpers.find_members(node, cluster_UID).map{ |n| n[1] }.join(','),
      :client_port => node['zookeeper']['client_port']
    }
  }
  mode 00755
end


