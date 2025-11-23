resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.46.8"

  cleanup_on_fail = true

  # ---- KHÔNG BAO GIỜ INSTALL CRDs → tránh stuck destroy ----
  set {
    name  = "installCRDs"
    value = true
  }

  # ---- Disable webhook (nguyên nhân số 2 gây stuck) ----
  set {
    name  = "notifications.enabled"
    value = false
  }

  # ---- Expose load balancer ----
  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  # ---- Optional: để access không cần TLS ----
  set {
    name  = "server.extraArgs[0]"
    value = "--insecure"
  }

  depends_on = [
    kubernetes_namespace.argocd
  ]
}

# Optional chờ pod start
resource "time_sleep" "wait_for_argocd" {
  depends_on      = [helm_release.argocd]
  create_duration = "30s"
}
