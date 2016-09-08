# == Definition: network::if::dynamic
#
# Creates a normal interface with dynamic IP information.
#
# === Parameters:
#
#   $ensure          - required - up|down
#   $ifname          - optional - default $title 
#   $device          - required - device name
#   $macaddress      - optional - defaults to macaddress_$title
#   $manage_hwaddr   - optional - defaults to true
#   $bootproto       - optional - defaults to "dhcp"
#   $userctl         - optional - defaults to false
#   $mtu             - optional
#   $dhcp_hostname   - optional
#   $ethtool_opts    - optional
#   $peerdns         - optional
#   $linkdelay       - optional
#   $check_link_down - optional
#   $zone            - optional
#   $metric          - optional
#   $defroute        - optional
#
# === Actions:
#
# Deploys the file /etc/sysconfig/network-scripts/ifcfg-$ifname.
#
# === Sample Usage:
#
#   network::if::dynamic { 'test2':
#     ensure     => 'up',
#     device     => 'eth2',
#     macaddress => $::macaddress_eth2,
#   }
#
#   network::if::dynamic { 'test3':
#     ensure     => 'up',
#     device     => 'eth3',
#     macaddress => 'fe:fe:fe:fe:fe:fe',
#     bootproto  => 'bootp',
#   }
#
# === Authors:
#
# Mike Arnold <mike@razorsedge.org>
#
# === Copyright:
#
# Copyright (C) 2011 Mike Arnold, unless otherwise noted.
#
define network::if::dynamic (
  $ensure,
  $device,
  $macaddress      = undef,
  $manage_hwaddr   = true,
  $bootproto       = 'dhcp',
  $userctl         = false,
  $mtu             = undef,
  $dhcp_hostname   = undef,
  $ethtool_opts    = undef,
  $peerdns         = false,
  $linkdelay       = undef,
  $check_link_down = false,
  $defroute        = undef,
  $zone            = undef,
  $metric          = undef
) {
  # Validate our regular expressions
  $states = [ '^up$', '^down$' ]
  validate_re($ensure, $states, '$ensure must be either "up" or "down".')

  if ! is_mac_address($macaddress) {
    # Strip off any tailing VLAN (ie eth5.90 -> eth5).
    $device_clean = regsubst($device,'^(\w+)\.\d+$','\1')
    $macaddy = getvar("::macaddress_${device_clean}")
  } else {
    $macaddy = $macaddress
  }
  # Validate booleans
  validate_bool($userctl)
  validate_bool($peerdns)
  validate_bool($manage_hwaddr)

  network_if_base { $title:
    ensure          => $ensure,
    ifname          => $title,
    device          => $title,
    ipaddress       => '',
    netmask         => '',
    gateway         => '',
    macaddress      => $macaddy,
    manage_hwaddr   => $manage_hwaddr,
    bootproto       => $bootproto,
    userctl         => $userctl,
    mtu             => $mtu,
    dhcp_hostname   => $dhcp_hostname,
    ethtool_opts    => $ethtool_opts,
    peerdns         => $peerdns,
    linkdelay       => $linkdelay,
    check_link_down => $check_link_down,
    defroute        => $defroute,
    zone            => $zone,
    metric          => $metric,
  }
} # define network::if::dynamic
