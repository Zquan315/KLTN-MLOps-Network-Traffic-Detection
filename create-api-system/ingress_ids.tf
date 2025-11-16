resource "kubernetes_ingress_v1" "ids_ingress" {
  metadata {
    name = "ids-ingress"
    annotations = {
      "kubernetes.io/ingress.class"                = "alb"
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"      = "ip"
    }
  }

  spec {
    rule {
      host = "api.qmuit.id.vn"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.arf_ids_api.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }

        path {
          path      = "/predict"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.arf_ids_api.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }

        path {
          path      = "/feedback"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.arf_ids_api.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }

        path {
          path      = "/metrics"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.arf_ids_api.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }

      }
    }
  }

  depends_on = [
    time_sleep.wait_for_lb_controller,
    helm_release.aws_load_balancer_controller,
    kubernetes_service.arf_ids_api,
    kubernetes_service.mlflow_service
  ]
}