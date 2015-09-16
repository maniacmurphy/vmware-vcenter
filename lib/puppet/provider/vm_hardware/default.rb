# Copyright (C) 2014 VMware, Inc.
vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
require File.join vmware_module.path, 'lib/puppet_x/vmware/util'
require File.join vmware_module.path, 'lib/puppet/property/vmware'
module_lib    = Pathname.new(__FILE__).parent.parent.parent.parent
require File.join module_lib, 'puppet_x/vmware/mapper'
require File.join module_lib, 'puppet/provider/vcenter'

Puppet::Type.type(:vm_hardware).provide(:vm_hardware, :parent => Puppet::Provider::Vcenter) do
  @doc = "Manage a vCenter VM's virtual hardware settings. See http://pubs.vmware.com/vsphere-55/index.jsp#com.vmware.wssdk.apiref.doc/vim.vm.VirtualHardware.html for class details"

  ##### begin common provider methods #####
  # besides name, these methods should look exactly the same for all providers
  # ensurable resources will have create, create_message, exist? and destroy

  map ||= PuppetX::VMware::Mapper.new_map('VirtualHardwareMap')

  define_method(:map) do
    @map ||= map
  end

  map.leaf_list.each do |leaf|
    Puppet.debug "Auto-discovered property [#{leaf.prop_name}] for type [#{self.name}]"

    define_method(leaf.prop_name) do
      value = PuppetX::VMware::Mapper::munge_to_tfsyms.call(
        PuppetX::VMware::Util::nested_value(config_is_now, leaf.path_is_now)
      )
    end

    define_method("#{leaf.prop_name}=".to_sym) do |value|
      PuppetX::VMware::Util::nested_value_set config_should, leaf.path_should, value, transform_keys=false
      @flush_required = true
    end
  end

  def config_should
    @config_should ||= {}
  end

  ##### begin standard provider methods #####
  # these methods should exist in all ensurable providers, but content will diff

  def config_is_now
    @config_is_now ||= hardware
  end

  def flush
    if @flush_required
    require 'pry'; binding.pry
      vm.ReconfigVM_Task(
       :spec => RbVmomi::VIM::VirtualMachineConfigSpec( config_should )
      ).wait_for_completion
    end
  end

  ##### begin private provider specific methods section #####
  # These methods are provider specific and that can be private
  private
 
  def datacenter(name=resource[:datacenter])
    vim.serviceInstance.find_datacenter(name) or raise Puppet::Error, "datacenter '#{resource[:datacenter]}' not found."
  end

  def vm
    @vm ||= findvm(datacenter.vmFolder, resource[:vm_name]) or raise Puppet::Error, "Unable to locate VM with the name '#{resource[:vm_name]}' "
  end

  def hardware
    vm.config.hardware
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

end
