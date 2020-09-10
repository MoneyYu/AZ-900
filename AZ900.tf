provider "azurerm" {
  # The "feature" block is required for AzureRM provider 2.x. 
  # If you are using version 1.x, the "features" block is not allowed.
  version = "~>2.0"
  features {}
}

locals {
  group_name              = "AZ900"
  lab01_name              = "LAB01VMWEB"
  lab02_name              = "LAB02CI"
  lab03_name              = "LAB03VM"
  lab04_name              = "LAB04BLOB"
  lab05_name              = "LAB05SQL"
  lab06_name              = "LAB06IOTHUB"
  lab07_name              = "LAB07FUNCTION"
  lab08_name              = "LAB08WEBAPP"
  lab13_name              = "LAB13KEYVALUT"
  lab14_name              = "LAB14COSMOS"
  lab01_name_with_postfix = "${local.lab01_name}${random_string.rid.result}"
  lab02_name_with_postfix = "${local.lab02_name}${random_string.rid.result}"
  lab03_name_with_postfix = "${local.lab03_name}${random_string.rid.result}"
  lab04_name_with_postfix = "${local.lab04_name}${random_string.rid.result}"
  lab05_name_with_postfix = "${local.lab05_name}${random_string.rid.result}"
  lab06_name_with_postfix = "${local.lab06_name}${random_string.rid.result}"
  lab07_name_with_postfix = "${local.lab07_name}${random_string.rid.result}"
  lab08_name_with_postfix = "${local.lab08_name}${random_string.rid.result}"
  lab13_name_with_postfix = "${local.lab13_name}${random_string.rid.result}"
  lab14_name_with_postfix = "${local.lab14_name}${random_string.rid.result}"
  user_name               = "demouser"
  user_passowrd           = "Azuredemo@2020"
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

data "azurerm_client_config" "current" {}

resource "random_string" "rid" {
  length  = 6
  special = false
}

resource "random_integer" "rint" {
  min = 10000
  max = 99999
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "az900rg" {
  name     = local.group_name
  location = "southeastasia"

  tags = {
    environment = local.group_name
  }
}

## LAB-01
# Create virtual network
resource "azurerm_virtual_network" "lab01vnet" {
  name                = "${local.lab01_name_with_postfix}-Vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.az900rg.location
  resource_group_name = azurerm_resource_group.az900rg.name

  tags = {
    environment = local.group_name
  }
}

# Create subnet
resource "azurerm_subnet" "lab01subnet" {
  name                 = "${local.lab01_name_with_postfix}-Subnet"
  resource_group_name  = azurerm_resource_group.az900rg.name
  virtual_network_name = azurerm_virtual_network.lab01vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "lab01publicip" {
  name                = "${local.lab01_name_with_postfix}-PublicIP"
  location            = azurerm_resource_group.az900rg.location
  resource_group_name = azurerm_resource_group.az900rg.name
  allocation_method   = "Dynamic"
  domain_name_label   = lower(local.lab01_name_with_postfix)

  tags = {
    environment = local.group_name
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "lab01nsg01" {
  name                = "${local.lab01_name_with_postfix}-NSG01"
  location            = azurerm_resource_group.az900rg.location
  resource_group_name = azurerm_resource_group.az900rg.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_security_rule" "nsgrulerdp" {
  name                        = "RDP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = "*"
  destination_port_range      = "3389"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.az900rg.name
  network_security_group_name = azurerm_network_security_group.lab01nsg01.name
}

resource "azurerm_network_security_rule" "nsgrulehttp" {
  name                        = "HTTP"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = "*"
  destination_port_range      = "80"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.az900rg.name
  network_security_group_name = azurerm_network_security_group.lab01nsg01.name
}

# Create network interface
resource "azurerm_network_interface" "lab01nic" {
  name                = "${local.lab01_name_with_postfix}-NIC"
  location            = azurerm_resource_group.az900rg.location
  resource_group_name = azurerm_resource_group.az900rg.name

  ip_configuration {
    name                          = "${local.lab01_name_with_postfix}-NicConfig"
    subnet_id                     = azurerm_subnet.lab01subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lab01publicip.id
  }

  tags = {
    environment = local.group_name
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nsgrelation01" {
  network_interface_id      = azurerm_network_interface.lab01nic.id
  network_security_group_id = azurerm_network_security_group.lab01nsg01.id
}

# Create virtual machine
resource "azurerm_windows_virtual_machine" "lab01vm" {
  name                  = lower(replace(local.lab01_name_with_postfix, "-", ""))
  location              = azurerm_resource_group.az900rg.location
  resource_group_name   = azurerm_resource_group.az900rg.name
  network_interface_ids = [azurerm_network_interface.lab01nic.id]
  size                  = "Standard_B4ms"

  os_disk {
    name                 = "${lower(replace(local.lab01_name_with_postfix, "-", ""))}OsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  computer_name  = local.lab01_name
  admin_username = local.user_name
  admin_password = local.user_passowrd

  tags = {
    environment = local.group_name
  }
}

## LAB-02
# Create Container Instance
resource "azurerm_container_group" "lab02ci" {
  name                = local.lab02_name_with_postfix
  location            = azurerm_resource_group.az900rg.location
  resource_group_name = azurerm_resource_group.az900rg.name
  ip_address_type     = "public"
  dns_name_label      = lower(local.lab02_name_with_postfix)
  os_type             = "Linux"

  container {
    name   = "hello-world"
    image  = "microsoft/aci-helloworld:latest"
    cpu    = "2"
    memory = "4"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  tags = {
    environment = local.group_name
  }
}

## LAB-03-Virtual-Network-Peering
# Create virtual network
resource "azurerm_virtual_network" "lab03vnet" {
  name                = "${local.lab03_name_with_postfix}-Vnet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.az900rg.location
  resource_group_name = azurerm_resource_group.az900rg.name

  tags = {
    environment = local.group_name
  }
}

# Create subnet
resource "azurerm_subnet" "lab03subnet" {
  name                 = "${local.lab03_name_with_postfix}-Subnet"
  resource_group_name  = azurerm_resource_group.az900rg.name
  virtual_network_name = azurerm_virtual_network.lab03vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "lab03publicip" {
  name                = "${local.lab03_name_with_postfix}-PublicIP"
  location            = azurerm_resource_group.az900rg.location
  resource_group_name = azurerm_resource_group.az900rg.name
  allocation_method   = "Dynamic"
  domain_name_label   = lower(local.lab03_name_with_postfix)

  tags = {
    environment = local.group_name
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "lab03nsg01" {
  name                = "${local.lab03_name_with_postfix}-NSG01"
  location            = azurerm_resource_group.az900rg.location
  resource_group_name = azurerm_resource_group.az900rg.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_security_rule" "lab03nsgrulerdp" {
  name                        = "RDP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = "*"
  destination_port_range      = "3389"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.az900rg.name
  network_security_group_name = azurerm_network_security_group.lab03nsg01.name
}

resource "azurerm_network_security_rule" "lab03nsgrulehttp" {
  name                        = "HTTP"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = "*"
  destination_port_range      = "80"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.az900rg.name
  network_security_group_name = azurerm_network_security_group.lab03nsg01.name
}

# Create network interface
resource "azurerm_network_interface" "lab03nic" {
  name                = "${local.lab03_name_with_postfix}-NIC"
  location            = azurerm_resource_group.az900rg.location
  resource_group_name = azurerm_resource_group.az900rg.name

  ip_configuration {
    name                          = "${local.lab03_name_with_postfix}-NicConfig"
    subnet_id                     = azurerm_subnet.lab03subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lab03publicip.id
  }

  tags = {
    environment = local.group_name
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "lab03nsgrelation01" {
  network_interface_id      = azurerm_network_interface.lab03nic.id
  network_security_group_id = azurerm_network_security_group.lab03nsg01.id
}

# Create virtual machine
resource "azurerm_windows_virtual_machine" "lab03vm" {
  name                  = lower(replace(local.lab03_name_with_postfix, "-", ""))
  location              = azurerm_resource_group.az900rg.location
  resource_group_name   = azurerm_resource_group.az900rg.name
  network_interface_ids = [azurerm_network_interface.lab03nic.id]
  size                  = "Standard_B4ms"

  os_disk {
    name                 = "${lower(replace(local.lab03_name_with_postfix, "-", ""))}OsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  computer_name  = local.lab03_name
  admin_username = local.user_name
  admin_password = local.user_passowrd

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_network_peering" "lab01to03peering" {
  name                      = "lab01tolab03"
  resource_group_name       = azurerm_resource_group.az900rg.name
  virtual_network_name      = azurerm_virtual_network.lab01vnet.name
  remote_virtual_network_id = azurerm_virtual_network.lab03vnet.id
}

resource "azurerm_virtual_network_peering" "lab03to01peering" {
  name                      = "lab03tolab01"
  resource_group_name       = azurerm_resource_group.az900rg.name
  virtual_network_name      = azurerm_virtual_network.lab03vnet.name
  remote_virtual_network_id = azurerm_virtual_network.lab01vnet.id
}

## LAB-04-Storage
resource "azurerm_storage_account" "lab04" {
  name                     = lower(local.lab04_name)
  resource_group_name      = azurerm_resource_group.az900rg.name
  location                 = azurerm_resource_group.az900rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = local.group_name
  }
}


resource "azurerm_storage_container" "lab04blob" {
  name                  = lower(local.lab04_name)
  storage_account_name  = azurerm_storage_account.lab04.name
  container_access_type = "blob"
}

resource "azurerm_cdn_profile" "lab04" {
  name                = local.lab04_name_with_postfix
  resource_group_name = azurerm_resource_group.az900rg.name
  location            = azurerm_resource_group.az900rg.location
  sku                 = "Standard_Verizon"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_cdn_endpoint" "lab04" {
  name                = lower(local.lab04_name_with_postfix)
  profile_name        = azurerm_cdn_profile.lab04.name
  location            = azurerm_resource_group.az900rg.location
  resource_group_name = azurerm_resource_group.az900rg.name

  origin {
    name       = "consents-documents"
    host_name  = "${azurerm_storage_account.lab04.name}.blob.core.windows.net"
    http_port  = 80
    https_port = 443
  }

  origin_host_header = ""
}

## LAB-05-SQLDATABASE
resource "azurerm_sql_server" "lab05" {
  name                         = lower(replace(local.lab05_name_with_postfix, "-", ""))
  resource_group_name          = azurerm_resource_group.az900rg.name
  location                     = azurerm_resource_group.az900rg.location
  version                      = "12.0"
  administrator_login          = local.user_name
  administrator_login_password = local.user_passowrd
}

resource "azurerm_sql_firewall_rule" "lab0501" {
  name                = "AlllowAzureServices"
  resource_group_name = azurerm_resource_group.az900rg.name
  server_name         = azurerm_sql_server.lab05.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_sql_firewall_rule" "lab0502" {
  name                = "Client_ip"
  resource_group_name = azurerm_resource_group.az900rg.name
  server_name         = azurerm_sql_server.lab05.name
  start_ip_address    = chomp(data.http.myip.body)
  end_ip_address      = chomp(data.http.myip.body)
}

resource "azurerm_sql_database" "lab05" {
  name                             = lower(replace(local.lab05_name_with_postfix, "-", ""))
  resource_group_name              = azurerm_resource_group.az900rg.name
  location                         = azurerm_resource_group.az900rg.location
  server_name                      = azurerm_sql_server.lab05.name
  edition                          = "Standard"
  requested_service_objective_name = "S0"

  import {
    storage_uri                  = "https://mctcontent.blob.core.windows.net/az900/Northwind.bacpac"
    storage_key                  = "65jEcBHuLZUIeUNowXZRp988kwIh2ErQ6vpBM1BEQjFSj8dEASCtUP9YfX8BF2u1ulJQ4WOsAj6z9zmso0jPKw=="
    storage_key_type             = "StorageAccessKey"
    administrator_login          = local.user_name
    administrator_login_password = local.user_passowrd
    authentication_type          = "SQL"
  }
}

## LAB-06-IOT-HUB
resource "azurerm_iothub" "lab06" {
  name                = lower(replace(local.lab06_name_with_postfix, "-", ""))
  resource_group_name = azurerm_resource_group.az900rg.name
  location            = azurerm_resource_group.az900rg.location

  sku {
    name     = "F1"
    capacity = "1"
  }

  tags = {
    environment = local.group_name
  }
}

## LAB-07-AZURE-FUNCTION
resource "azurerm_storage_account" "lab07" {
  name                     = lower(replace(local.lab07_name_with_postfix, "-", ""))
  resource_group_name      = azurerm_resource_group.az900rg.name
  location                 = azurerm_resource_group.az900rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_app_service_plan" "lab07" {
  name                = lower(replace(local.lab07_name_with_postfix, "-", ""))
  location            = azurerm_resource_group.az900rg.location
  resource_group_name = azurerm_resource_group.az900rg.name

  sku {
    tier = "Dynamic"
    size = "Y1"
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_function_app" "lab07" {
  name                       = lower(replace(local.lab07_name_with_postfix, "-", ""))
  location                   = azurerm_resource_group.az900rg.location
  resource_group_name        = azurerm_resource_group.az900rg.name
  app_service_plan_id        = azurerm_app_service_plan.lab07.id
  storage_account_name       = azurerm_storage_account.lab07.name
  storage_account_access_key = azurerm_storage_account.lab07.primary_access_key

  tags = {
    environment = local.group_name
  }
}

## LAB-08-WEB-APP
resource "azurerm_app_service_plan" "lab08" {
  name                = lower(replace(local.lab08_name_with_postfix, "-", ""))
  location            = azurerm_resource_group.az900rg.location
  resource_group_name = azurerm_resource_group.az900rg.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "lab08" {
  name                = lower(replace(local.lab08_name_with_postfix, "-", ""))
  location            = azurerm_resource_group.az900rg.location
  resource_group_name = azurerm_resource_group.az900rg.name
  app_service_plan_id = azurerm_app_service_plan.lab08.id

  site_config {
    linux_fx_version = "DOTNETCORE|3.1"
  }
}

## LAB-13-KEY-VALUT
resource "azurerm_key_vault" "lab13" {
  name                        = lower(replace(local.lab13_name_with_postfix, "-", ""))
  location                    = azurerm_resource_group.az900rg.location
  resource_group_name         = azurerm_resource_group.az900rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_enabled         = true
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = "a53a335e-5b21-4ee9-95b6-66f95ad57c6f"

    key_permissions = [
      "backup", "create", "decrypt", "delete", "encrypt", "get", "import", "list", "purge",
      "recover", "restore", "sign", "unwrapKey", "update", "verify", "wrapKey"
    ]

    secret_permissions = [
      "backup", "delete", "get", "list", "purge", "recover", "restore", "set"
    ]

    storage_permissions = [
      "backup", "delete", "deletesas", "get", "getsas", "list", "listsas",
      "purge", "recover", "regeneratekey", "restore", "set", "setsas", "update"
    ]

    certificate_permissions = [
      "get", "getissuers", "list", "listissuers"
    ]
  }

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  tags = {
    environment = local.group_name
  }
}

## LAB-14-COSMOS-DB
resource "azurerm_cosmosdb_account" "lab14" {
  name                = lower(replace(local.lab14_name_with_postfix, "-", ""))
  location            = azurerm_resource_group.az900rg.location
  resource_group_name = azurerm_resource_group.az900rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 10
    max_staleness_prefix    = 200
  }

  geo_location {
    location          = azurerm_resource_group.az900rg.location
    failover_priority = 0
  }
}

resource "azurerm_container_group" "lab14" {
  name                = "${lower(replace(local.lab14_name_with_postfix, "-", ""))}aci"
  location            = azurerm_resource_group.az900rg.location
  resource_group_name = azurerm_resource_group.az900rg.name
  ip_address_type     = "public"
  dns_name_label      = "${lower(replace(local.lab14_name_with_postfix, "-", ""))}aci"
  os_type             = "linux"

  container {
    name   = "vote-aci"
    image  = "microsoft/azure-vote-front:cosmosdb"
    cpu    = "0.5"
    memory = "1.5"
    ports {
      port     = 80
      protocol = "TCP"
    }

    secure_environment_variables = {
      "COSMOS_DB_ENDPOINT"  = azurerm_cosmosdb_account.lab14.endpoint
      "COSMOS_DB_MASTERKEY" = azurerm_cosmosdb_account.lab14.primary_master_key
      "TITLE"               = lower(replace(local.lab14_name_with_postfix, "-", ""))
      "VOTE1VALUE"          = "Cats"
      "VOTE2VALUE"          = "Dogs"
    }
  }
}