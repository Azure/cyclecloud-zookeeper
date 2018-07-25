#
# Cookbook Name:: zookeeper
# Recipe:: default
#
# Copyright (C) 2013 Cycle Computing LLC
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'cyclecloud'

mirror = "http://apache.mirrors.tds.net/zookeeper/"
version = '3.4.12'
checksum = 'c686f9319050565b58e642149cb9e4c9cc8c7207aacc2cb70c5c0672849594b9'
zk_tarball = "zookeeper-#{version}.tar.gz"
zk_url = "#{mirror}/zookeeper-#{version}/#{zk_tarball}"

zookeeper_home = '/opt/zookeeper/current'
zookeeper_prefix = File.dirname(zookeeper_home)
zookeeper_install_path = "#{zookeeper_prefix}/zookeeper-#{version}"

heap_size = ZooKeeper::Helpers.heap_size(node['memory']['total'])

node.override['zookeeper']['xmx'] = "#{heap_size}K"
node.override['zookeeper']['xms'] = "#{heap_size}K"

user 'zookeeper' do
  shell '/bin/bash'
end

%w{ /opt/zookeeper /opt/zookeeper/logs }.each do |dir|
  directory dir do
    owner 'zookeeper'
    mode 0775
    not_if { ::File.exists?(dir) }
  end
end

zookeeper_installer_path = "#{Chef::Config[:file_cache_path]}/#{zk_tarball}"
remote_file zookeeper_installer_path do
  source zk_url
  checksum checksum
  mode 0755
  not_if { ::File.exists?(zookeeper_installer_path) }
  action :create_if_missing
end

directory zookeeper_prefix do
  mode 0755
  recursive true
end

# See: https://conda.io/docs/user-guide/install/macos.html#install-macos-silent
execute 'extract zookeeper' do
  command "tar xzf #{zookeeper_installer_path} -C #{zookeeper_prefix}"
  not_if { File.directory?(zookeeper_home) }
end


link zookeeper_home do
  to zookeeper_install_path
  owner 'zookeeper'
  not_if { ::File.exists?(zookeeper_home) }
end

link "#{zookeeper_home}/logs" do
  to "#{zookeeper_prefix}/logs"
  owner 'zookeeper'
  not_if { ::File.exists?("#{zookeeper_prefix}/logs") }
end

directory '/etc/zookeeper' do
  owner 'zookeeper'
  group 'zookeeper'
end

template '/etc/zookeeper/log4j.properties' do
  source 'log4j.properties.erb'
  owner 'zookeeper'
end

link "#{zookeeper_home}/conf/log4j.properties" do
  to '/etc/zookeeper/log4j.properties'
  owner 'zookeeper'
  not_if { ::File.exists?("#{zookeeper_home}/conf/log4j.properties") }
end
