# =================
# Compute resources
# =================

# YC Cloud resources
data "yandex_compute_image" "vm_image" {
  family = "ubuntu-2404-lts-oslogin"
}


# Service Account for App VMs & CM binding
resource "yandex_iam_service_account" "app_vm_sa" {
  folder_id   = var.folder_id
  name        = "app-vm-sa"
  description = "Service account for App VMs"
}

// Certificate Manager downloader binding
resource "yandex_cm_certificate_iam_binding" "dnld_binding" {
  certificate_id = yandex_cm_certificate.app_le_cert.id
  role           = "certificate-manager.certificates.downloader"
  members        = ["serviceAccount:${yandex_iam_service_account.app_vm_sa.id}"]
}

// App VMs
resource "yandex_compute_instance" "app_vm" {
  for_each           = var.zone_list
  folder_id          = var.folder_id
  name               = "app-vm-${each.key}"
  hostname           = "app-vm-${each.key}"
  platform_id        = "standard-v3"
  zone               = "ru-central1-${each.key}"
  service_account_id = yandex_iam_service_account.app_vm_sa.id
  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.vm_image.id
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.app_subnet[each.key].id
    ip_address         = cidrhost(yandex_vpc_subnet.app_subnet[each.key].v4_cidr_blocks[0], 10)
    nat                = false
    security_group_ids = [yandex_vpc_security_group.permit_nlb_hc_sg.id]
  }

  metadata = {
    user-data = templatefile("app-vm-init.tpl", {
      ADMIN_NAME    = var.user_name
      ADMIN_SSH_KEY = file("~/.ssh/id_ed25519.pub")
      SRV_NAME      = var.app_fqdn
      CERT_ID       = yandex_cm_certificate.app_le_cert.id
      HOSTNAME      = "app-vm-${each.key}"
    })
  }

  depends_on = [yandex_cm_certificate.app_le_cert]
}
