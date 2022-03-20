
locals {
  # username that terraform will use to ssh to the node(s)
  user = "pazmedina"

  # the filename of the private key used to ssh to the node(s)
  private_key = "id_rsa_rke"
  nodes = {
    Kubemaster = {
      hostname = "Kubemaster"
      ip_addr  = "192.168.1.142"
      role     = ["controlplane", "worker", "etcd"]
    },
    node01 = {
      hostname = "Kubenode01"
      ip_addr  = "192.168.1.139"
      role     = ["worker", "etcd"]
    }
  }

}
