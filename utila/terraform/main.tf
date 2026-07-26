locals {
  name_prefix = "${var.environment}-proxyless-grpc"

  cluster_name              = "${local.name_prefix}-gke"
  network_name              = "${local.name_prefix}-vpc"
  subnet_name               = "${local.name_prefix}-subnet"
  pods_range_name           = "${local.name_prefix}-pods"
  services_range_name       = "${local.name_prefix}-services"
  node_service_account_name = "${local.name_prefix}-nodes"
  router_name               = "${local.name_prefix}-router"
  nat_name                  = "${local.name_prefix}-nat"

  common_labels = merge(
    var.additional_labels,
    {
      environment = var.environment
      managed_by  = "terraform"
      assignment  = "proxyless-grpc"
    }
  )

  node_labels = merge(
    var.additional_node_labels,
    {
      environment = var.environment
      managed_by  = "terraform"
      workload    = "general"
    }
  )
}

resource "google_project_service" "required" {
  for_each = var.required_apis

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "18.1.0"

  project_id   = var.project_id
  network_name = local.network_name
  routing_mode = var.routing_mode

  subnets = [
    {
      subnet_name           = local.subnet_name
      subnet_ip             = var.subnet_cidr
      subnet_region         = var.region
      subnet_private_access = true
    }
  ]

  secondary_ranges = {
    (local.subnet_name) = [
      {
        range_name    = local.pods_range_name
        ip_cidr_range = var.pods_cidr
      },
      {
        range_name    = local.services_range_name
        ip_cidr_range = var.services_cidr
      }
    ]
  }

  depends_on = [google_project_service.required]
}

module "cloud_nat" {
  source  = "terraform-google-modules/cloud-nat/google"
  version = "7.0.0"

  project_id = var.project_id
  region     = var.region
  network    = module.vpc.network_name

  create_router = true
  router        = local.router_name
  name          = local.nat_name

  min_ports_per_vm = var.nat_min_ports_per_vm

  depends_on = [
    google_project_service.required,
    module.vpc,
  ]
}

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "44.3.0"

  project_id = var.project_id
  name       = local.cluster_name
  region     = var.region
  zones      = var.zones

  regional = true

  network            = module.vpc.network_name
  network_project_id = var.project_id
  subnetwork         = local.subnet_name
  ip_range_pods      = local.pods_range_name
  ip_range_services  = local.services_range_name

  enable_private_nodes    = var.enable_private_nodes
  enable_private_endpoint = var.enable_private_endpoint
  master_ipv4_cidr_block  = var.master_ipv4_cidr_block

  master_authorized_networks = var.master_authorized_networks

  release_channel    = var.release_channel
  kubernetes_version = var.kubernetes_version

  deletion_protection = var.deletion_protection

  identity_namespace = "enabled"

  datapath_provider = var.datapath_provider
  network_policy    = var.network_policy

  http_load_balancing             = var.http_load_balancing
  horizontal_pod_autoscaling      = var.horizontal_pod_autoscaling
  enable_vertical_pod_autoscaling = var.enable_vertical_pod_autoscaling
  dns_cache                       = var.enable_dns_cache
  gce_pd_csi_driver               = var.enable_gce_pd_csi_driver

  monitoring_enable_managed_prometheus = var.enable_managed_prometheus

  enable_shielded_nodes = var.enable_shielded_nodes

  maintenance_start_time = var.maintenance_start_time

  cluster_resource_labels = local.common_labels

  create_service_account = true
  service_account_name   = local.node_service_account_name
  grant_registry_access  = var.grant_registry_access

  remove_default_node_pool = true

  node_pools = [
    {
      name                        = var.node_pool_name
      machine_type                = var.node_machine_type
      node_locations              = join(",", var.zones)
      min_count                   = var.node_min_count
      max_count                   = var.node_max_count
      initial_node_count          = var.node_initial_count
      disk_size_gb                = var.node_disk_size_gb
      disk_type                   = var.node_disk_type
      image_type                  = var.node_image_type
      spot                        = var.node_spot
      preemptible                 = false
      auto_repair                 = var.node_auto_repair
      auto_upgrade                = var.node_auto_upgrade
      max_pods_per_node           = var.node_max_pods
      enable_secure_boot          = var.enable_secure_boot
      enable_integrity_monitoring = var.enable_integrity_monitoring
    }
  ]

  node_pools_oauth_scopes = {
    all = var.node_oauth_scopes
  }

  node_pools_labels = {
    all = local.node_labels
  }

  node_pools_tags = {
    all = var.node_tags
  }

  node_pools_metadata = {
    all = {
      disable-legacy-endpoints = "true"
    }
  }

  depends_on = [
    google_project_service.required,
    module.vpc,
    module.cloud_nat,
  ]
}

module "cloud_service_mesh" {
  source = "./modules/cloud-service-mesh"

  providers = {
    # google      = google
    google-beta = google-beta
  }

  project_id               = var.project_id
  region                   = var.region
  environment              = var.environment
  cluster_name             = "${var.environment}-proxyless-grpc-gke"
  grpc_server_neg_name     = "${var.environment}-helloworld-grpc"
  grpc_server_hostname     = "grpc-server.utila.svc.cluster.local"
  grpc_server_port         = 50051
  max_rate_per_endpoint    = 1000

  depends_on = [
    module.gke
  ]
}

# resource "google_project_iam_member" "gke_traffic_director_client" {
#   project = var.project_id
#   role    = "roles/trafficdirector.client"
#   member  = "serviceAccount:${var.gke_node_service_account}"
# }

data "google_project" "current" {
  project_id = var.project_id
}

resource "google_project_iam_member" "grpc_client_traffic_director" {
  project = var.project_id
  role    = "roles/trafficdirector.client"

  member = "principal://iam.googleapis.com/projects/${data.google_project.current.number}/locations/global/workloadIdentityPools/${var.project_id}.svc.id.goog/subject/ns/utila/sa/grpc-client"
}

module "argocd" {
  source = "./modules/argocd"

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
  
  namespace                = var.argocd_namespace
  chart_version            = var.argocd_chart_version
  github_repository_url    = var.argocd_repository_url
  github_repository_branch = var.argocd_repository_branch
  app_of_apps_path         = var.argocd_app_of_apps_path

  depends_on = [
    module.gke
  ]
}