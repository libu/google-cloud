data "template_file" "wordpress_install" {
  template = "${file("wordpress_install.sh")}"
    vars = {
    database_password = "${google_secret_manager_secret_version.wordpress-database-password.secret_data}"
    database_ip = "${google_sql_database_instance.instance.ip_address.0.ip_address}"
  }
}
module "network-setup" {
  source = "./modules/network"
}
module "sa-setup" {
  source = "./modules/service-account"
}
resource "google_secret_manager_secret" "wordpress-database-password" {
  secret_id = "wordpress-database-password"
  replication {
    automatic = true
  }
}
resource "google_secret_manager_secret_version" "wordpress-database-password" {
  secret = google_secret_manager_secret.wordpress-database-password.id
  secret_data = "${random_id.db_name_suffix.hex}"
}

data "google_secret_manager_secret_version" "wordpress-database-password" {
  secret = google_secret_manager_secret.wordpress-database-password.id
}

#Install wordpress VM creation
resource "google_compute_instance" "wordpress" {
  name         = "wordpress"
  machine_type = "f1-micro"
  zone         = "us-west1-a"
  tags         = ["wordpress"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  # Install wordpress
  metadata_startup_script = data.template_file.wordpress_install.rendered

  network_interface {
    subnetwork = module.network-setup.private_subnet

    access_config {
      # Include this section to give the VM an external IP address
    }
  }
    service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = module.sa-setup.vm-sa-email
    scopes = ["sql-admin"]
  }
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

#Install wordpress databse CloudSQL mysql creation

resource "google_sql_database_instance" "instance" {
  provider = google-beta

  name             = "private-instance-${random_id.db_name_suffix.hex}"
  region           = "us-west1"
  database_version = "MYSQL_5_7"

 depends_on = [module.network-setup.private_vpc_connection]

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