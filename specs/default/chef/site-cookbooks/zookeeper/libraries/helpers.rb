# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

module ZooKeeper
  class Helpers

    def self.find_members(node, cluster_UID)
      # Finds ensemble members, uses cached value if exists
      
      # the cluster object cannot be looked up any other way
      cluster = ::CycleCloudCluster.new(node)
      ensemble_size = node['zookeeper']['ensemble_size']
      
      if node['zookeeper']['members'].length == ensemble_size
        node['zookeeper']['members']
      else
        Chef::Log.info "Searching for ZooKeeper ensemble members..."
        # wait up to 200 seconds for the ensemble to become ready
        self.wait_for_ensemble(ensemble_size, 5, 40) do
          cluster.search(:clusterUID => cluster_UID).select do |n|
            not n['zookeeper'].nil? and n['zookeeper']['ready'] == true
          end
        end
        
        member_nodes = cluster.search(:clusterUID => cluster_UID).select do |n|
          !n['zookeeper'].nil? && n['zookeeper']['ready'] == true
        end
        
        members = member_nodes.map{|n| [n['zookeeper']['id'], n['cyclecloud']['instance']['ipv4']] }
        members.sort {|a,b| a[1] <=> b[1]}.reverse
        Chef::Log.info "ZooKeeper ensemble: #{members.inspect}"
        node.set['zookeeper']['members'] = members
        members
      end
    end
    
    def self.wait_for_ensemble(ensemble_size, sleep_time=10, retries=6, &block)
      results = block.call
      retries = 0
      while results.length < ensemble_size and retries < 6
        sleep sleep_time
        retries += 1
        results = block.call
        Chef::Log.info "Ensemble Size : #{ensemble_size}   Num Results: #{results.length}"
      end
      if retries >= 6
        raise Exception, "Timed out waiting for quorum"
      end
    
    end

    def self.ensemble_members(opts={})
      ensemble_members = cluster.search(opts) do |n|
        n[:zookeeper][:mode] == 'ensemble'
      end
      ensemble_ips = ensemble_members.map do |n|
        n[:cyclecloud][:instance][:ipv4]
      end
      ensemble_ips
    end
    
    def self.heap_size(total_memory)
      # calculate heap_size, which should never be larger than 50% of available RAM
      # should not be > 6 GB
      total_ram = total_memory.to_i
      heap_size = (total_ram * 0.4).to_i
      
      if heap_size > 6000000
        heap_size = 6000000
      end
      heap_size
    end

    def self.new_size(cpu_count)
      # calculate new_size, 50MB per cpu
      new_size = cpu_count.to_i * 50
    end
    
    def self.is_vpc?
      require 'net/http'
      my_mac = Net::HTTP.start('169.254.169.254').get('/latest/meta-data/network/interfaces/macs/').body.split[0]
      interface_details = Net::HTTP.start('169.254.169.254').get("/latest/meta-data/network/interfaces/macs/#{my_mac}").body
      if interface_details.split.include? 'vpc-id'
        true
      else
        false
      end
    end

  end
end
