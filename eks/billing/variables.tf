variable "account_id" {
  description = "ID da conta AWS"
  type        = string
}

variable "eks_cluster_role" {
  description = "Nome da Role IAM para o EKS Control Plane (AWS Academy)"
  type        = string
  default     = "LabRole"
}

variable "eks_node_role" {
  description = "Nome da Role IAM para os Worker Nodes do EKS (AWS Academy)"
  type        = string
  default     = "LabRole"
}

variable "datadog_api_key" {
  description = "API Key do Datadog usada pelo Agent para enviar métricas (Organization Secret DD_API_KEY)"
  type        = string
  sensitive   = true
}

variable "datadog_site" {
  description = "Site do Datadog para onde o Agent envia os dados"
  type        = string
  default     = "us5.datadoghq.com"
}
