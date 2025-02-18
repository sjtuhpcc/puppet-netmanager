# == Class: network
#
# This module manages Red Hat/Fedora network configuration.
#
# === Parameters:
#
# None
#
# === Actions:
#
# Defines the network service so that other resources can notify it to restart.
#
# === Sample Usage:
#
#   include '::network'
#
# === Authors:
#
# Mike Arnold <mike@razorsedge.org>
#
# === Copyright:
#
# Copyright (C) 2011 Mike Arnold, unless otherwise noted.
#
class network {
  # Only run on RedHat derived systems.
  case $::osfamily {
    'RedHat': { }
    default: {
      fail('This network module only supports RedHat-based systems.')
    }
  }

  service { 'NetworkManager':
    ensure     => 'running',
    enable     => true,
    hasrestart => false,
    hasstatus  => true,
  }

} # class network

# == Definition: network_if_base
#
# This definition is private, i.e. it is not intended to be called directly
# by users.  It can be used to write out the following device files:
#  /etc/sysconfig/networking-scripts/ifcfg-eth
#  /etc/sysconfig/networking-scripts/ifcfg-eth:alias
#  /etc/sysconfig/networking-scripts/ifcfg-bond(master)
#
# === Parameters:
#
#   $ensure          - required - up|down
#   $ifname          - optional
#   $device          - required
#   $ipaddress       - required
#   $netmask         - required
#   $macaddress      - required
#   $manage_hwaddr   - optional - defaults to true
#   $gateway         - optional
#   $noaliasrouting  - optional - defaults to false
#   $bootproto       - optional
#   $userctl         - optional - defaults to false
#   $mtu             - optional
#   $dhcp_hostname   - optional
#   $ethtool_opts    - optional
#   $bonding_opts    - optional
#   $isalias         - optional
#   $peerdns         - optional
#   $dns1            - optional
#   $dns2            - optional
#   $domain          - optional
#   $bridge          - optional
#   $scope           - optional
#   $linkdelay       - optional
#   $check_link_down - optional
#   $flush           - optional
#   $zone            - optional
#   $metric          - optional
#   $defroute        - optional
#
# === Actions:
#
# Performs 'service network restart' after any changes to the ifcfg file.
#
# === TODO:
#
#   HOTPLUG=yes|no
#   WINDOW=
#   SCOPE=
#   SRCADDR=
#   NOZEROCONF=yes
#   PERSISTENT_DHCLIENT=yes|no|1|0
#   DHCPRELEASE=yes|no|1|0
#   DHCLIENT_IGNORE_GATEWAY=yes|no|1|0
#   REORDER_HDR=yes|no
#
# === Authors:
#
# Mike Arnold <mike@razorsedge.org>
#
# === Copyright:
#
# Copyright (C) 2011 Mike Arnold, unless otherwise noted.
#
define network_if_base (
  $ensure,
  $ifname,
  $device,
  $ipaddress,
  $netmask,
  $macaddress,
  $manage_hwaddr   = true,
  $gateway         = undef,
  $noaliasrouting  = false,
  $ipv6address     = undef,
  $ipv6gateway     = undef,
  $ipv6init        = false,
  $ipv6autoconf    = false,
  $ipv6secondaries = undef,
  $bootproto       = 'none',
  $userctl         = false,
  $mtu             = undef,
  $dhcp_hostname   = undef,
  $ethtool_opts    = undef,
  $bonding_opts    = undef,
  $isalias         = false,
  $peerdns         = false,
  $ipv6peerdns     = false,
  $dns1            = undef,
  $dns2            = undef,
  $domain          = undef,
  $bridge          = undef,
  $linkdelay       = undef,
  $scope           = undef,
  $check_link_down = false,
  $flush           = false,
  $defroute        = undef,
  $zone            = undef,
  $metric          = undef,
  $type            = undef,
) {
  # Validate our booleans
  validate_bool($noaliasrouting)
  validate_bool($userctl)
  validate_bool($isalias)
  validate_bool($peerdns)
  validate_bool($ipv6init)
  validate_bool($ipv6autoconf)
  validate_bool($ipv6peerdns)
  validate_bool($check_link_down)
  validate_bool($manage_hwaddr)
  validate_bool($flush)
  # Validate our regular expressions
  $states = [ '^up$', '^down$' ]
  validate_re($ensure, $states, '$ensure must be either "up" or "down".')

  include '::network'

  # Deal with the case where $dns2 is non-empty and $dns1 is empty.
  if $dns2 {
    if !$dns1 {
      $dns1_real = $dns2
      $dns2_real = undef
    } else {
      $dns1_real = $dns1
      $dns2_real = $dns2
    }
  } else {
    $dns1_real = $dns1
    $dns2_real = $dns2
  }

  if $isalias {
    $onparent = $ensure ? {
      'up'    => 'yes',
      'down'  => 'no',
      default => undef,
    }
    $iftemplate = template('network/ifcfg-alias.erb')
  } else {
    $onboot = $ensure ? {
      'up'    => 'yes',
      'down'  => 'no',
      default => undef,
    }
    $iftemplate = template('network/ifcfg-eth.erb')
  }

  if $flush {
    exec { 'network-flush':
      user        => 'root',
      command     => "ip addr flush dev ${device}",
      refreshonly => true,
      subscribe   => File["ifcfg-${ifname}"],
      before      => Exec["nmcli_manage_${ifname}"],
      path        => '/sbin:/usr/sbin',
    }
  }

  file { "ifcfg-${ifname}":
    ensure  => 'present',
    path    => "/etc/sysconfig/network-scripts/ifcfg-${ifname}",
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => $iftemplate,
    notify  => Exec["nmcli_config_${ifname}"]
  }


  exec { "nmcli_config_${ifname}":
    path        => '/usr/bin:/bin:/usr/sbin:/sbin',
    command     => "nmcli connection load /etc/sysconfig/network-scripts/ifcfg-${ifname}",
    refreshonly => true,
    notify      => Exec["nmcli_manage_${ifname}"],
  }

  exec { "nmcli_manage_${ifname}":
    path        => '/usr/bin:/bin:/usr/sbin:/sbin',
    command     => "nmcli connection ${ensure} ${ifname}",
    refreshonly => true,
    notify      => Exec["nmcli_clean_${ifname}"],
    require     => Exec["nmcli_config_${ifname}"]
  }

  exec { "nmcli_clean_${ifname}":
    path    => '/usr/bin:/bin:/usr/sbin:/sbin',
    command => "nmcli connection delete $(nmcli -f UUID,DEVICE connection show|grep \'\\-\\-\'|awk \'{print \$1}\')",
    onlyif  => "nmcli -f UUID,DEVICE connection show|grep \'\\-\\-\'",
    require => Exec["nmcli_manage_${ifname}"]
  }

} # define network_if_base

# == Definition: validate_ip_address
#
# This definition can be used to call is_ip_address on an array of ip addresses.
#
# === Parameters:
#
# None
#
# === Actions:
#
# Runs is_ip_address on the name of the define and fails if it is not a valid IP address.
#
# === Sample Usage:
#
# $ips = [ '10.21.30.248', '123:4567:89ab:cdef:123:4567:89ab:cdef' ]
# validate_ip_address { $ips: }
#
define validate_ip_address {
  if ! is_ip_address($name) { fail("${name} is not an IP(v6) address.") }
} # define validate_ip_address
