resource "google_project_service" "all" {
  for_each           = toset(var.gcp_service_list)
  project            = var.project_number
  service            = each.key
  disable_on_destroy = false
}