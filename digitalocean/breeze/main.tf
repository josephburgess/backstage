resource "digitalocean_ssh_key" "breeze" {
  name       = "Breeze SSH Key"
  public_key = file(var.ssh_public_key_path)
}

resource "digitalocean_droplet" "breeze" {
  image     = "ubuntu-22-04-x64"
  name      = "breeze-app"
  region    = "nyc1"
  size      = "s-1vcpu-1gb"
  ssh_keys  = [digitalocean_ssh_key.breeze.fingerprint]

  user_data = <<-EOF
    #!/bin/bash
    apt update
    apt install -y docker.io docker-compose nginx certbot python3-certbot-nginx
    systemctl enable --now docker

    cat > /etc/nginx/sites-available/breeze.joeburgess.dev << 'NGINX'
    server {
        listen 80;
        server_name breeze.joeburgess.dev;

        location / {
            proxy_pass http://localhost:8080;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
    NGINX

    ln -sf /etc/nginx/sites-available/breeze.joeburgess.dev /etc/nginx/sites-enabled/
    nginx -t && systemctl restart nginx
  EOF
}

resource "digitalocean_domain" "default" {
  name = "joeburgess.dev"
}

resource "digitalocean_record" "breeze" {
  domain = digitalocean_domain.default.name
  type   = "A"
  name   = "breeze"
  value  = digitalocean_droplet.breeze.ipv4_address

  depends_on = [digitalocean_domain.default]
}

output "droplet_ip" {
  value = digitalocean_droplet.breeze.ipv4_address
}

output "breeze_url" {
  value = "http://breeze.joeburgess.dev"
}
