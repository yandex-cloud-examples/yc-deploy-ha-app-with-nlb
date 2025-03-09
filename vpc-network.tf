# =======================
# Network (VPC) resources
# =======================

// App Network
resource "yandex_vpc_network" "app_net" {
  folder_id = var.folder_id
  name      = "app-net"
}

// App Subnets
resource "yandex_vpc_subnet" "app_subnet" {
  for_each       = var.zone_list
  folder_id      = var.folder_id
  network_id     = yandex_vpc_network.app_net.id
  name           = "app-subnet-${each.key}"
  zone           = "ru-central1-${each.key}"
  v4_cidr_blocks = [each.value]
  route_table_id = yandex_vpc_route_table.app_net_rt.id
}

// NAT Gateway for Outbound Internet Access
resource "yandex_vpc_gateway" "app_net_gateway" {
  folder_id = var.folder_id
  name      = "app-net-gateway"
  shared_egress_gateway {}
}

// Route Table for direct all outbound traffic via
// NAT Gateway
resource "yandex_vpc_route_table" "app_net_rt" {
  folder_id  = var.folder_id
  name       = "app-net-rt"
  network_id = yandex_vpc_network.app_net.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.app_net_gateway.id
  }
}

// NLB Listener Public IP Address
resource "yandex_vpc_address" "app_nlb_ip" {
  folder_id = var.folder_id
  name      = "app-nlb-ip"

  external_ipv4_address {
    zone_id = "ru-central1-d"
  }
}

// SG with active NLB Health Check (HC) rule
resource "yandex_vpc_security_group" "permit_nlb_hc_sg" {
  folder_id  = var.folder_id
  name       = "permit-nlb-hc-sg"
  network_id = yandex_vpc_network.app_net.id

  ingress {
    description    = "icmp"
    protocol       = "ICMP"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "ssh"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "http"
    protocol       = "TCP"
    port           = "443"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "http"
    protocol       = "TCP"
    port           = "80"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description       = "Health checks from NLB"
    protocol          = "TCP"
    predefined_target = "loadbalancer_healthchecks"
  }

  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

// SG with no NLB Health Check rule
// Used for emulate the fail on specific VM/AZ
resource "yandex_vpc_security_group" "block_nlb_hc_sg" {
  folder_id  = var.folder_id
  name       = "block-nlb-hc-sg"
  network_id = yandex_vpc_network.app_net.id

  ingress {
    description    = "icmp"
    protocol       = "ICMP"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "ssh"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "http"
    protocol       = "TCP"
    port           = "443"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
