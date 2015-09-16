# Copyright 2015 VMware, Inc.

require 'set'

module PuppetX::VMware::Mapper

  class VirtualHardwareMap < Map
    def initialize
      @initTree = {
        Node => NodeData[
          :node_type => 'VirtualHardware',
        ],
        :memoryMb => LeafData[
          :desc => "The memory size to assign to the target VM",
          :validate => PuppetX::VMware::Mapper::validate_i_ge(0),
          :munge => PuppetX::VMware::Mapper::munge_to_i,
          :olio => {
            :ensure_is_class => ::Integer,
          }, 
        ],
        :numCoresPerSocket => LeafData[
          :desc => "The number of cores per vCPU on the target VM",
          :validate => PuppetX::VMware::Mapper::validate_i_ge(1),
          :munge => PuppetX::VMware::Mapper::munge_to_i,
          :olio => {
            :ensure_is_class => ::Integer,
          }, 
        ],
        :numCpus => LeafData[
          :desc => "Does this virtual machine have Virtual Intel I/O Controller Hub 7",
          :validate => PuppetX::VMware::Mapper::validate_i_ge(1),
          :munge => PuppetX::VMware::Mapper::munge_to_i,
          :olio => {
            :ensure_is_class => ::Integer,
          }, 
        ],
        :virtualICH7MPresent => LeafData[
          :prop_name  => 'virtual_ich7m_present',
          :desc       => "Does this virtual machine have Virtual Intel I/O Controller Hub 7",
          :valid_enum => [:true, :false],
        ],
        :virtualSMCPresent => LeafData[
          :prop_name  => 'virtual_smc_present',
          :desc       => "Does this virtual machine have System Management Controller",
          :valid_enum => [:true, :false],
        ],
      }

      super
    end
  end
end
