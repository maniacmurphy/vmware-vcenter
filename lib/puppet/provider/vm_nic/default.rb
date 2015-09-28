# Copyright (C) 2014 VMware, Inc.
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet_x/vmware/util'
require File.join vmware_module.path, 'lib/puppet/property/vmware'
module_lib    = Pathname.new(__FILE__).parent.parent.parent.parent
require File.join module_lib, 'puppet_x/vmware/mapper'
require File.join module_lib, 'puppet/provider/vcenter'

Puppet::Type.type(:vm_nic).provide(:vm_nic, :parent => Puppet::Provider::Vcenter) do
  @doc =

  ##### begin common provider methods #####
  # besides name, these methods should look exactly the same for all providers
  # ensurable resources will have create, create_message, exist? and destroy

  map ||= PuppetX::VMware::Mapper.new_map('VirtualEthernetCardMap')

  define_method(:map) do
    @map ||= map
  end
  map.leaf_list.each do |leaf|
    Puppet.debug "Auto-discovered property [#{leaf.prop_name}] for type [#{self.name}]"

    define_method(leaf.prop_name) do
      Puppet.debug "#{leaf.path_is_now} set to #{PuppetX::VMware::Util::nested_value(config_is_now, leaf.path_is_now)}"
      value = PuppetX::VMware::Mapper::munge_to_tfsyms.call(
        PuppetX::VMware::Util::nested_value(config_is_now, leaf.path_is_now)
      )
    end

    define_method("#{leaf.prop_name}=".to_sym) do |value|
      PuppetX::VMware::Util::nested_value_set config_should, leaf.path_should, value, transform_keys=false
      @flush_required = true
    end
  end

  def exists?
    Puppet.debug "Evaluating '#{resource.inspect}' => #{resource.to_hash}"
    config_is_now
  end

  def config_should
    @config_should ||= is_now_hash config_is_now || {}
  end

  ##### begin standard provider methods #####
  # these methods should exist in all ensurable providers, but content will diff

  def config_is_now
    @config_is_now ||= ( @creating ? {} : map.annotate_is_now(virtual_network_card) )
  end

  def flush
    if @flush_required
      vm.ReconfigVM_Task(
        :spec => virtualMachineConfigSpec( :edit ) 
      ).wait_for_completion
    end
  end

  ##### begin misc provider specific methods #####
  # This section is for overrides of automatically-generated property getters and setters. Many
  # providers don't need any overrides. The most common use of overrides is to allow user input
  # of component names instead of object IDs (REST APIs) or Managed Object References (SOAP APIs).
  def portgroup
    case config_is_now[:backing].class.to_s 
    when 'VirtualEthernetCardDistributedVirtualPortBackingInfo'
      pg = find_dv_portgroup_by_key config_is_now[:backing][:port][:portgroupKey] 
      pg.name
    when 'VirtualEthernetCardNetworkBackingInfo'
      config_is_now[:backing][:deviceName]
    else
      raise Puppet::Error, "#{resource.inspect} returned unrecognized backing class: '#{config_is_now[:backing].class.to_s}'" 
    end
  end

  def portgroup=(value)
    case resource[:portgroup_type]
    when :distributed
      port = RbVmomi::VIM::DistributedVirtualSwitchPortConnection(
        :portgroupKey => distributedPortgroup.key,
        :switchUuid   => distributedPortgroup.config.distributedVirtualSwitch.uuid
      )
      config_should[:backing] = RbVmomi::VIM::VirtualEthernetCardDistributedVirtualPortBackingInfo(:port => port)
    when :standard
      config_should[:backing] = RbVmomi::VIM::VirtualEthernetCardNetworkBackingInfo(
        :deviceName => resource[:portgroup],
      )
    else
      raise Puppet::Error, "#{resource.inspect} missing parameter 'portgroup_type': valid values [distrubuted, standard]" 
    end
    @flush_required = true
  end

  def type
    case virtual_network_card.class.to_s
    when 'VirtualE1000'
      'e1000'
    when 'VirtualE1000e'
      'e1000e'
    when 'VirtualVmxnet2'
      'vmxnet2'
    when 'VirtualVmxnet3'
      'vmxnet3'
    else
      raise Puppet::Error, "#{resource.inspect} returned an unrecognized network card type"
    end
  end

  def type=(value)
    @newType = true
    @flush_required = true
  end
 
  ##### begin private provider specific methods section #####
  # These methods are provider specific and that can be private
  private

  def is_now_hash(config)
    if config_is_now.class.to_s != 'Hash'
      config_hash = { 
        :connectable => config[:connectable].props,
        :key         => config[:key]
      }
    end
    config_hash
  end
 
  def virtual_network_card
    vm.config.hardware.device.find { |d| d.deviceInfo.label.downcase == resource[:name].downcase }
  end

  def virtualMachineConfigSpec(operation)
    #if operation == :edit
    #  config_should[:key] = config_is_now[:key] 
    #end
