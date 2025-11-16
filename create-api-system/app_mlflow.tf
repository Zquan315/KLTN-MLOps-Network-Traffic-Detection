resource "kubernetes_deployment" "mlflow_server" {
  metadata {
    name      = "mlflow-server"
    namespace = "default"
    labels = {
      app = "mlflow-server"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "mlflow-server"
      }
    }

    template {
      metadata {
        labels = {
          app = "mlflow-server"
        }
      }

      spec {
        container {
          name              = "mlflow"
          image             = "ghcr.io/mlflow/mlflow:latest"
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 5000
          }

          env {
            name  = "BACKEND_STORE_URI"
            value = "sqlite:///mlflow.db"
          }

          env {
            name  = "ARTIFACT_ROOT"
            value = "s3://${data.terraform_remote_state.infra.outputs.api_model_bucket_name}/mlflow-artifacts"
          }

          env {
            name  = "AWS_DEFAULT_REGION"
            value = "us-east-1"
          }

          env {
            name  = "MLFLOW_S3_IGNORE_TLS"
            value = "true"
          }

          command = ["/bin/sh", "-c"]
          args = [
            "mlflow server --backend-store-uri=$BACKEND_STORE_URI --default-artifact-root=$ARTIFACT_ROOT --host=0.0.0.0 --port=5000 --allowed-hosts='*' --cors-allowed-origins='*'"
          ]

          volume_mount {
            name       = "mlflow-storage"
            mount_path = "/mlflow"
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

        volume {
          name = "mlflow-storage"
          empty_dir {}
        }
      }
    }
  }

}


resource "kubernetes_service" "mlflow_service" {
  metadata {
    name      = "mlflow-service"
    namespace = "default"
    labels = {
      app = "mlflow-server"
    }
  }

  spec {
    selector = {
      app = "mlflow-server"
    }

    port {
      port        = 80
      target_port = 5000
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }

  depends_on = [
    kubernetes_deployment.mlflow_server,
    time_sleep.wait_for_lb_controller
  ] 
}
