source "qemu" "vm-rhel" {
  iso_url          = "http://172.20.173.71:8000/rhel-8.6-x86_64-dvd.iso"
  iso_checksum     = "sha256:8cb0dfacc94b789933253d5583a2fb7afce26d38d75be7c204975fe20b7bdf71"
  output_directory = "img"
  vm_name          = "sisvm.qcow2"
  disk_size        = "40G"
  format           = "qcow2"
  cpus             = 4
  memory           = "4096"
  headless         = true
  qemu_binary      = "/usr/libexec/qemu-kvm"
  accelerator      = "kvm"
  http_directory   = "http"
  net_device       = "virtio-net"
  disk_interface   = "virtio"
  boot_wait        = "5s"
  boot_command     = ["<up><tab> inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg inst.text<enter><wait>"]
  communicator     = "none"
  shutdown_timeout = "15m"
}

build {
  sources = ["source.qemu.vm-rhel"]
}