#require 'pry'; binding.pry
    deviceSpec = map.objectify config_should
    if @newType
      nicType = resource[:type]
    else
      nicType = config_is_now.class.to_s
    end

    deviceSpec = 
     begin
        case nicType
        when :e1000, 'VirtualE1000'
          RbVmomi::VIM::VirtualE1000( deviceSpec.props )
        when :e1000e, 'VirtualE1000e'
          RbVmomi::VIM::VirtualE1000e( deviceSpec.props )
        when :vmxnet2, 'VirtualVmxnet2'
          RbVmomi::VIM::VirtualVmxnet2( deviceSpec.props )
        when :vmxnet3, 'VirtualVmxnet3'
          RbVmomi::VIM::VirtualVmxnet3( deviceSpec.props )
        end
     end

    spec = {
      :operation => operation,
      :device    => deviceSpec
    }

    virtualDeviceConfigSpec = RbVmomi::VIM::VirtualDeviceConfigSpec( spec )
    
    @virtualMachineConfigSpec = RbVmomi::VIM::VirtualMachineConfigSpec(
      :deviceChange => [ virtualDeviceConfigSpec ]
    )
  end

  def findvm(folder,vm_name)
    folder.children.each do |f|
      break if @vm_obj
      case f
      when RbVmomi::VIM::Folder
        findvm(f,vm_name)
      when RbVmomi::VIM::VirtualMachine
        @vm_obj = f if f.name == vm_name
      when RbVmomi::VIM::VirtualApp
        f.vm.each do |v|
          if v.name == vm_name
            @vm_obj = f
            break
          end
        end
      else
        puts "unknown child type found: #{f.class}"
        exit
      end
    end
    @vm_obj
  end

  def find_dv_portgroup_by_key(pg_key)
    datacenter.network.find {|n| n.key == pg_key if n.class.to_s == 'DistributedVirtualPortgroup' }
  end

  def distributedPortgroup
    @distributedPortgroup ||= datacenter.network.find {|n| n.name == resource[:portgroup] if n.class.to_s == 'DistributedVirtualPortgroup'} or raise Puppet::Error, "#{resource.inspect} unable to find distrubuted portgroup '#{resource[:portgroup]}' in datacenter '#{resource[:datacenter]}'."
  end
  
  def standardPortgroup
    @standardPortgroup ||= datacenter.network.find {|n| n.name == resource[:portgroup] if n.class.to_s == 'Network'} or raise Puppet::Error, "#{resource.inspect} unable to find standard portgroup '#{resource[:portgroup]}' in datacenter '#{resource[:datacenter]}'."
  end

  def datacenter(name=resource[:datacenter])
    vim.serviceInstance.find_datacenter(name) or raise Puppet::Error, "datacenter '#{resource[:datacenter]}' not found."
  end

  def vm
    @vm ||= findvm(datacenter.vmFolder, resource[:vm_name]) or raise Puppet::Error, "Unable to locate VM with the name '#{resource[:vm_name]}' "
  end

end
