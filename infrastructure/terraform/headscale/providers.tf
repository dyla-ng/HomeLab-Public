terraform {
  required_version = ">= 1.5.0"
  required_providers {
    headscale = {
      source  = "awlsring/headscale"
      version = ">= 0.5.1"
    }
  }
}

provider "headscale" {
  endpoint = var.headscale_endpoint
  api_key  = var.headscale_api_key
}
