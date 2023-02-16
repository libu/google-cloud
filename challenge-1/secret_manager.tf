resource "random_password" "database_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
resource "google_secret_manager_secret" "wordpress-database-password" {
  secret_id = "wordpress-database-password"
  replication {
    automatic = true
  }
}
resource "google_secret_manager_secret_version" "wordpress-database-password" {
  secret      = google_secret_manager_secret.wordpress-database-password.id
  secret_data = random_password.database_password.result
}
/*
data "google_secret_manager_secret_version" "wordpress-database-password" {
  secret = google_secret_manager_secret.wordpress-database-password.id
}
*/