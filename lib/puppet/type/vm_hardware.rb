# Copyright (C) 2013 VMware, Inc.
require 'pathname'
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet/property/vmware'

Puppet::Type.newtype(:vm_hardware) do
  @doc = "Manage a vCenter VM's virtual hardware settings. See http://pubs.vmware.com/vsphere-55/index.jsp#com.vmware.wssdk.apiref.doc/vim.vm.VirtualHardware.html for class details"


  newparam(:vm_name, :namevar => true) do
    desc "The name of the target VM"
  end

  newparam(:datacenter) do
    desc "The name of the datacenter hosting the target VM"
    newvalues(/\w/)
  end

  newproperty(:num_cpus) do
    desc "The number of vCPUs to assign to the target VM"
    newvalues(/\d/)
  end

  newproperty(:num_cores_per_socket) do
    desc "The number of cores per vCPU on the target VM"
    newvalues(/\d/)
  end

  newproperty(:memory_mb) do
    desc "The memory size to assign to the target VM"
  end

  newparam(:virtual_ich7m_present) do
    desc "Does this virtual machine have Virtual Intel I/O Controller Hub 7"
    newvalues(:true, :false)
  end

  newparam(:virtual_smc_present) do
    desc "Does this virtual machine have System Management Controller"
    newvalues(:true, :false)
  end
end
