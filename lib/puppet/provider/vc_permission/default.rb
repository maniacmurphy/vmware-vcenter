# Copyright (C) 2016 VMware, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'vcenter')

Puppet::Type.type(:vc_permission).provide(:vc_permission, :parent => Puppet::Provider::Vcenter) do

  @doc = "Manage vCenter Roles. http://pubs.vmware.com/vsphere-55/index.jsp#com.vmware.wssdk.apiref.doc/vim.AuthorizationManager.Permission.html"

  def create

  end

  def destroy

  end

  def exists?
  end

  ##### begin standard provider methods #####
  # these methods should exist in all ensurable providers, but content will diff

  def flush

  end

  ##### begin private provider specific methods section #####
  # These methods are provider specific and that can be private

  def propagate
  end

  def propogate=()
  end

  def is_group
  end

  def is_group=()
  end

  private

  def authorizationManager
    @authorizationManager ||= vim.serviceContent.authorizationManager
  end

  def role
    @role ||= authorizationManager.roleList.find { |r| r.name == resource[:role] }
    raise Puppet::Error, "Unable to locate role '#{resource[:role]}' on vCenter" unless @role
    @role
  end
end
