# Copyright (C) 2014 VMware, Inc.
import 'data.pp'

transport { 'vcenter':
  username => $vcenter['username'],
  password => $vcenter['password'],
  server   => $vcenter['server'],
  options  => $vcenter['options'],
}

vm_vapp_property { 'newProperty':
  ensure           => present,
  datacenter_name  => 'dc1',
  vm_name          => 'vm1',
  category         => 'Application',
  description      => 'A test property created by Puppet',
  id               => 'testproperty',
  label            => 'Test Property',
  type             => 'string',
  userconfigurable => 'true',
  value            => 'new string',
  transport        => Transport['vcenter'],
}
