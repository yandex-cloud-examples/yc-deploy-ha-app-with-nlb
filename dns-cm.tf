# ===================================
# DNS & Certificate Manager resources
# ===================================

data "yandex_dns_zone" "dns_zone" {
  folder_id = var.dns_folder_id
  name      = var.dns_zone_name
}

// Create DNS record for the App with reserved public ip address
resource "yandex_dns_recordset" "vm_dns_rec" {
  zone_id = data.yandex_dns_zone.dns_zone.id
  name    = var.app_name
  type    = "A"
  ttl     = 300
  data    = ["${yandex_vpc_address.app_nlb_ip.external_ipv4_address.0.address}"]
}

// Create LE certificate request for App
resource "yandex_cm_certificate" "app_le_cert" {
  folder_id   = var.dns_folder_id
  name        = var.app_name
  description = "LE certificate for the ${var.app_name}"
  domains     = ["${var.app_fqdn}"]
  managed {
    challenge_type = "DNS_CNAME"
  }
}

// Create domain validation DNS record for Let's Encrypt service
resource "yandex_dns_recordset" "app_validation_dns_rec" {
  zone_id = data.yandex_dns_zone.dns_zone.id
  name    = yandex_cm_certificate.app_le_cert.challenges[0].dns_name
  type    = yandex_cm_certificate.app_le_cert.challenges[0].dns_type
  data    = [yandex_cm_certificate.app_le_cert.challenges[0].dns_value]
  ttl     = 60
}
