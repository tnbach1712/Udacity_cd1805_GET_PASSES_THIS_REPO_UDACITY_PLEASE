
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
    name                          = "internal"
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

resource "azurerm_network_interface_backend_address_pool_association" "association-pool-network-01" {
  ip_configuration_name   = "association-pool-network-01"
  network_interface_id    = azurerm_network_interface.network-interfaces[0].id
  backend_address_pool_id = azurerm_lb_backend_address_pool.load-lb-pool-01.id
}

# Create Avaibility set
resource "azurerm_availability_set" "avaibility-set-01" {
  name                = "avaibility-set-01"
  location            = var.location
  resource_group_name = var.resource_group

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
    id = "/subscriptions/fbda4cc5-31d3-4801-9427-d377d6038291/resourceGroups/fdn-doi-iac-rg-001/providers/Microsoft.Compute/images/myPackerImage"
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
    admin_password = var.admin_password # "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = var.tags
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