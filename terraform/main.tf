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
  oss_addons = {}
  
  # Merge all addon categories
  addons = merge(
    local.oss_addons,
    {
      kubernetes_version = "1.31" # Add the k8s version you're using
    }
  )
  
  # Metadata for addons
  addons_metadata = merge( 
  {
    cluster_name = local.cluster_name
    environment  = local.environment
    addons_repo_url = local.gitops_repo
    addons_repo_basepath = ""
    addons_repo_path = "addons"
    addons_repo_revision = "main"
  },
  {
    workload_repo_url      = local.gitops_repo
    workload_repo_basepath = ""
    workload_repo_path     = "k8s"
    workload_repo_revision = "main"
  }
  )
  
  # Define ArgoCD applications - including the addons and workloads ApplicationSet
  argocd_apps = {
    #nginx = file("${path.module}/../apps/nginx.yaml")
    addons = file("${path.module}/../apps/addons.yaml") 
    workloads = file("${path.module}/../apps/workloads.yaml")
  }
}

module "gitops_bridge" {
  source = "gitops-bridge-dev/gitops-bridge/helm"

  cluster = {
    cluster_name = local.cluster_name
    environment  = local.environment
    metadata     = local.addons_metadata
    addons       = local.addons
}
  apps = local.argocd_apps
}
