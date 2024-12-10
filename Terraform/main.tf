# Provider Name Kubernetes
provider "kubernetes" {
    config_path = var.kubeconfig_path
}

# Provider Name Helm
provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

# Namespace for ClickHouse
resource "kubernetes_namespace" "clickhouse" {
    metadata {
        name = var.namespace_clickhouse
    }
}

# Namespace for Superset
resource "kubernetes_namespace" "superset" {
    metadata {
        name = var.namespace_superset
    }
}

# ClickHouse PV File 
resource "kubernetes_manifest" "clickhouse-pv" {
    depends_on = [ kubernetes_namespace.clickhouse ]
    manifest = yamldecode(file(var.pv_file_path))
}

# ClickHouse PVC File 
resource "kubernetes_manifest" "clickhouse-pvc" {
    depends_on = [ kubernetes_manifest.clickhouse-pv ]
    manifest = yamldecode(file(var.pvc_file_path))
}

# ClickHouse ConfigMAP File 
resource "kubernetes_manifest" "clickhouse-configmap" {
    depends_on = [ kubernetes_manifest.clickhouse-pvc ]
    manifest = yamldecode(file(var.config_file_path))
}

# ClickHouse Deployment File 
resource "kubernetes_manifest" "clickhouse-deployment" {
    depends_on = [ kubernetes_manifest.clickhouse-configmap ]
    manifest = yamldecode(file(var.deploy_file_path))
}

# ClickHouse Service File 
resource "kubernetes_manifest" "clickhouse-service" {
    depends_on = [ kubernetes_manifest.clickhouse-deployment ]
    manifest = yamldecode(file(var.service_file_path))
}

# SuperSet Using Helm
# Helm release for Superset with custom values.yaml
resource "helm_release" "superset" {
    depends_on = [ var.namespace_superset ]
    name       = var.superset_name
    namespace  = var.namespace_superset
    chart      = var.chart_path  # Path to local Helm chart
    
    values = [file(var.values_file)]  # Use your custom values.yaml file
    # Optional: Wait for the release to be fully deployed before finishing
    wait = true
    
    # Optional: Timeout for Helm install
    timeout = 600  # in seconds
}