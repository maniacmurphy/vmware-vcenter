# Copyright (C) 2013 VMware, Inc.
begin
  require 'puppet_x/puppetlabs/transport'
rescue LoadError => e
  require 'pathname' # WORK_AROUND #14073 and #7788
  vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
  require File.join vmware_module.path, 'lib/puppet_x/puppetlabs/transport'
end

begin
  require 'puppet_x/puppetlabs/transport/vsphere'
rescue LoadError => e 
  require 'pathname' # WORK_AROUND #14073 and #7788
  module_lib = Pathname.new(__FILE__).parent.parent.parent
  require File.join module_lib, 'puppet_x/puppetlabs/transport/vsphere'
end

begin
  require 'puppet_x/vmware/util'
rescue LoadError => e 
  require 'pathname' # WORK_AROUND #14073 and #7788
  module_lib = Pathname.new(__FILE__).parent.parent.parent
  vmware_module = Puppet::Module.find('vmware_lib', Puppet[:environment].to_s)
  require File.join vmware_module.path, 'lib/puppet_x/vmware/util'
end

class Puppet::Provider::Vcenter <  Puppet::Provider
  confine :feature => :vsphere

  private

  def vim
    @transport ||= PuppetX::Puppetlabs::Transport.retrieve(:resource_ref => resource[:transport], :catalog => resource.catalog, :provider => 'vsphere')
    @transport.vim
  end

  def rootfolder
    @rootfolder ||= vim.serviceInstance.content.rootFolder
  end

  # Always return a folder
  def vmfolder(path=parent)
    if path == '/'
      vmfolder = rootfolder
    else
      vmfolder = locate(path)
    end
    raise Puppet::Error.new("Invalid path: #{path}") unless vmfolder
    return_folder(vmfolder)
  end

  def return_folder(folder)
    case folder
    when RbVmomi::VIM::Folder
      folder
    when RbVmomi::VIM::Datacenter
      folder.hostFolder
    when RbVmomi::VIM::ClusterComputeResource
      folder
    when RbVmomi::VIM::ComputeResource
      folder.resourcePool
    when NilClass
      raise Puppet::Error.new("Invalid path: #{@resource[:path]}.")
    else
      raise Puppet::Error.new("Unknown container type: #{folder.class}")
    end
  end

  def findvms(folder)
  # Returns all VMs under target folder's hierarchy
    vms = []
    folder.children.each do |c|
      puts c.class
      case c
      when RbVmomi::VIM::Folder
        puts c
        vms += findvm(c)
      when RbVmomi::VIM::VirtualMachine
        vms << c
      when RbVmomi::VIM::VirtualApp
        f.vm.each do |v|
          if v.name == vm_name
            @vm_obj = f
            break
          end
        end
      else
        Puppet.warning "Puppet::Provider::Vcenter::findvm unknown child type found: #{f.class}"
        exit
      end
    end
    vms
  end

  def findvm(folder,vm_name)
  # Returns the first matching VM under target folders hierarchy
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
        Puppet.warning "Puppet::Provider::Vcenter::findvm unknown child type found: #{f.class}"
        exit
      end
    end
    @vm_obj
  end

  def locate(path, type=nil)
    folder = rootfolder
    Pathname.new(path).each_filename do |dir|
      folder = return_folder(folder).traverse(dir)
    end

    if type
      folder if folder.is_a? type
    else
      folder
    end
  end

  def walk(path, type, order=:ascend)
    Pathname.new(path).send(order) do |folder|
      obj = vim.searchIndex.FindByInventoryPath({:inventoryPath => folder.to_s})
      return obj if obj.is_a? type
    end
  end

  def parent(path=resource[:path])
    Pathname.new(path).parent.to_s
  end

  def basename(path=resource[:path])
    Pathname.new(path).basename.to_s
  end
end
