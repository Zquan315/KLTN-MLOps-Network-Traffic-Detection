resource "kubernetes_manifest" "root_app" {
  manifest = yamldecode(file("${path.module}/apps/root-app.yaml"))

  depends_on = [
    helm_release.argocd,
    time_sleep.wait_for_argocd,
  ]
}
