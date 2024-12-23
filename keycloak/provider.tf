terraform {
  required_providers {
    keycloak = {
      source = "mrparkers/keycloak"
      version = "4.4.0"
    }
  }
}

variable "keycloak_url" {
  type = string
}

variable "keycloak_username" {
  type = string
}

variable "keycloak_password" {
  type = string
}

provider "keycloak" {
  client_id     = "admin-cli"
  username      = var.keycloak_username
  password      = var.keycloak_password
  url           = var.keycloak_url
  tls_insecure_skip_verify = true
}
