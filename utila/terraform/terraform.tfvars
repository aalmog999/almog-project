# --------------------------------------------------
# Project and environment
# --------------------------------------------------

project_id  = "project-595dfcb1-d16e-4c23-83d"
environment = "dev"


# --------------------------------------------------
# Location
# --------------------------------------------------

region = "europe-west1"

zones = [
  "europe-west1-b",
  "europe-west1-c",
  "europe-west1-d",
]


# --------------------------------------------------
# GKE version
# --------------------------------------------------

release_channel    = "REGULAR"
kubernetes_version = "latest"

deletion_protection = false


# --------------------------------------------------
# Networking
# --------------------------------------------------

routing_mode = "GLOBAL"

# GKE node addresses
subnet_cidr = "10.10.0.0/20"

# Kubernetes pod addresses
pods_cidr = "10.20.0.0/16"

# Kubernetes ClusterIP Service addresses
services_cidr = "10.30.0.0/20"

# GKE control-plane range
master_ipv4_cidr_block = "172.16.0.0/28"


# --------------------------------------------------
# Private cluster
# --------------------------------------------------

enable_private_nodes    = true
enable_private_endpoint = false

# Replace YOUR_PUBLIC_IP with the result of:
# curl -4 https://ifconfig.me
master_authorized_networks = [
  {
    cidr_block   = "147.236.186.202/32"
    display_name = "almog-mac"
  }
]


# --------------------------------------------------
# Cluster networking and addons
# --------------------------------------------------

datapath_provider = "ADVANCED_DATAPATH"

# Dataplane V2 already provides network-policy enforcement.
network_policy = false

http_load_balancing             = true
horizontal_pod_autoscaling      = true
enable_vertical_pod_autoscaling = false
enable_dns_cache                = true
enable_gce_pd_csi_driver        = true
enable_managed_prometheus       = true


# --------------------------------------------------
# Security
# --------------------------------------------------

enable_shielded_nodes       = true
enable_secure_boot          = true
enable_integrity_monitoring = true


# --------------------------------------------------
# Node pool
# --------------------------------------------------

node_pool_name    = "general"
node_machine_type = "e2-standard-2"

# For this regional cluster, counts are applied per zone.
# Three zones with min_count=1 means a minimum of three nodes.
node_min_count     = 1
node_max_count     = 3
node_initial_count = 1

node_disk_size_gb = 50
node_disk_type    = "pd-balanced"
node_image_type   = "COS_CONTAINERD"

node_spot         = false
node_auto_repair  = true
node_auto_upgrade = true
node_max_pods     = 64

grant_registry_access = true

node_oauth_scopes = [
  "https://www.googleapis.com/auth/cloud-platform",
]

node_tags = [
  "gke-node",
  "allow-grpc-health-checks",
]

# ARGOCD
argocd_namespace     = "argocd"
argocd_chart_version = "9.4.15"
argocd_repository_url = "https://github.com/aalmog999/almog-project.git"
argocd_repository_branch = "main"
argocd_app_of_apps_path  = "utila/argocd/dev/argocd_apps"

# --------------------------------------------------
# Labels
# --------------------------------------------------

# The environment label is added automatically from:
# environment = "dev"

additional_labels = {
  application = "grpc-assignment"
}

additional_node_labels = {
  node_type = "general"
}


# --------------------------------------------------
# Maintenance
# --------------------------------------------------

maintenance_start_time = "03:00"


# --------------------------------------------------
# Cloud NAT
# --------------------------------------------------

nat_min_ports_per_vm = 64


# --------------------------------------------------
# Required APIs
# --------------------------------------------------

required_apis = [
  "artifactregistry.googleapis.com",
  "cloudresourcemanager.googleapis.com",
  "compute.googleapis.com",
  "container.googleapis.com",
  "iam.googleapis.com",
  "serviceusage.googleapis.com",
]