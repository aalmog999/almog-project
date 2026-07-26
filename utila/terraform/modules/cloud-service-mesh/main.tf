resource "google_network_services_mesh" "grpc_mesh" {
  provider = google-beta

  project     = var.project_id
  name        = "${var.environment}-proxyless-grpc-mesh"
  location    = "global"
  description = "Proxyless gRPC service mesh"
}

data "google_container_cluster" "gke" {
  project  = var.project_id
  name     = var.cluster_name
  location = var.region
}

data "google_compute_network_endpoint_group" "grpc_server" {
  for_each = toset(data.google_container_cluster.gke.node_locations)

  project = var.project_id
  name    = var.grpc_server_neg_name
  zone    = each.value
}

resource "google_compute_health_check" "grpc_server" {
  project = var.project_id
  name    = "${var.environment}-grpc-server-health-check"

  timeout_sec         = var.health_check_timeout_seconds
  check_interval_sec  = var.health_check_interval_seconds
  healthy_threshold   = var.health_check_healthy_threshold
  unhealthy_threshold = var.health_check_unhealthy_threshold

  grpc_health_check {
    port               = var.grpc_server_port
    port_specification = "USE_FIXED_PORT"
  }
}

resource "google_compute_backend_service" "grpc_server" {
  project = var.project_id
  name    = "${var.environment}-grpc-server-backend"

  protocol              = "GRPC"
  load_balancing_scheme = "INTERNAL_SELF_MANAGED"
  locality_lb_policy    = var.locality_lb_policy
  timeout_sec           = var.backend_timeout_seconds

  health_checks = [
    google_compute_health_check.grpc_server.id
  ]

  dynamic "backend" {
    for_each = data.google_compute_network_endpoint_group.grpc_server

    content {
      group                 = backend.value.id
      balancing_mode        = "RATE"
      max_rate_per_endpoint = var.max_rate_per_endpoint
    }
  }
}

resource "google_network_services_grpc_route" "grpc_server" {
  provider = google-beta

  project  = var.project_id
  name     = "${var.environment}-grpc-server-route"
  location = "global"

  hostnames = [
    var.grpc_server_hostname
  ]

  meshes = [
    google_network_services_mesh.grpc_mesh.id
  ]

  rules {
    action {
      destinations {
        service_name = google_compute_backend_service.grpc_server.id
        weight       = 100
      }
    }
  }
}