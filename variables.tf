variable "cloud_id" {
  description = "YC cloud-id. Taken from the environment variable."
}

variable "folder_id" {
  description = "YC folder-id. Taken from the environment variable."
}

variable "zone_list" {
  type        = map(string)
  description = "Zones & Subnets list"
  default = {
    a = "10.10.1.0/24"
    b = "10.10.2.0/24"
    d = "10.10.3.0/24"
  }
}

variable "app_name" {
  description = "Application DNS Name."
  default     = "app"
}

variable "app_fqdn" {
  description = "Application FQDN."
  default     = "app.mydom.net"
}

variable "dns_folder_id" {
  description = "DNS Folder Id where public domain is located."
  default     = "b1glv**********qd5g4"
}

variable "dns_zone_name" {
  description = "DNS Zone Name which application belongs to."
  default     = "mydom-net"
}

variable "user_name" {
  description = "VM's administrator user name."
  default     = "admin"
}
