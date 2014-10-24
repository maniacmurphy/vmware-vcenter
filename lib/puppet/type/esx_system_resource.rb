# Copyright (C) 2013 VMware, Inc.
Puppet::Type.newtype(:esx_system_resource) do
  @doc = "This resource allows the configuration of system resources of a host that are viewed und er the 'System Resource Allocation' section of the vSphere client"

  newparam(:host, :namevar => true) do
    desc "ESX hostname or ip address."
  end

  newproperty(:cpu_reservation) do
    desc "System resource CPU reservation in MHz"
    newvalues(/\d{1,}/)
  end

  newproperty(:cpu_expandable_reservation) do
    desc "Enable expandable reservation"
    newvalues(:true, :false)
  end

  newproperty(:cpu_limit) do
    desc "CPU limit in MHz"
    newvalues(/\d{1,}/)
  end

  newproperty(:cpu_unlimited) do
    desc "Enable unlimited CPU resources"
    newvalues(:true,:false)
  end
 
  newproperty(:mem_reservation) do
    desc "System resource memory reservation in MB"
    newvalues(/\d{1,}/)
  end
 
  newproperty(:mem_expandable_reservation) do
    desc "Enable expandable reservation"
    newvalues(:true, :false)
  end
 
  newproperty(:mem_limit) do
    desc "Memory limit in MB"
    newvalues(/\d{1,}/)
  end

   newproperty(:mem_unlimited) do
     desc "Enable unlimited Memory resources"
     newvalues(:true,:false)
   end
end
