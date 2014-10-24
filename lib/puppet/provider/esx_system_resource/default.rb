# Copyright (C) 2014 VMware, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'vcenter')

Puppet::Type.type(:esx_system_resource).provide(:esx_system_resource, :parent => Puppet::Provider::Vcenter) do

  def cpu_reservation
    systemResource.cpuAllocation.reservation
  end

  def cpu_reservation=(value)
    systemResource.cpuAllocation.reservation = value
    @update = true
  end

  def cpu_limit
    systemResource.cpuAllocation.limit
  end

  def cpu_limit=(value)
    systemResource.cpuAllocation.limit = value
    @update = true
  end

  def findSystemResource (systemResources)
    if systemResources.key.split('/')[-1] == resource[:name]
      @hostSystemResource = systemResources
    else
      systemResources.child.each do |child|
        findSystemResource(child)
      end
    end
  end

  def systemResource
    @systemResource ||= findSystemResource(host.systemResources)
  end

  def host
    @host ||= vim.searchIndex.FindByDnsName(:dnsName => resource[:host], :vmSearch => false) or raise Puppet::Error, "Host '#{resource[:host]}' not found"
  end
end
