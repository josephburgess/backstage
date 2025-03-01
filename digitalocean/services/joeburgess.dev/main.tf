resource "digitalocean_ssh_key" "breeze" {
  name       = "Breeze SSH Key"
  public_key = file(var.ssh_public_key_path)
}

resource "digitalocean_droplet" "breeze" {
  image     = "ubuntu-22-04-x64"
  name      = "breeze-app"
  region    = "nyc1"
  size      = "s-1vcpu-1gb"
  ipv6      = true
  ssh_keys  = [digitalocean_ssh_key.breeze.fingerprint]

  # Copy scripts to the server
  provisioner "file" {
    source      = "${path.module}/scripts/configure_docker.sh"
    destination = "/tmp/configure_docker.sh"
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(var.ssh_private_key_path)
      host        = self.ipv4_address
    }
  }

  provisioner "file" {
    source      = "${path.module}/scripts/configure_nginx.sh"
    destination = "/tmp/configure_nginx.sh"
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(var.ssh_private_key_path)
      host        = self.ipv4_address
    }
  }

  # provisioner "file" {
  #   source      = "${path.module}/scripts/setup_ssl.sh"
  #   destination = "/tmp/setup_ssl.sh"
  #   connection {
  #     type        = "ssh"
  #     user        = "root"
  #     private_key = file(var.ssh_private_key_path)
  #     host        = self.ipv4_address
  #   }
  # }

  provisioner "file" {
    source      = "${path.module}/scripts/init.sh"
    destination = "/tmp/init.sh"
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(var.ssh_private_key_path)
      host        = self.ipv4_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/*.sh",
      "bash /tmp/init.sh"
    ]
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(var.ssh_private_key_path)
      host        = self.ipv4_address
    }
  }
}

resource "digitalocean_domain" "default" {
  name = "joeburgess.dev"
}

resource "digitalocean_reserved_ip" "breeze_ip" {
  region     = digitalocean_droplet.breeze.region
  droplet_id = digitalocean_droplet.breeze.id
}

resource "digitalocean_record" "breeze" {
  domain     = digitalocean_domain.default.name
  type       = "A"
  name       = "breeze"
  value      = digitalocean_reserved_ip.breeze_ip.ip_address
  ttl        = 3600
  depends_on = [digitalocean_domain.default, digitalocean_reserved_ip.breeze_ip]
}

resource "digitalocean_record" "breeze_ipv6" {
  domain     = digitalocean_domain.default.name
  type       = "AAAA"
  name       = "breeze"
  ttl        = 3600
  value      = digitalocean_droplet.breeze.ipv6_address
  depends_on = [digitalocean_domain.default]
}

resource "digitalocean_record" "root" {
  domain     = digitalocean_domain.default.name
  type       = "A"
  name       = "@"
  value      = digitalocean_reserved_ip.breeze_ip.ip_address
  ttl        = 3600
  depends_on = [digitalocean_domain.default, digitalocean_reserved_ip.breeze_ip]
}


resource "digitalocean_record" "root_ipv6" {
  domain     = digitalocean_domain.default.name
  type       = "AAAA"
  name       = "@"
  ttl        = 3600
  value      = digitalocean_droplet.breeze.ipv6_address
  depends_on = [digitalocean_domain.default]
}

resource "digitalocean_record" "www" {
  domain     = digitalocean_domain.default.name
  type       = "A"
  name       = "www"
  value      = digitalocean_reserved_ip.breeze_ip.ip_address
  ttl        = 3600
  depends_on = [digitalocean_domain.default, digitalocean_reserved_ip.breeze_ip]
}

resource "digitalocean_record" "www_ipv6" {
  domain     = digitalocean_domain.default.name
  type       = "AAAA"
  name       = "www"
  ttl        = 3600
  value      = digitalocean_droplet.breeze.ipv6_address
  depends_on = [digitalocean_domain.default]
}

output "reserved_ipv4" {
  value = digitalocean_reserved_ip.breeze_ip.ip_address
}

output "droplet_ipv6" {
  value = digitalocean_droplet.breeze.ipv6_address
}

output "joeburgess_url" {
  value = "https://joeburgess.dev"
}

output "breeze_url" {
  value = "https://breeze.joeburgess.dev"
}

