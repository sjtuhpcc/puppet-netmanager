# == Definition: network::bond::slave
#
# Creates a bonded slave interface.
#
# === Parameters:
#
#   $macaddress   - required
#   $master       - required
#   $ethtool_opts - optional
#
# === Actions:
#
# Deploys the file /etc/sysconfig/network-scripts/ifcfg-$name.
#
# === Requires:
#
#   Service['network']
#
# === Sample Usage:
#
#   network::bond::slave { 'eth1':
#     macaddress => $::macaddress_eth1,
#     master     => 'bond0',
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
define network::bond::slave (
  $macaddress,
  $master,
  $device = $title,
  $ethtool_opts = undef,
  $zone = undef,
  $defroute = undef,
  $metric = undef
) {
  # Validate our data
  if ! is_mac_address($macaddress) {
    fail("${macaddress} is not a MAC address.")
  }

  include '::network'

  $ifname = $title

  file { "ifcfg-${ifname}":
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    path    => "/etc/sysconfig/network-scripts/ifcfg-${ifname}",
    content => template('network/ifcfg-bond.erb'),
    before  => File["ifcfg-${master}"],
    notify  => Exec['nmcli_config', 'nmcli_manage', 'nmcli_clean'],
  }
} # define network::bond::slave
