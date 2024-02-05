
# DEFINE NSG
resource "azurerm_network_security_group" "nsg-deny-internet-alow-internal-network" {
  name                = "nsg-deny-internet-alow-internal-network"
  location            = var.location
  resource_group_name = var.resource_group

  tags = var.tags
}

# DEFINE NSG RULE
resource "azurerm_network_security_rule" "nsg-deny-internet" {
  name                        = "nsg-deny-internet"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = var.resource_group
  network_security_group_name = azurerm_network_security_group.nsg-deny-internet-alow-internal-network.name
}
resource "azurerm_network_security_rule" "nsg-allow-internal" {
  name                        = "nsg-allow-internal"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = var.resource_group
  network_security_group_name = azurerm_network_security_group.nsg-deny-internet-alow-internal-network.name
}

//  Define Vnet
resource "azurerm_virtual_network" "vnet01" {
  name                = "Vnet01"
  location            = var.location
  resource_group_name = var.resource_group
  address_space       = var.address_space // ["10.0.0.0/16"]
  dns_servers         = var.dns_server // ["10.0.0.4", "10.0.0.5"]
  tags = var.tags 
}

# Create sunbets
resource "azurerm_subnet" "subnets" {
  count = length(var.subnets)
  name                 = var.subnets[count.index].name
  resource_group_name  = var.resource_group
  
  virtual_network_name = azurerm_virtual_network.vnet01.name
  address_prefixes     = [var.subnets[count.index].address_prefix]
}

resource "azurerm_subnet_network_security_group_association" "subnets-association-nsg" {
  count                     = length(azurerm_subnet.subnets)
  subnet_id                 = azurerm_subnet.subnets[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg-deny-internet-alow-internal-network.id
}

#  Create Network Interfaces
resource "azurerm_network_interface" "network-interfaces" {
  location            = var.location
  resource_group_name = var.resource_group
  count               = length(azurerm_subnet.subnets)
  name                = "network-interface-${count.index}"
  ip_configuration {
    name                          = "nic-internal-${count.index}"
    subnet_id                     = azurerm_subnet.subnets[count.index].id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create Public IP
resource "azurerm_public_ip" "public-ip-01" {
  name                = "public_ip_01"
  resource_group_name = var.resource_group
  location            = var.location
  allocation_method   = "Static"

  tags = var.tags
}

resource "azurerm_lb" "load-lb-01" {
  name                = "load-lb-01"
  location            = var.location
  resource_group_name = var.resource_group
  sku = "Standard"
  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.public-ip-01.id
  } 
}

resource "azurerm_lb_backend_address_pool" "load-lb-pool-01" {
  loadbalancer_id    = azurerm_lb.load-lb-01.id
  name               = "load-lb-pool-01"
  virtual_network_id = azurerm_virtual_network.vnet01.id
}

resource "azurerm_lb_backend_address_pool_address" "lb-address-pool-address-01" {
  name = "lb-address-pool-address-01"
  backend_address_pool_id = azurerm_lb_backend_address_pool.load-lb-pool-01.id
  backend_address_ip_configuration_id = azurerm_lb.load-lb-01.frontend_ip_configuration[0].id
}
resource "azurerm_network_interface" "loadbalancer-network-interface" {
  name                = "example-nic"
  location            = var.location
  resource_group_name = var.resource_group

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.subnets[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "association-pool-network-01" {
  ip_configuration_name   = "testconfiguration1"
  network_interface_id    = azurerm_network_interface.loadbalancer-network-interface.id
  backend_address_pool_id = azurerm_lb_backend_address_pool.load-lb-pool-01.id
  depends_on = [ azurerm_network_interface.loadbalancer-network-interface ]
}

# Create Avaibility set
resource "azurerm_availability_set" "avaibility-set-01" {
  name                = "avaibility-set-01"
  location            = var.location
  resource_group_name = var.resource_group
  platform_update_domain_count   = 2
  platform_fault_domain_count    = 2

  tags = var.tags
}

# Create VM 
resource "azurerm_virtual_machine" "vm-01" {
  name                  = "vm-01"
  location              = var.location
  resource_group_name   = var.resource_group
  availability_set_id   = azurerm_availability_set.avaibility-set-01.id
  delete_os_disk_on_termination = true
  network_interface_ids = [azurerm_network_interface.network-interfaces[0].id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group}/providers/Microsoft.Compute/images/${var.image_name}"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = var.tags

  # depends_on = [ azurerm.vnet01, azurerm.subnets ]
}

# Create managed disk
resource "azurerm_managed_disk" "disk" {
  name                 = "disk1"
  location             = var.location
  resource_group_name  = var.resource_group
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 10
}

resource "azurerm_virtual_machine_data_disk_attachment" "example" {
  managed_disk_id    = azurerm_managed_disk.disk.id
  virtual_machine_id = azurerm_virtual_machine.vm-01.id
  lun                = "10"
  caching            = "ReadWrite"
}


resource "azurerm_lb_probe" "example_lb_probe" {
  name                = "example-lb-probe"
  loadbalancer_id     = azurerm_lb.load-lb-01.id
  protocol            = "Tcp"
  port                = 80
  interval_in_seconds = 15
  number_of_probes    = 2
  
}

resource "azurerm_lb_rule" "example_lb_rule" {
  name                           = "example-lb-rule"
  # resource_group_name            = var.resource_group
  loadbalancer_id                = azurerm_lb.load-lb-01.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  # backend_address_pool_id        = azurerm_lb_backend_address_pool.example_backend_address_pool.id
  probe_id                       = azurerm_lb_probe.example_lb_probe.id
  enable_floating_ip             = false
  idle_timeout_in_minutes        = 15
  load_distribution              = "Default"
  disable_outbound_snat          = false
  # floating_ip_idle_timeout_in_minutes = 4
}