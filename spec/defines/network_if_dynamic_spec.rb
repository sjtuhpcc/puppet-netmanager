#!/usr/bin/env rspec

require 'spec_helper'

describe 'network::if::dynamic', :type => 'define' do

  context 'incorrect value: ensure' do
    let(:title) { 'test77' }
    let :params do {
      :ensure => 'blah',
      :device => 'eth77',
    }
    end
    it 'should fail' do
      expect {should contain_file('ifcfg-test77')}.to raise_error(Puppet::Error, /\$ensure must be either "up" or "down"./)
    end
  end

  context 'required parameters' do
    let(:title) { 'test99' }
    let :params do {
      :ensure => 'up',
      :device => 'eth99',
    }
    end
    let :facts do {
      :osfamily         => 'RedHat',
      :macaddress_eth99 => 'ff:aa:ff:aa:ff:aa',
    }
    end
    it { should contain_file('ifcfg-test99').with(
      :ensure => 'present',
      :mode   => '0644',
      :owner  => 'root',
      :group  => 'root',
      :path   => '/etc/sysconfig/network-scripts/ifcfg-test99',
      :notify  =>"Exec['nmcli_config', 'nmcli_manage', 'nmcli_clean']"
    )}
    it 'should contain File[ifcfg-test99] with required contents' do
      verify_contents(catalogue, 'ifcfg-test99', [
        'DEVICE=eth99',
        'BOOTPROTO=dhcp',
        'HWADDR=ff:aa:ff:aa:ff:aa',
        'ONBOOT=yes',
        'HOTPLUG=yes',
        'TYPE=Ethernet',
        'NM_CONTROLLED=yes',
      ])
    end
    it { should contain_service('NetworkManager') }
  end

  context 'optional parameters' do
    let(:title) { 'test99' }
    let :params do {
      :ensure          => 'down',
      :device          => 'eth99',
      :macaddress      => 'ef:ef:ef:ef:ef:ef',
      :bootproto       => 'bootp',
      :userctl         => true,
      :mtu             => '1500',
      :dhcp_hostname   => 'hostname',
      :ethtool_opts    => 'speed 100 duplex full autoneg off',
      :peerdns         => true,
      :linkdelay       => '5',
      :check_link_down => true,
      :defroute        => 'yes',
      :metric          => '10',
      :zone            => 'trusted',
    }
    end
    let :facts do {
      :osfamily         => 'RedHat',
      :macaddress_eth99 => 'ff:aa:ff:aa:ff:aa',
    }
    end
    it { should contain_file('ifcfg-test99').with(
      :ensure => 'present',
      :mode   => '0644',
      :owner  => 'root',
      :group  => 'root',
      :path   => '/etc/sysconfig/network-scripts/ifcfg-test99',
      :notify  =>"Exec['nmcli_config', 'nmcli_manage', 'nmcli_clean']"
    )}
    it 'should contain File[ifcfg-test99] with required contents' do
      verify_contents(catalogue, 'ifcfg-test99', [
        'DEVICE=eth99',
        'BOOTPROTO=bootp',
        'HWADDR=ef:ef:ef:ef:ef:ef',
        'ONBOOT=no',
        'HOTPLUG=no',
        'TYPE=Ethernet',
        'MTU=1500',
        'DHCP_HOSTNAME="hostname"',
        'ETHTOOL_OPTS="speed 100 duplex full autoneg off"',
        'USERCTL=yes',
        'LINKDELAY=5',
        'DEFROUTE=yes',
        'ZONE=trusted',
        'METRIC=10',
        'NM_CONTROLLED=yes',
      ])
    end
    it { should contain_service('NetworkManager') }
  end

  context 'optional parameters - vlan' do
    let(:title) { 'eth45.302' }
    let(:params) {{ :ensure => 'up' }}
    let :facts do {
      :osfamily         => 'RedHat',
      :macaddress_eth45 => 'bb:cc:bb:cc:bb:cc',
    }
    end
    it { should contain_file('ifcfg-eth45.302').with(
      :ensure => 'present',
      :mode   => '0644',
      :owner  => 'root',
      :group  => 'root',
      :path   => '/etc/sysconfig/network-scripts/ifcfg-eth45.302',
      :notify  =>"Exec['nmcli_config', 'nmcli_manage', 'nmcli_clean']"
    )}
    it 'should contain File[ifcfg-eth45.302] with required contents' do
      verify_contents(catalogue, 'ifcfg-eth45.302', [
        'DEVICE=eth45.302',
        'BOOTPROTO=dhcp',
        'HWADDR=bb:cc:bb:cc:bb:cc',
        'ONBOOT=yes',
        'HOTPLUG=yes',
        'TYPE=Ethernet',
        'NM_CONTROLLED=no',
      ])
    end
    it { should contain_service('NetworkManager') }
  end

  context 'optional parameters - manage_hwaddr' do
    let(:title) { 'test0' }
    let :params do {
      :ensure        => 'up',
      :device        => 'eth0',
      :manage_hwaddr => false,
    }
    end
    let :facts do {
      :osfamily        => 'RedHat',
      :macaddress_eth0 => 'bb:cc:bb:cc:bb:cc',
    }
    end
    it { should contain_file('ifcfg-test0').with(
      :ensure => 'present',
      :mode   => '0644',
      :owner  => 'root',
      :group  => 'root',
      :path   => '/etc/sysconfig/network-scripts/ifcfg-test0',
      :notify  =>"Exec['nmcli_config', 'nmcli_manage', 'nmcli_clean']"
    )}
    it 'should contain File[ifcfg-test0] with required contents' do
      verify_contents(catalogue, 'ifcfg-test0', [
        'DEVICE=eth0',
        'BOOTPROTO=dhcp',
        'ONBOOT=yes',
        'HOTPLUG=yes',
        'TYPE=Ethernet',
        'NM_CONTROLLED=yes',
      ])
    end
    it { should contain_service('NetworkManager') }
  end


end
