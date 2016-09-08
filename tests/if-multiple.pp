include network

# normal interface - dhcp
network::if::dynamic { 'test70':
  ensure     => 'up',
  device       => 'eth70',
  macaddress => 'ff:ff:ff:ff:ff:ff',
}

# normal interface - static
network::if::static { 'test90':
  ensure       => 'up',
  device       => 'eth90',
  ipaddress    => '1.2.3.4',
  netmask      => '255.255.255.0',
  gateway      => '1.2.3.1',
  macaddress   => 'fe:fe:fe:ff:ff:ff',
  mtu          => '9000',
  ethtool_opts => 'speed 10 duplex half autoneg off',
}
