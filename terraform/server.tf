resource "digitalocean_droplet" "web0" {
  image    = "ubuntu-18-04-x64"
  name     = "web0"
  region   = "sgp1"
  size     = "s-1vcpu-1gb"
  ssh_keys = [
    "${digitalocean_ssh_key.P29224.id}",
    "${digitalocean_ssh_key.MBP2011.id}",
    "${digitalocean_ssh_key.Dream.id}",
  ]

  provisioner "remote-exec" {
    script = "scripts/install.sh"
  }

  provisioner "remote-exec" {
    script = "scripts/services.sh"
  }
}
