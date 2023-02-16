#HTTP LB

resource "google_compute_instance_group_manager" "wordpress" {
  name = "lb-backend-wordpress"
  zone = "us-west1-a"
  named_port {
    name = "http"
    port = 80
  }
  version {
    instance_template = var.instance_template
    name              = "primary"
  }
  base_instance_name = "vm"
  target_size        = 2
}

resource "google_compute_health_check" "wordpress" {
  name               = "wp-http-health-check"
  check_interval_sec = 5
  healthy_threshold  = 2
  http_health_check {
    port               = 80
    port_specification = "USE_FIXED_PORT"
    proxy_header       = "NONE"
    request_path       = "/wp-admin/install.php"
  }
  timeout_sec         = 5
  unhealthy_threshold = 2
}

resource "google_compute_backend_service" "wordpress" {
  name                            = "wp-backend-service"
  connection_draining_timeout_sec = 0
  health_checks                   = [google_compute_health_check.wordpress.id]
  load_balancing_scheme           = "EXTERNAL"
  port_name                       = "http"
  protocol                        = "HTTP"
  session_affinity                = "NONE"
  timeout_sec                     = 30
  backend {
    group           = google_compute_instance_group_manager.wordpress.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}


resource "google_compute_url_map" "wordpress" {
  name            = "wp-map-http"
  default_service = google_compute_backend_service.wordpress.id
}


resource "google_compute_target_http_proxy" "wordpress" {
  name    = "wp-http-lb-proxy"
  url_map = google_compute_url_map.wordpress.id
}

resource "google_compute_global_address" "wordpress" {
  name       = "lb-ipv4-1"
  ip_version = "IPV4"
}
resource "google_compute_global_forwarding_rule" "wordpress" {
  name                  = "wp-http-content-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80-80"
  target                = google_compute_target_http_proxy.wordpress.id
  ip_address            = google_compute_global_address.wordpress.id
}
