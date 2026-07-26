variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
}

variable "grpc_server_neg_name" {
  description = "Name configured by the GKE standalone NEG annotation"
  type        = string
}

variable "grpc_server_hostname" {
  description = "Hostname used by the xDS gRPC client"
  type        = string
}

variable "grpc_server_port" {
  description = "gRPC server port"
  type        = number
  default     = 50051
}

variable "health_check_interval_seconds" {
  description = "Health check interval"
  type        = number
  default     = 5
}

variable "health_check_timeout_seconds" {
  description = "Health check timeout"
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Successful checks required for healthy status"
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Failed checks required for unhealthy status"
  type        = number
  default     = 2
}

variable "backend_timeout_seconds" {
  description = "Backend request timeout"
  type        = number
  default     = 30
}

variable "locality_lb_policy" {
  description = "Load-balancing policy used by the gRPC clients"
  type        = string
  default     = "ROUND_ROBIN"
}

variable "max_rate_per_endpoint" {
  description = "Maximum requests per second per NEG endpoint"
  type        = number
  default     = 1000
}