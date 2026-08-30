########################################
# DATADOG AGENT (Kubernetes resource monitoring)
########################################

resource "kubernetes_namespace" "datadog" {
  metadata {
    name = "datadog"
  }

  depends_on = [
    aws_eks_node_group.main
  ]
}

resource "helm_release" "datadog" {
  name       = "datadog"
  repository = "https://helm.datadoghq.com"
  chart      = "datadog"
  version    = "3.239.0"
  namespace  = kubernetes_namespace.datadog.metadata[0].name

  values = [
    yamlencode({
      datadog = {
        apiKey      = var.datadog_api_key
        site        = var.datadog_site
        clusterName = aws_eks_cluster.main.name

        # Coleta de CPU/memória de nodes e pods via kubelet + kube-state-metrics.
        # Logs (JSON estruturado + correlação de traces) coletados de todos os containers.
        logs = {
          enabled             = true
          containerCollectAll = true
        }
        # APM via hostPort TCP (usado pela app via DD_AGENT_HOST=status.hostIP:8126).
        apm = {
          portEnabled   = true
          socketEnabled = false
        }
        processAgent = {
          enabled           = false
          processCollection = false
        }
      }

      clusterAgent = {
        enabled = true
      }

      agents = {
        containers = {
          agent = {
            resources = {
              requests = {
                cpu    = "100m"
                memory = "200Mi"
              }
              limits = {
                cpu    = "200m"
                memory = "256Mi"
              }
            }
          }
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.datadog
  ]
}
