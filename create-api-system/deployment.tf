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
          image             = "bqmxnh/arf-ids-mlops:latest"
          image_pull_policy = "Always"

          port {
            container_port = 8000
          }

          env {
            name  = "ENV"
            value = "production"
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

  # Đảm bảo cluster + access entry đã sẵn sàng
  depends_on = [
    module.eks,
    aws_eks_access_entry.cluster_admin_access,
    aws_eks_access_policy_association.cluster_admin_policy
  ]
}