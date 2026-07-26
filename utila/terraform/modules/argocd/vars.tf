variable "namespace" {
  description = "Kubernetes namespace in which Argo CD will be installed"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "Argo CD Helm chart version"
  type        = string
}

variable "github_repository_url" {
  description = "GitHub repository managed by Argo CD"
  type        = string
}

variable "github_repository_branch" {
  description = "Git branch monitored by the Argo CD app-of-apps"
  type        = string
  default     = "main"
}

variable "app_of_apps_path" {
  description = "Path inside the Git repository containing Argo CD applications"
  type        = string
  default     = "utila/argocd"
}