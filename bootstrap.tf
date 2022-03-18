resource "null_resource" "kubecluster_bootstrap" {
  triggers = {
    version = "0.1.2"
  }
  for_each = local.nodes
  connection {
    type        = "ssh"
    user        = local.user
    private_key = file("${path.module}/../../../.ssh/${local.private_key}")
    host        = each.value.ip_addr
  }


  provisioner "file" {
    source      = "files/daemon.json"
    destination = "./daemon.json"
  }


  provisioner "remote-exec" {
    inline = [
      # set hostname
      "sudo hostnamectl set-hostname ${each.value.hostname}",
      "if ! grep -qP ${each.value.hostname} /etc/hosts; then echo '127.0.1.1 ${each.value.hostname}' | sudo tee -a /etc/hosts; fi",

      # there is a better way to do this but this will suffice for now
      # populate etc hosts so that hosts can resolve each other
      "if ! grep -q 'kubemaster' /etc/hosts; then echo '192.168.1.142 kubemaster' | sudo tee -a /etc/hosts; fi",
      "if ! grep -q 'kubenode1' /etc/hosts; then echo '192.168.1.139 kubenode1' | sudo tee -a /etc/hosts; fi",

      # date time config (you use UTC...right?!?)
      "sudo timedatectl set-timezone UTC",
      "sudo timedatectl set-ntp true",

      # system & package updates - then lock kernel updates
      "sudo apt-get update -y",
      "sudo apt-get -o Dpkg::Options::='--force-confnew' upgrade -y",
      "sleep 5",
      "sudo apt-get -o Dpkg::Options::='--force-confnew' dist-upgrade -y",
      "sleep 5",
      "sudo apt --fix-broken install -y",
      "sudo apt-mark hold linux-raspi",
      "sudo apt-get -y --purge autoremove",

      # install docker for arm64 (only have focal version right now)
      # for now rancher rke requires a version of docker just little further behind
      "sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common ",
      "echo 'deb [arch=arm64] https://download.docker.com/linux/ubuntu focal stable' | sudo tee /etc/apt/sources.list.d/docker.list",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add",
      "sudo apt-get update -y",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io",
      # rke may want a specific Docker version, or in the cluster.tf you can disable the Docker version check
      #"sudo apt-get install -y docker-ce=5:19.03.14~3-0~ubuntu-focal docker-ce-cli=5:19.03.14~3-0~ubuntu-focal containerd.io",

      # replace the contents of /etc/docker/daemon.json to enable the systemd cgroup driver
      "sudo rm -f /etc/docker/daemon.json",
      "cat ~/daemon.json | sudo tee /etc/docker/daemon.json",
      "rm -f ~/daemon.json",
      "sudo systemctl enable --now docker",

      # check each kernel command line option and append if necessary
      "if ! grep -qP 'cgroup_enable=cpuset' /boot/firmware/cmdline.txt; then sudo sed -i.bck '$s/$/ cgroup_enable=cpuset/' /boot/firmware/cmdline.txt; fi",
      "if ! grep -qP 'cgroup_enable=memory' /boot/firmware/cmdline.txt; then sudo sed -i.bck '$s/$/ cgroup_enable=memory/' /boot/firmware/cmdline.txt; fi",
      "if ! grep -qP 'cgroup_memory=1' /boot/firmware/cmdline.txt; then sudo sed -i.bck '$s/$/ cgroup_memory=1/' /boot/firmware/cmdline.txt; fi",
      "if ! grep -qP 'swapaccount=1' /boot/firmware/cmdline.txt; then sudo sed -i.bck '$s/$/ swapaccount=1/' /boot/firmware/cmdline.txt; fi",

      # allow iptables to see bridged traffic
      "echo 'net.bridge.bridge-nf-call-ip6tables = 1' >> ./k8s.conf",
      "echo 'net.bridge.bridge-nf-call-iptables = 1' >> ./k8s.conf",
      "cat ./k8s.conf | sudo tee /etc/sysctl.d/k8s.conf",
      "rm -f ./k8s.conf",
      "sudo sysctl --system",

      # reboot to confirm the changes are persistent
      "sudo shutdown -r +0"
    ]
  }
}

# wait 90 seconds after the node(s) have rebooted before doing anything else
resource "time_sleep" "wait_90_seconds" {
  depends_on      = [null_resource.kubecluster_bootstrap]
  create_duration = "90s"
}

resource "null_resource" "next" {
  depends_on = [time_sleep.wait_90_seconds]
}
