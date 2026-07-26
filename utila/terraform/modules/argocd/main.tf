resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version

  wait    = true
  atomic  = true
  timeout = 900

  values = [
    yamlencode({
      crds = {
        install = true
        keep    = true
      }

      configs = {
        params = {
          "server.insecure" = true
        }

        repositories = {
          github = {
            name = "github"
            type = "git"
            url  = var.github_repository_url
          }
        }
      }

      server = {
        service = {
          type = "ClusterIP"
        }
      }

      extraObjects = [
        {
          apiVersion = "argoproj.io/v1alpha1"
          kind       = "Application"

          metadata = {
            name      = "app-of-apps"
            namespace = var.namespace
          }

          spec = {
            project = "default"

            source = {
              repoURL       = var.github_repository_url
              targetRevision = var.github_repository_branch
              path           = var.app_of_apps_path
              directory = {
                recurse = true
              }
            }

            destination = {
              server    = "https://kubernetes.default.svc"
              namespace = var.namespace
            }

            syncPolicy = {
              automated = {
                prune    = true
                selfHeal = true
              }

              syncOptions = [
                "CreateNamespace=true"
              ]
            }
          }
        }
      ]
    })
  ]
}