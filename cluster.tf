# Configuramos nuestro cluster como provedor
provider "rke" {
  log_file = "rke_debug.log"
}

# Creamos el cluster
resource rke_cluster "clusterrke" {
  depends_on = [null_resource.next]
  ignore_docker_version = true
  #disable_port_check = true
  dynamic "nodes" {
    for_each = local.nodes
    content {
      # you can use address = nodes.value.ip_addr but this may harm usage with other tf providers
      # otherwise set the ip to name mappings within /etc/hosts
      address = nodes.value.hostname
      user    = local.user
      role    = nodes.value.role
      ssh_key = file("${path.module}/../${local.private_key}")
    }
  }

  ## limited CNIs running on arm64
  network {
    plugin = "flannel"
  }

  ## default to arm64 versions that seem to work
  #system_images {
   # alpine                      = "rancher/rke-tools:v0.1.71"
   # nginx_proxy                 = "rancher/rke-tools:v0.1.71"
   # cert_downloader             = "rancher/rke-tools:v0.1.71"
   # kubernetes_services_sidecar = "rancher/rke-tools:v0.1.71"
   # nodelocal                   = "rancher/rke-tools:v0.1.71"
   # ingress                     = "rancher/nginx-ingress-controller:nginx-0.35.0-rancher2"
   # etcd                        = "rancher/coreos-etcd:v3.4.13-arm64"
  }

  upgrade_strategy {
    drain                  = true
    max_unavailable_worker = "20%"
  }
}
