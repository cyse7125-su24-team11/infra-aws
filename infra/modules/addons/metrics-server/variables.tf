variable "eks_name" {
  default = "cve-eks"
}

variable "region" {
  default = "us-east-1"
}
variable "username" {
  
}
variable "password" {
  
}

variable "metrics_server_name" {
  default = "metrics-server"
}

variable "metrics_server_repo" {
  default = "https://raw.githubusercontent.com/cyse7125-su24-team11/helm-metrics-server/main"
}

variable "metrics_chart" {
  default = "metrics-server" 
}

variable "chart_version" {
  default = "0.1.0"
}
variable "helm_repo_username" {
  default = "maheshpoojaryneu"
}

variable "helm_repo_token" {
  
}