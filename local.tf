
locals {
  # username that terraform will use to ssh to the node(s)
  user = "pazmedina"

  # the filename of the private key used to ssh to the node(s)
  private_key = "id_rsa"

  
  nodes = {
    node1 = {
      hostname = "Kubermaster"
      ip_addr  = "192.168.1.192"
      role     = ["controlplane", "worker", "etcd"]
    },
    node2 = {
      hostname = "Kubernode1"
      ip_addr  = "192.168.1.139"
      role     = ["worker", "etcd"]
    }
  }

}
