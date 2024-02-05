variable "subscription_id" {
  type    = string
  description = "Subcription Id"
}
variable "resource_group" {
  type    = string
  default = "bachtn-demo"
}

variable "location" {
  type    = string
  default = "westus"
}
variable "tags" {
  type = map(string)
  default = {
    "env" = "Udacity-01"
  }
}
variable "address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "dns_server" {
  type    = list(string)
  default = ["10.0.0.4", "10.0.0.5"]
}

variable "subnets" {
  type = list(object({
      name = string
      address_prefix = string
      network_security_group = optional(string)
    })
  )
  default = [ {
    name           = "subnet1"
    address_prefix = "10.0.1.0/24"
  }, {
    name           = "subnet2"
    address_prefix = "10.0.2.0/24"
  }]
}

variable "admin_username" {
  type = string
}
variable "admin_password" {
  type = string
  sensitive   = true
}
variable "image_name" {
  type = string
}