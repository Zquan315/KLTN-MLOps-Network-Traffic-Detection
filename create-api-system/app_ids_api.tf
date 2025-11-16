resource "kubernetes_deployment" "arf_ids_api" {
  metadata {
    name      = "arf-ids-api"
    namespace = "default"
    labels = {
      app = "arf-ids-api"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "arf-ids-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "arf-ids-api"
        }
      }

      spec {
        container {
          name              = "arf-ids-api"
          image             = "bqmxnh/arf-ids-api:latest"
          image_pull_policy = "Always"

          port {
            container_port = 8000
          }

          env {
            name  = "ENV"
            value = "production"
          }

          env {
            name  = "MODEL_BUCKET"
            value = "arf-ids-model-bucket"
          }

          env {
            name  = "MODEL_VERSION"
            value = "v1.0"
          }

          resources {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "1Gi"
            }
          }
        }
      }
    }
  }

}

resource "kubernetes_service" "arf_ids_api" {
  metadata {
    name = "arf-ids-api-service"
    labels = {
      app = "arf-ids-api"
    }
  }

  spec {
    selector = {
      app = "arf-ids-api"
    }

    port {
      port        = 80
      target_port = 8000
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
  depends_on = [
    kubernetes_deployment.arf_ids_api, 
    time_sleep.wait_for_lb_controller
  ]
}


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