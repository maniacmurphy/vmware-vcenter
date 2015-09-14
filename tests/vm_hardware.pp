import 'data.pp'

transport { 'vcenter':
  username => $vcenter['username'],
  password => $vcenter['password'],
  server   => $vcenter['server'],
  options  => $vcenter['options'],
}

vm_hardware { $vmname :
  datacenter      => $datacenter,
  num_cpus        => $num_cpus,
  num_cores_per_socket => $num_cores,
  memory_mb       => $memory,
  transport       => Transport['vcenter'],
} 
