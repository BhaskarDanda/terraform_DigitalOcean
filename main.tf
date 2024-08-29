# Create a new Web Droplet in the blr1 region
resource "digitalocean_droplet" "web" {
  image  = "ubuntu-20-04-x64"
  name   = "web-1"
  region = "blr1"
  size   = "s-1vcpu-1gb"
}
