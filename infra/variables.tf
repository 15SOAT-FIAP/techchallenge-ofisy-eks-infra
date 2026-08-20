variable "aws_region" {
  description = "Região da AWS onde a infraestrutura será criada"
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "ID da conta AWS"
  type        = string
}

variable "role_name" {
  description = "Nome da Role de Execução (ex: LabRole para AWS Academy)"
  type        = string
  default     = "LabRole"
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
  description = "Site do Datadog para onde o Agent envia os dados (ex.: datadoghq.com, us3.datadoghq.com, us5.datadoghq.com, datadoghq.eu)"
  type        = string
  default     = "us5.datadoghq.com"
}
