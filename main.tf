#provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "get subscription from azure whether tenant or default directory"
  # Configuration options
}

#creating resource group
resource "azurerm_resource_group" "tf-resourcegr" {
  name     = "tf-reourcesgr"
  location = "West Europe"
}

#creating virtual network
resource "azurerm_virtual_network" "tf-vnet" {
  name                = "tf-vnet"
  location            = azurerm_resource_group.tf-resourcegr.location
  resource_group_name = azurerm_resource_group.tf-resourcegr.name
  address_space       = ["10.0.0.0/16"]
}

#creating subnet
resource "azurerm_subnet" "public_subnet" {
  name                 = "public-subnet"
  resource_group_name  = azurerm_resource_group.tf-resourcegr.name
  virtual_network_name = azurerm_virtual_network.tf-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

#creating security group and security following each other immediately
resource "azurerm_network_security_group" "tf-nsg" {
  name                = "tf_nsg"
  location            = azurerm_resource_group.tf-resourcegr.location
  resource_group_name = azurerm_resource_group.tf-resourcegr.name

  security_rule {
    name                       = "tf-nsr"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
#this is to associate network intetrface and security group

resource "azurerm_network_interface_security_group_association" "tf-nica" {
  network_interface_id      = azurerm_network_interface.tf_nic.id
  network_security_group_id = azurerm_network_security_group.tf-nsg.id
}
resource "azurerm_network_interface" "tf_nic" {
  name                = "tf_nic"
  location            = azurerm_resource_group.tf-resourcegr.location
  resource_group_name = azurerm_resource_group.tf-resourcegr.name
#remember to include public address id [creating public ip]
  ip_configuration {
    name                          = "tf-ip"
    subnet_id                     = azurerm_subnet.public_subnet.id
    private_ip_address_allocation = "Static"
    public_ip_address_id = azurerm_public_ip.tf-ip.id
  }
}

resource "azurerm_linux_virtual_machine" "tf-vm" {
  name                = "tf-vm"
  resource_group_name = azurerm_resource_group.tf-resourcegr.name
  location            = azurerm_resource_group.tf-resourcegr.location
  size                = "Standard_F2"
  admin_username      = "chemiron"
  network_interface_ids = [
    azurerm_network_interface.tf_nic.id,
  ]

  admin_ssh_key {
    username   = "chemiron"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
resource "azurerm_public_ip" "tf-ip" {
  name                = "tf-ip"
  resource_group_name = azurerm_resource_group.tf-resourcegr.name
  location            = azurerm_resource_group.tf-resourcegr.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}