# Lookup IDS API ingress created by ArgoCD
data "kubernetes_ingress_v1" "api_ingress" {
  metadata {
    name      = "api-ingress"
    namespace = "default"
  }
}

# Lookup MLflow ingress created by ArgoCD
data "kubernetes_ingress_v1" "mlflow_ingress" {
  metadata {
    name      = "mlflow-ingress"
    namespace = "default"
  }
}
