data "kubernetes_ingress_v1" "api_ingress" {
  metadata {
    name      = "api-ingress"
    namespace = "default"
  }
}

data "kubernetes_ingress_v1" "mlflow_ingress" {
  metadata {
    name      = "mlflow-ingress"
    namespace = "mlflow"
  }
}

data "kubernetes_ingress_v1" "argocd_ingress" {
  metadata {
    name      = "argocd-ingress"
    namespace = "argocd"
  }
}

data "kubernetes_ingress_v1" "argo_workflows_ingress" {
  metadata {
    name      = "argo-workflows-server"
    namespace = "argo"
  }
}

