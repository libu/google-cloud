module "apis-setup" {
  source = "./modules/apis-setup/"
  project_number=var.project_number
}
module "network-setup" {
  source         = "./modules/network-setup"
  instance_template = google_compute_instance_template.wordpress.id

}
module "service-accounts-setup" {
  source = "./modules/service-accounts-setup/"
}

##Install wordpress 
data "template_file" "wordpress_install" {
  template = file("wordpress_install.sh")
  vars = {
    database_password = "${google_secret_manager_secret_version.wordpress-database-password.secret_data}"
    database_ip       = "${google_sql_database_instance.instance.ip_address.0.ip_address}"
  }
}
resource "google_compute_instance_template" "wordpress" {
  name = "lb-backend-template"
  disk {
    auto_delete  = true
    boot         = true
    device_name  = "persistent-disk-0"
    mode         = "READ_WRITE"
    source_image = "projects/debian-cloud/global/images/family/debian-11"
    type         = "PERSISTENT"
  }
  machine_type = "n1-standard-1"
  metadata = {
    startup-script = data.template_file.wordpress_install.rendered
  }
  network_interface {
   access_config {
      network_tier = "PREMIUM"
    }
    network    = module.network-setup.private_network
    subnetwork = module.network-setup.private_subnet
  }
  #region = "us-east1"
  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    provisioning_model  = "STANDARD"
  }
  service_account {
    email  = module.service-accounts-setup.vm-sa-email
    scopes = ["sql-admin"]
  }
  tags = ["wordpress"]
}

#



#Wordpress Database

#Install wordpress databse CloudSQL mysql creation

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "instance" {
  provider = google-beta

  name                = "private-instance-${random_id.db_name_suffix.hex}"
  region              = "us-west1"
  database_version    = "MYSQL_5_7"
  depends_on          = [module.network-setup.private_vpc_connection]
  deletion_protection = false

  settings {
    tier = "db-n1-standard-1"
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = module.network-setup.private_network
      enable_private_path_for_google_cloud_services = true
    }
  }
}

resource "google_sql_database" "database" {
  name     = "wp-data"
  instance = google_sql_database_instance.instance.name
}
resource "google_sql_user" "users" {
  name     = "wp-user"
  instance = google_sql_database_instance.instance.name
  password = google_secret_manager_secret_version.wordpress-database-password.secret_data
}
