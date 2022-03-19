provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "project-1-rg" {
  name     = var.name_rg
  location = var.location_rg

  tags = {
    environment = var.prefix
  }
}

resource "azurerm_network_security_group" "project-1-SG" {
  name                = "${var.prefix}-security-group"
  location            = azurerm_resource_group.project-1-rg.location
  resource_group_name = azurerm_resource_group.project-1-rg.name

  tags = {
    environment = var.prefix
  }
}

# lowest priority rule denying all inbound traffic from the internet to the vnet
resource "azurerm_network_security_rule" "project-1-SG-rule-4" {
  name                        = "${var.prefix}-deny-all-from-internet"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "0.0.0.0/0"
  destination_address_prefix  = "10.0.0.0/16"
  resource_group_name         = azurerm_resource_group.project-1-rg.name
  network_security_group_name = azurerm_network_security_group.project-1-SG.name
}
# One rule allowing inbound traffic inside the same Virtual Network
resource "azurerm_network_security_rule" "project-1-SG-rule-1" {
  name                        = "${var.prefix}-allow-inbound-from-vnet"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_ranges           = ["22","80-443"]
  destination_port_ranges      = ["22","80-443"]
  source_address_prefix       = "10.0.0.0/16"
  destination_address_prefix  = "10.0.2.0/24"
  resource_group_name         = azurerm_resource_group.project-1-rg.name
  network_security_group_name = azurerm_network_security_group.project-1-SG.name
}
# One rule allowing outbound traffic inside the same Virtual Network
resource "azurerm_network_security_rule" "project-1-SG-rule-2" {
  name                        = "${var.prefix}-allow-outbound-to-vnet"
  priority                    = 102
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_ranges           = ["22","80-443"]
  destination_port_ranges      = ["22","80-443"]
  source_address_prefix       = "10.0.2.0/24"
  destination_address_prefix  = "10.0.0.0/16"
  resource_group_name         = azurerm_resource_group.project-1-rg.name
  network_security_group_name = azurerm_network_security_group.project-1-SG.name
}
# One rule allowing HTTP traffic to the VMs from the load balancer.
resource "azurerm_network_security_rule" "project-1-SG-rule-3" {
  name                        = "${var.prefix}-allow-http-to-VMs-from-lb"
  priority                    = 103
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "80"
  destination_port_range      = "80"
  source_address_prefix       = azurerm_public_ip.project-1-IP.ip_address
  destination_address_prefix  = "10.0.2.0/24"
  resource_group_name         = azurerm_resource_group.project-1-rg.name
  network_security_group_name = azurerm_network_security_group.project-1-SG.name
}


resource "azurerm_virtual_network" "project-1-VN" {
  name                = "${var.prefix}-virtual-network"
  location            = azurerm_resource_group.project-1-rg.location
  resource_group_name = azurerm_resource_group.project-1-rg.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = var.prefix
  }
}

resource "azurerm_subnet" "project-1-subnet-1" {
  name                 = "${var.prefix}-subnet-1"
  resource_group_name  = azurerm_resource_group.project-1-rg.name
  virtual_network_name = azurerm_virtual_network.project-1-VN.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "project-1-nic" {
  count               = var.number_of_VMs
  name                = "${var.prefix}-nic-${count.index}"
  location            = azurerm_resource_group.project-1-rg.location
  resource_group_name = azurerm_resource_group.project-1-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.project-1-subnet-1.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = var.prefix
  }
}

# Associations for Network Interfaces and Security group
resource "azurerm_network_interface_security_group_association" "example" {
  count                     = var.number_of_VMs
  network_interface_id      = azurerm_network_interface.project-1-nic[count.index].id
  network_security_group_id = azurerm_network_security_group.project-1-SG.id
}

resource "azurerm_public_ip" "project-1-IP" {
  name                = "${var.prefix}-IP"
  resource_group_name = azurerm_resource_group.project-1-rg.name
  location            = azurerm_resource_group.project-1-rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  availability_zone   = "No-Zone"
  tags = {
    environment = var.prefix
  }
}

resource "azurerm_lb" "project-1-LB" {
  name                = "${var.prefix}-load-balancer"
  location            = azurerm_resource_group.project-1-rg.location
  resource_group_name = azurerm_resource_group.project-1-rg.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.project-1-IP.id
  }

  tags = {
    environment = var.prefix
  }
}

resource "azurerm_lb_backend_address_pool" "project-1-backend-pool" {
  loadbalancer_id = azurerm_lb.project-1-LB.id
  name            = "${var.prefix}-BackEndAddressPool"
  # resource_group_name = azurerm_resource_group.project-1-rg.name
}

resource "azurerm_network_interface_backend_address_pool_association" "project-1-backend-pool-address-association" {
  count                   = var.number_of_VMs
  network_interface_id    = azurerm_network_interface.project-1-nic[count.index].id
  ip_configuration_name   = azurerm_network_interface.project-1-nic[count.index].ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.project-1-backend-pool.id
}

resource "azurerm_availability_set" "project-1-AV" {
  name                         = "${var.prefix}-availability-set"
  location                     = azurerm_resource_group.project-1-rg.location
  resource_group_name          = azurerm_resource_group.project-1-rg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  tags = {
    environment = var.prefix
  }
}

data "azurerm_image" "project-1-template-image" {
  name                = var.custom_image_name
  resource_group_name = var.custom_image_rg
}


# No need for the following azure_rm_managed_disk for the new terraform azurerm resource type of "azurerm_linux_virtual_machine".
# resource "azurerm_managed_disk" "project-1-VMs-managed-disks" {
#   count                = var.number_of_VMs
#   name                 = "${var.prefix}-VM-managed-disk-${count.index}"
#   location             = azurerm_resource_group.project-1-rg.location
#   resource_group_name  = azurerm_resource_group.project-1-rg.name
#   storage_account_type = "Standard_LRS"
#   create_option        = "Empty"
#   disk_size_gb         = "20"

#   tags = {
#     environment = var.prefix
#   }
# }

resource "azurerm_linux_virtual_machine" "project-1-VM-availability-set" {
  count                           = var.number_of_VMs
  name                            = "${var.prefix}-VM-${count.index}"
  resource_group_name             = azurerm_resource_group.project-1-rg.name
  location                        = azurerm_resource_group.project-1-rg.location
  size                            = "Standard_B1s"
  admin_username                  = var.VM_admin_username
  admin_password                  = var.VM_admin_password
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.project-1-nic[count.index].id,
  ]
  availability_set_id = azurerm_availability_set.project-1-AV.id
  source_image_id     = data.azurerm_image.project-1-template-image.id

  os_disk { # for the resource type of azurerm_linux_virtual_machine we can create an OS disk in this block without having to specify another terraform resource block.
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = {
    environment = var.prefix
  }
}