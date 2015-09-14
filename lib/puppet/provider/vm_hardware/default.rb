# Copyright (C) 2014 VMware, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'vcenter')

Puppet::Type.type(:vm_hardware).provide(:vm_hardware, :parent => Puppet::Provider::Vcenter) do
  @doc = "Manage a vCenter VM's virtual hardware settings. See http://pubs.vmware.com/vsphere-55/index.jsp#com.vmware.wssdk.apiref.doc/vim.vm.VirtualHardware.html for class details"

  Puppet::Type.type(:vm_hardware).properties.collect{|x| x.name}.each do |prop|
    Puppet.debug "Auto-discovered property [#{prop}] in vm_hardware"
    camel_prop = PuppetX::VMware::Util.camelize(prop, :lower).to_sym
    case prop
    when :memory_mb
      camel_prop = :memoryMB
    else
      camel_prop = camel_prop
    end
    Puppet.debug "camel_prop set to #{camel_prop}"

    if prop != :num_cpus
      define_method(prop) do
        value = current[camel_prop]
        case value
        when TrueClass  then :true
        when FalseClass then :false
        else value
        end
      end

      define_method("#{prop}=") do |value|
        @update = true
        hardwareProperties[camel_prop] = value
      end
    end
  end

  def num_cpus
    current[:numCPU]
  end

  def num_cpus=(value)
   @update = true
   hardwareProperties[:numCPUs] = value
  end

  def virtualMachineConfigSpec
    spec = RbVmomi::VIM::VirtualMachineConfigSpec( hardwareProperties )
  end

  def hardwareProperties
    @hardwareProperties ||= {}
  end

  def flush
    if @update
      vm.ReconfigVM_Task(
       :spec => virtualMachineConfigSpec
      ).wait_for_completion
    end
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

  def datacenter(name=resource[:datacenter])
    vim.serviceInstance.find_datacenter(name) or raise Puppet::Error, "datacenter '#{resource[:datacenter]}' not found."
  end

  def vm
    @vm ||= findvm(datacenter.vmFolder, resource[:vm_name]) or raise Puppet::Error, "Unable to locate VM with the name '#{resource[:vm_name]}' "
  end

  def hardware
#    require 'pry'; binding.pry
    vm.config.hardware
  end

  def current
    @current ||= hardware
  end

end
