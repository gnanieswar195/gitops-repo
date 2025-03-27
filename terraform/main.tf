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
    enable_metrics_server = true
    enable_kube_prometheus_stack = true
    enable_cert_manager = false
  }
  
  # Merge all addon categories
  addons = merge(
    local.oss_addons,
    {
      kubernetes_version = "1.31" # Add the k8s version you're using, just for info purpose
    }
  )
  
  # Metadata for addons and workloads
  addons_and_workloads_metadata = merge( 
  { 
    ##Addons metadata
    addons_repo_url = local.gitops_repo
    addons_repo_basepath = ""
    addons_repo_path = "addons"
    addons_repo_revision = "main"
  },
  {
    ##Workloads metadata
    workload_repo_url      = local.gitops_repo
    workload_repo_basepath = ""
    workload_repo_path     = "k8s"
    workload_repo_revision = "main"
  }
  )
  
  # Define ArgoCD applications - including the addons and workloads ApplicationSet
  argocd_apps = {
    addons = file("${path.module}/../apps/addons.yaml") 
    workloads = file("${path.module}/../apps/workloads.yaml")
  }
}

module "gitops_bridge" {
  source = "gitops-bridge-dev/gitops-bridge/helm"

  cluster = {
    cluster_name = local.cluster_name
    environment  = local.environment
    metadata     = local.addons_and_workloads_metadata
    addons       = local.addons
  }
  apps = local.argocd_apps
}
