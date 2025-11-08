resource "kubernetes_horizontal_pod_autoscaler_v2" "arf_ids_api_hpa" {
  metadata {
    name      = "arf-ids-api-hpa"
    namespace = "default"
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.arf_ids_api.metadata[0].name
    }

    min_replicas = 2
    max_replicas = 6

    metric {
      type = "Resource"

      resource {
        name = "cpu"

        target {
          type                = "Utilization"
          average_utilization = 60
        }
      }
    }
  }

  depends_on = [
    kubernetes_deployment.arf_ids_api,
    kubernetes_service.arf_ids_api
  ]
}