variable "project_id" {
  description = "Google Cloud project ID."
  type        = string
}

variable "environment" {
  description = "Environment name used in resource names and labels."
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.environment))
    error_message = "environment must start with a lowercase letter and contain only lowercase letters, numbers, or hyphens."
  }
}

variable "region" {
  description = "Region where the regional GKE cluster will be created."
  type        = string
  default     = "europe-west1"
}

variable "zones" {
  description = "Zones used by the regional GKE cluster."
  type        = list(string)

  default = [
    "europe-west1-b",
    "europe-west1-c",
    "europe-west1-d",
  ]
}

variable "routing_mode" {
  description = "VPC routing mode."
  type        = string
  default     = "GLOBAL"

  validation {
    condition     = contains(["GLOBAL", "REGIONAL"], var.routing_mode)
    error_message = "routing_mode must be GLOBAL or REGIONAL."
  }
}

variable "subnet_cidr" {
  description = "Primary subnet CIDR used by GKE nodes."
  type        = string
  default     = "10.10.0.0/20"
}

variable "pods_cidr" {
  description = "Secondary subnet CIDR used by Kubernetes pods."
  type        = string
  default     = "10.20.0.0/16"
}

variable "services_cidr" {
  description = "Secondary subnet CIDR used by Kubernetes Services."
  type        = string
  default     = "10.30.0.0/20"
}

variable "master_ipv4_cidr_block" {
  description = "Private CIDR used by the GKE control plane."
  type        = string
  default     = "172.16.0.0/28"
}

variable "enable_private_nodes" {
  description = "Whether GKE nodes receive private IP addresses only."
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Whether the GKE control-plane endpoint is private-only."
  type        = bool
  default     = false
}

variable "master_authorized_networks" {
  description = "Networks allowed to access the GKE public control-plane endpoint."

  type = list(object({
    cidr_block   = string
    display_name = string
  }))

  default = []
}

variable "release_channel" {
  description = "GKE release channel."
  type        = string
  default     = "REGULAR"

  validation {
    condition = contains(
      ["RAPID", "REGULAR", "STABLE", "EXTENDED", "UNSPECIFIED"],
      var.release_channel
    )

    error_message = "release_channel must be RAPID, REGULAR, STABLE, EXTENDED, or UNSPECIFIED."
  }
}

variable "kubernetes_version" {
  description = "GKE control-plane version. Use latest to select a valid version from the release channel."
  type        = string
  default     = "latest"
}

variable "deletion_protection" {
  description = "Protect the GKE cluster from Terraform deletion."
  type        = bool
  default     = false
}

variable "datapath_provider" {
  description = "GKE datapath provider."
  type        = string
  default     = "ADVANCED_DATAPATH"
}

variable "network_policy" {
  description = "Enable the GKE network-policy addon. Dataplane V2 already enforces network policy."
  type        = bool
  default     = false
}

variable "http_load_balancing" {
  description = "Enable the GKE HTTP load-balancing addon."
  type        = bool
  default     = true
}

variable "horizontal_pod_autoscaling" {
  description = "Enable the Horizontal Pod Autoscaler addon."
  type        = bool
  default     = true
}

variable "enable_vertical_pod_autoscaling" {
  description = "Enable Vertical Pod Autoscaling."
  type        = bool
  default     = false
}

variable "enable_dns_cache" {
  description = "Enable NodeLocal DNSCache."
  type        = bool
  default     = true
}

variable "enable_gce_pd_csi_driver" {
  description = "Enable the Google Persistent Disk CSI driver."
  type        = bool
  default     = true
}

variable "enable_managed_prometheus" {
  description = "Enable Google Managed Service for Prometheus."
  type        = bool
  default     = true
}

variable "enable_shielded_nodes" {
  description = "Enable Shielded GKE nodes."
  type        = bool
  default     = true
}

variable "enable_secure_boot" {
  description = "Enable Secure Boot on GKE nodes."
  type        = bool
  default     = true
}

variable "enable_integrity_monitoring" {
  description = "Enable integrity monitoring on GKE nodes."
  type        = bool
  default     = true
}

variable "node_pool_name" {
  description = "Name of the primary GKE node pool."
  type        = string
  default     = "general"
}

variable "node_machine_type" {
  description = "Machine type used by GKE nodes."
  type        = string
  default     = "e2-standard-2"
}

variable "node_min_count" {
  description = "Minimum number of nodes per zone."
  type        = number
  default     = 1
}

variable "node_max_count" {
  description = "Maximum number of nodes per zone."
  type        = number
  default     = 3
}

variable "node_initial_count" {
  description = "Initial number of nodes per zone."
  type        = number
  default     = 1
}

variable "node_disk_size_gb" {
  description = "Node boot-disk size."
  type        = number
  default     = 50
}

variable "node_disk_type" {
  description = "Node boot-disk type."
  type        = string
  default     = "pd-balanced"
}

variable "node_image_type" {
  description = "Node operating-system image."
  type        = string
  default     = "COS_CONTAINERD"
}

variable "node_spot" {
  description = "Use Spot VMs for the node pool."
  type        = bool
  default     = false
}

variable "node_auto_repair" {
  description = "Enable automatic node repair."
  type        = bool
  default     = true
}

variable "node_auto_upgrade" {
  description = "Enable automatic node upgrades."
  type        = bool
  default     = true
}

variable "node_max_pods" {
  description = "Maximum pods scheduled on each node."
  type        = number
  default     = 64
}

variable "grant_registry_access" {
  description = "Grant GKE nodes access to pull container images."
  type        = bool
  default     = true
}

variable "node_oauth_scopes" {
  description = "OAuth scopes assigned to GKE nodes."
  type        = list(string)

  default = [
    "https://www.googleapis.com/auth/cloud-platform",
  ]
}

variable "node_tags" {
  description = "Additional network tags assigned to GKE nodes."
  type        = list(string)

  default = [
    "gke-node",
    "allow-grpc-health-checks",
  ]
}

variable "additional_labels" {
  description = "Additional labels applied to the GKE cluster."
  type        = map(string)
  default     = {}
}

variable "additional_node_labels" {
  description = "Additional labels applied to GKE nodes."
  type        = map(string)
  default     = {}
}

variable "maintenance_start_time" {
  description = "Daily GKE maintenance start time in UTC."
  type        = string
  default     = "03:00"
}

variable "nat_min_ports_per_vm" {
  description = "Minimum number of Cloud NAT ports allocated per VM."
  type        = number
  default     = 64
}

variable "required_apis" {
  description = "Google APIs enabled before creating the cluster."
  type        = set(string)

  default = [
    "artifactregistry.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "serviceusage.googleapis.com",
  ]
}

variable "argocd_namespace" {
  description = "Namespace for Argo CD"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Argo CD Helm chart version"
  type        = string
}

variable "argocd_repository_url" {
  description = "GitHub repository containing the Argo CD applications"
  type        = string
}

variable "argocd_repository_branch" {
  description = "Git branch monitored by Argo CD"
  type        = string
  default     = "main"
}

variable "argocd_app_of_apps_path" {
  description = "Directory containing the Argo CD Application manifests"
  type        = string
  default     = "utila/argocd"
}