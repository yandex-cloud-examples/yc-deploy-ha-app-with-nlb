# =====================================
# Network Load Balancer (NLB) resources
# =====================================

resource "yandex_lb_target_group" "app_nlb_tg" {
  folder_id = var.folder_id
  name      = "app-nlb-tg"
  region_id = "ru-central1"

  // NLB Targets
  dynamic "target" {
    for_each = var.zone_list
    content {
      subnet_id = yandex_vpc_subnet.app_subnet[target.key].id
      address   = cidrhost(yandex_vpc_subnet.app_subnet[target.key].v4_cidr_blocks[0], 10)
    }
  }
}

resource "yandex_lb_network_load_balancer" "app_nlb" {
  name      = "app-nlb"
  folder_id = var.folder_id
  type      = "external"
  region_id = "ru-central1"

  listener {
    name     = "http-443"
    protocol = "tcp"
    port     = 443
    external_address_spec {
      address    = yandex_vpc_address.app_nlb_ip.external_ipv4_address[0].address
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.app_nlb_tg.id

    healthcheck {
      name                = "http"
      interval            = 2
      timeout             = 1
      unhealthy_threshold = 2
      http_options {
        port = 80
        path = "/health"
      }
    }
  }
}
