variable "gcp_service_list" {
    description = "The list of apis necessary for the project"
    type        = list(string)
    default = [
        "compute.googleapis.com",
        "servicenetworking.googleapis.com",
        "sql-component.googleapis.com",
        "sqladmin.googleapis.com",
        "secretmanager.googleapis.com"
    ]
}
variable "project_number" {
  type        = string
  description = "project_number"
  default     = ""
}