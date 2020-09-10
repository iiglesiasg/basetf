resource "azurerm_storage_blob" "test_blob" {
  name                   = CHANGEME
  storage_account_name   = azurerm_storage_account.test_sta.name
  storage_container_name = azurerm_storage_container.test_con.name
  type                   = "Block"
  source                 = "README.md"
}

output "azurerm_storage_blob" {
  value       = azurerm_storage_blob.test_blob.url
  description = "Blob"
}