# Copyright (C) 2014 VMware, Inc.
import 'data.pp'

transport { 'vcenter':
  username => $vcenter['username'],
  password => $vcenter['password'],
  server   => $vcenter['server'],
  options  => $vcenter['options'],
}

vm_vapp_property { 'newProperty':
  ensure           => absent,
  datacenter_name  => 'dc1',
  vm_name          => 'vm1',
  label            => 'Test Property',
  transport        => Transport['vcenter'],
}
