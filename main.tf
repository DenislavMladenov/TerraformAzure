terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.25.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "636f8b28-d20d-4971-b6d2-50b57cbce3e9"
  features {}
}

# Generate a random integer to create a globally unique name
#resource "random_integer" "ri" {
#  min = 10000
#  max = 99999
#}

#Create the resource group
resource "azurerm_resource_group" "rg" {
 name     = var.resource_group_name
 location = var.resource_group_location
}



#Create the web app stack service plan
resource "azurerm_service_plan" "appserviceplan" {
  name                = var.app_service_plan_name
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  os_type             = "Linux"
  sku_name            = "F1"
}

#Create the web app
resource "azurerm_linux_web_app" "app" {
  name                = var.app_service_name
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.appserviceplan.id


  site_config {
    application_stack {
      dotnet_version = "6.0"
    }
    always_on = false
  }
  connection_string {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = "Data Source=tcp:${azurerm_mssql_server.azmssql.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.azmssqldb.name};User ID=${azurerm_mssql_server.azmssql.administrator_login};Password=${azurerm_mssql_server.azmssql.administrator_login_password};Trusted_Connection=False; MultipleActiveResultSets=True;"
  }

}
# Create the SQL Server
resource "azurerm_mssql_server" "azmssql" {
  name                         = var.sql_server_name
  resource_group_name          = var.resource_group_name
  location                     = var.resource_group_location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password
}

#Create the SQL Database
resource "azurerm_mssql_database" "azmssqldb" {
  name         = var.sql_database_name
  server_id    = azurerm_mssql_server.azmssql.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  sku_name     = "S0"
}

#Create the SQL Firewall Rule
resource "azurerm_mssql_firewall_rule" "azmssqlfirewallrule" {
  name             = var.firewall_rule_name
  server_id        = azurerm_mssql_server.azmssql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

#Deploy the code from a public GitHub repo
resource "azurerm_app_service_source_control" "azlwa" {
  app_id                 = azurerm_linux_web_app.app.id
  repo_url               = var.repo_URL
  branch                 = "main"
  use_manual_integration = true
}
