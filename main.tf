terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "minitwit_rg" {
  name     = "minitwit"
  location = "West Europe"
}

resource "azurerm_virtual_network" "minitwit_vnet" {
  name                = "vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.minitwit_rg.location
  resource_group_name = azurerm_resource_group.minitwit_rg.name
}

resource "azurerm_subnet" "minitwit_subnet_web" {
  name                 = "web"
  resource_group_name  = azurerm_resource_group.minitwit_rg.name
  virtual_network_name = azurerm_virtual_network.minitwit_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "minitwit_subnet_db" {
  name                 = "db"
  resource_group_name  = azurerm_resource_group.minitwit_rg.name
  virtual_network_name = azurerm_virtual_network.minitwit_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "minitwit_public_ip" {
  name                = "app_public_ip"
  location            = azurerm_resource_group.minitwit_rg.location
  resource_group_name = azurerm_resource_group.minitwit_rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "minitwit_nic" {
  name                = "app_nic"
  location            = azurerm_resource_group.minitwit_rg.location
  resource_group_name = azurerm_resource_group.minitwit_rg.name

  ip_configuration {
    name                          = "app-nic-config"
    subnet_id                     = azurerm_subnet.minitwit_subnet_web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.minitwit_public_ip.id
  }
}

resource "azurerm_network_security_group" "minitwit_nsg" {
  name                = "app_nsg"
  location            = azurerm_resource_group.minitwit_rg.location
  resource_group_name = azurerm_resource_group.minitwit_rg.name
}

resource "azurerm_network_security_rule" "minitwit_nsg_rule_web" {
  name                        = "allow_http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.minitwit_rg.name
  network_security_group_name = azurerm_network_security_group.minitwit_nsg.name
}

resource "azurerm_linux_virtual_machine" "minitwit_vm_web" {
  name                = "vm-web"
  resource_group_name = azurerm_resource_group.minitwit_rg.name
  location            = azurerm_resource_group.minitwit_rg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.minitwit_nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
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
