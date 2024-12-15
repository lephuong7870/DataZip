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

# ClickHouse Cold PV File 
resource "kubernetes_manifest" "clickhouse-pv-cold" {
    depends_on = [ kubernetes_namespace.clickhouse ]
    manifest = yamldecode(file(var.pv_cold_file_path))
}

# ClickHouse Hot PV File 
resource "kubernetes_manifest" "clickhouse-pv-hot" {
    depends_on = [ kubernetes_manifest.clickhouse-pv-cold ]
    manifest = yamldecode(file(var.pv_hot_file_path))
}

# ClickHouse Cold PVC File 
resource "kubernetes_manifest" "clickhouse-pvc-cold" {
    depends_on = [ kubernetes_manifest.clickhouse-pv-hot ]
    manifest = yamldecode(file(var.pvc_cold_file_path))
}

# ClickHouse Hot PVC File 
resource "kubernetes_manifest" "clickhouse-pvc-hot" {
    depends_on = [ kubernetes_manifest.clickhouse-pvc-cold ]
    manifest = yamldecode(file(var.pvc_hot_file_path))
}

# ClickHouse ConfigMAP File 
resource "kubernetes_manifest" "clickhouse-configmap" {
    depends_on = [ kubernetes_manifest.clickhouse-pvc-hot ]
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

# SuperSet PV File 
resource "kubernetes_manifest" "superset-pv" {
    depends_on = [ kubernetes_namespace.superset ]
    manifest = yamldecode(file(var.superset_pv_file_path))
}

# SuperSet PVC File 
resource "kubernetes_manifest" "superset-pvc" {
    depends_on = [ kubernetes_manifest.superset-pv ]
    manifest = yamldecode(file(var.superset_pvc_file_path))
}


# SuperSet Using Helm
# Helm release for Superset with custom values.yaml
resource "helm_release" "superset" {
    depends_on = [ kubernetes_manifest.superset-pvc ]
    name       = var.superset_name
    namespace  = var.namespace_superset
    chart      = var.chart_path  # Path to local Helm chart
    
    values = [file(var.values_file)]  # Use your custom values.yaml file
    # Optional: Wait for the release to be fully deployed before finishing
    wait = true
    
    # Optional: Timeout for Helm install
    timeout = 600  # in seconds
}


# External data source to retrieve service details
data "external" "clickhouse_service_details" {
  program = ["bash", "-c", <<EOT
SERVICE_NAME=$(kubectl get svc -n clickhouse -o json | jq -r '.items[] | select(.metadata.name=="clickhouse-service")')
NODE_PORT=$(echo "$SERVICE_NAME" | jq -r '.spec.ports[0].nodePort')
NODE_IP=$(kubectl get nodes -o json | jq -r '.items[0].status.addresses[] | select(.type=="ExternalIP").address')
echo "{\"node_port\": \"$NODE_PORT\", \"node_ip\": \"$NODE_IP\"}"
EOT
  ]
}

# External data source to fetch IP and port details
data "external" "superset_service_details" {
  depends_on = [helm_release.superset] # Ensure Helm release is installed first
  program = ["bash", "-c", <<EOT
SERVICE_NAME=$(kubectl get svc -n ${var.namespace_superset} -o json | jq -r '.items[] | select(.metadata.name=="${helm_release.superset.name}")')
NODE_PORT=$(echo "$SERVICE_NAME" | jq -r '.spec.ports[0].nodePort')
NODE_IP=$(kubectl get nodes -o json | jq -r '.items[0].status.addresses[] | select(.type=="ExternalIP").address')
echo "{\"node_port\": \"$NODE_PORT\", \"node_ip\": \"$NODE_IP\"}"
EOT
  ]
}
