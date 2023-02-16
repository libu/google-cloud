# Wordpress VM network
resource "google_compute_network" "vpc_network" {
  name                    = "app-network"
  auto_create_subnetworks = false
  mtu                     = 1460
}
resource "google_compute_subnetwork" "subnet" {
  name          = "app-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-west1"
  network       = google_compute_network.vpc_network.id
}

#Database
resource "google_compute_global_address" "private_ip_alloc" {
  name          = "private-ip-alloc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
}

# Create a private connection
resource "google_service_networking_connection" "private_vpc" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}


output "private_vpc_connection" {
  value = google_service_networking_connection.private_vpc.id
}

output "private_network" {
  value = google_compute_network.vpc_network.id
}

output "private_subnet" {
  value = google_compute_subnetwork.subnet.id
}
