require 'spec_helper'

provider_class = Puppet::Type.type(:vc_permission).provider(:vc_permission)

describe provider_class do

  let :resource do
    Puppet::Type::Vc_permission.new(
      { :principal => 'my_user', :role => 'Test_Role2', :propagate => 'true', :is_group => 'false' }
    )
  end

  let :provider do
    provider_class.new(resource)
  end

  before :each do
    # Mock AuthenticationManager that will be used to retrieve roles and permissions
    # Made an instance variable to overwrite in supplemental tests
    @fake_authManager = double
    provider.stubs(:authorizationManager).returns(@fake_authManager)

    # Mock 3 roles to simulate the return of multiple roles from the AuthenticationManager
    fake_role_1 = double
    allow(fake_role_1).to receive(:name).and_return('Test_Role1')
    fake_role_2 = double
    allow(fake_role_2).to receive(:name).and_return('Test_Role2')
    # Added roleId and privilege to fake_resource_2 since this is the object that will match the resource query
    # These attribute will be required for modification or deletion of the resource
    allow(fake_role_2).to receive(:roleId).and_return(1)
    fake_role_3 = double
    allow(fake_role_3).to receive(:name).and_return('Test_Role3')
    fake_role_list = [
      fake_role_1,
      fake_role_2,
      fake_role_3
    ]
    allow(@fake_authManager).to receive(:roleList).and_return( fake_role_list )
  end # End before :each do

  context 'exists?' do

  end # End context 'exists?' do

  context 'create' do
    before :each do
    end
  end # End context 'create' do

  context 'destroy' do
    before :each do
    end
  end # End context 'destroy' do

  context 'flush' do
=begin
    it 'should do nothing if @flush_required is false' do
      provider.instance_variable_set(:@flush_required, false)
      expect( provider.instance_variable_get(:@flush_required) ).to eq(false)
      expect{ provider.flush }.to_not raise_error
    end

    it 'should update the role when @flush_required is true' do
      expect( provider.instance_variable_get(:@flush_required) ).to eq(true)
      expect{ provider.flush }.to_not raise_error
    end 
=end
  end # End context 'flush' do

  context 'role' do
    it 'should locate the role matching resource[:role]' do
      expect{ provider.send(:role) }.to_not raise_error
      role = provider.send(:role) 
      expect( role ).to_not be_nil
      expect( role.name ).to eq('Test_Role2')
    end

    it 'should error if it fails to lcoate a role matching resource[:role]' do
      # Overwrite the stubbed return of the roleList method to simulate no returned roles
      allow(@fake_authManager).to receive(:roleList).and_return( [] )
      expect{ provider.send(:role) }.to raise_error(Puppet::Error, "Unable to locate role 'Test_Role2' on vCenter")
    end
  end # End context 'role' do
end
