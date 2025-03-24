provider "kubernetes" {
  config_path = "~/.kube/config"
  config_context = "default"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
    config_context = "default"
  }
}

locals {
  cluster_name = "default"
  environment  = "dev"
  gitops_repo  = "https://github.com/gnanieswar195/gitops-repo.git"

  # OSS addons configuration
  oss_addons = {
    enable_kube_prometheus_stack = true  
    enable_prometheus_adapter    = true  
  }
  
  # Merge all addon categories
  addons = merge(
    local.oss_addons,
    {
      kubernetes_version = "1.32" # Add the k8s version you're using
    }
  )
  
  # Metadata for addons
  addons_metadata = {
    cluster_name = local.cluster_name
    environment  = local.environment
    addons_repo_url = local.gitops_repo
    addons_repo_basepath = ""
    addons_repo_path = "addons"
    addons_repo_revision = "main"
  }
  
  # Define ArgoCD applications - including the addons ApplicationSet
  argocd_apps = {
    nginx = file("${path.module}/../apps/nginx.yaml")
    addons = file("${path.module}/../apps/addons.yaml")  # Important - this is needed
  }
}

module "gitops_bridge" {
  source = "gitops-bridge-dev/gitops-bridge/helm"

  cluster = {
    cluster_name = local.cluster_name
    environment  = local.environment
    metadata     = merge(
      {
        repo_url  = local.gitops_repo
        repo_path = "apps"
      },
      local.addons_metadata
    )
    addons = local.addons
  }
  
  apps = local.argocd_apps
}
