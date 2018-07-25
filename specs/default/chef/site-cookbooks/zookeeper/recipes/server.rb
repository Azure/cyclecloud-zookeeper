#
# Cookbook Name:: zookeeper
# Recipe:: server
#
# Copyright (C) 2016 Cycle Computing LLC
#
# All rights reserved - Do Not Redistribute
#
include_recipe 'zookeeper::default'

directory node['zookeeper']['data_dir'] do
  owner 'zookeeper'
  group 'zookeeper'
  recursive true
end

if node['zookeeper']['data_dir'] != "#{node['zookeeper']['home']}/data"
  link "#{node['zookeeper']['home']}/data" do
    to node['zookeeper']['data_dir']
    owner 'zookeeper'
    not_if { ::File.exists?("#{node['zookeeper']['home']}/data") }
  end
end

# Disable search caching to ensure that search gets new results on each retry
node.override['cyclecloud']['search']['caching']['disabled'] = true
node.override['zookeeper']['ready'] = true
node.override['zookeeper']['id'] = (node['cyclecloud']['instance']['ipv4'].gsub('.', '').to_i % 2**31).to_s

cluster.store_discoverable()

zk_template = template '/etc/zookeeper/zoo.cfg' do
  source 'zoo.cfg.erb'
  mode "0644"
  owner 'zookeeper'
  variables lazy {
    {
      :members =>  ZooKeeper::Helpers.find_members(node, node['cyclecloud']['cluster']['name'])
    }
  }
end

ruby_block "zoo_cfg_updated" do
  block do
    node.override['zookeeper']['members_changed'] = zk_template.updated_by_last_action?
  end
  notifies :restart, 'service[zookeeper]'
end

link '/opt/zookeeper/current/conf/zoo.cfg' do
  to '/etc/zookeeper/zoo.cfg'
  owner 'zookeeper'
  not_if { ::File.exists?('/opt/zookeeper/current/conf/zoo.cfg') }
end


file '/opt/zookeeper/current/data/myid' do
  content node['zookeeper']['id']
  owner 'zookeeper'
end


jvm_flags = ["-Xmx#{node['zookeeper']['xmx']}", "-Xms#{node['zookeeper']['xmx']}"]

template '/etc/init.d/zookeeper' do
  source 'zookeeper.init.erb'
  variables( :jvm_flags => jvm_flags )
  mode 0775
end

log "Zoo.cfg WAS updated by last action" do
  level :info
  only_if { node['zookeeper']['members_changed'] == true }
end

log "Zoo.cfg NOT updated by last action" do
  level :info
  only_if { not zk_template.updated_by_last_action? }
end


service 'zookeeper' do
  action [:enable, :start]
  # Only restart if the template changes (since it causes a re-connect of all clients)
  only_if { zk_template.updated_by_last_action? }
end

# Pull in the Jetpack LWRP
include_recipe 'jetpack'

monitoring_config = "#{node['cyclecloud']['home']}/config/service.d/zookeeper.json"
file monitoring_config do
  content <<-EOH
  {
    "system": "zookeeper",
    "cluster_name": "#{node['cyclecloud']['cluster']['name']}",
    "hostname": "#{node['cyclecloud']['instance']['public_hostname']}",
    "ports": {"ssh": 22, "zookeeper": 2181}
  }
  EOH
  mode "750"
  not_if { ::File.exist?(monitoring_config) }
end

jetpack_send "Registering ZooKeeper server for monitoring." do
  file monitoring_config
  routing_key "#{node['cyclecloud']['service_status']['routing_key']}.zookeeper"
end

