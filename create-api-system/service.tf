resource "kubernetes_service" "arf_ids_api" {
  metadata {
    name = "arf-ids-api-service"
    labels = {
      app = "arf-ids-api"
    }
  }

  spec {
    selector = {
      app = kubernetes_deployment.arf_ids_api.metadata[0].labels.app
    }

    port {
      port        = 80
      target_port = 8000
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }
  depends_on = [
    kubernetes_deployment.arf_ids_api
  ]
}
