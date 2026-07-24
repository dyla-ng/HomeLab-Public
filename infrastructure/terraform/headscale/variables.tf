variable "headscale_endpoint" {
  type        = string
  description = "The HTTP/gRPC API endpoint of the Headscale server."
  default     = "https://hs.example.com:43923"
}


variable "headscale_api_key" {
  type        = string
  description = "The API key used to authenticate with the Headscale server."
  sensitive   = true
}
