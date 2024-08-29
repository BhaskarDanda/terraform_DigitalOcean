# main.tf
variable "do_token" {}
variable "image" {}
variable "ssh_key_name" {}
variable "fingerprint" {}

# Create a new tag
resource "digitalocean_tag" "server" {
  name = "admin"
}

# Configure the DigitalOcean provider
provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_ssh_key" "existing_key" {
  name       = var.ssh_key_name # Provide a name for the resource
}

# Define a DigitalOcean Droplet
resource "digitalocean_droplet" "server" {
  # count  = 1
  name   = "server"#-${count.index}"
  region = "blr1"
  size   = "s-1vcpu-2gb"
  image  = var.image
  tags   = [digitalocean_tag.server.id] 
  
  # SSH key configuration
  ssh_keys = [data.digitalocean_ssh_key.existing_key.id]


  provisioner "remote-exec" {
    inline = [
    "mkdir /home/admin",
    "mkdir -p /home/admin/.ssh",
    "useradd -s /bin/bash --home /home/admin admin",
    "chown -R admin:admin /home/admin",
    "echo 'admin ALL=(ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers",
    "echo 'ssh-rsa ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDDGhLy11EnuKpn1zpV8vOoY50Qe2crD/vEwidAhWxdN6x00S7ZXY5PkZ4/0SL1ClwfqAH3xDt6MZikjkccd3cyeWDGMCtWdx89L2wayF9hf6iJ1xXSO5cfDNZ12+dxcZ2Z6O2CRuvOr3iIn4IYCPM32A7ZIzkQwqpnsMwkRbGuNvxtvAIzo4+2elN4FXeNa+9Z4q2rDoSMFovGCAH5zgvCm9/1HhBnhMwYgGxzyNmA9PnoLSqr5TWz9Nhhfrt4LGOfB/4buVdea0m/AZYlFTBjV6WFiGMC7ExrZWHfOaiKquZ9N/XxW2Hq14N/EGZHKDw4eEo1q4ZNj469SCXSgD3G5ZVwz4p0bhNdkbjTCsr4virImSx8Zq3CtAvxYNQp8txN+w5Plsq9e2sjnZMBK9jdJPAuf15AMrCeW/1PTautIhq+B2DxH9F126FFtUKEWJPTbUkmLKkCnnajKaGGKmMZPBSVFNkXJfF4u6Bv4YepCPC62x24Wodq+4g/QycSAdU= welcome@DESKTOP-4Q1NHRR' >> /home/admin/.ssh/authorized_keys",
    "chmod 700 /home/admin/.ssh",
    "chmod 600 /home/admin/.ssh/authorized_keys",
    "echo 'root:admin' | sudo chpasswd",
    "echo 'admin:admin' | sudo chpasswd",
    # "sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config",
    "sudo systemctl restart sshd",
    
    # Additional commands such as installing packages can be added here
    "sudo yum install wget curl unzip net-tools firewalld -y",
    "sudo yum install epel-release -y"
  ]
    connection {
      type = "ssh"
      host = self.ipv4_address
      user = "root"
      private_key = file("~/.ssh/id_rsa")  # Path to your private key
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Delete resources if creation fails
resource "null_resource" "delete_resources" {
  triggers = {
    instance_id = digitalocean_droplet.server.id
  }

  provisioner "local-exec" {
    command = "echo 'Server creation failed.'"
    # Add additional cleanup commands if needed
  }

  depends_on = [digitalocean_droplet.server]
}

# Output the IP address of the Droplet
output "droplet_ip-1" {
  value = digitalocean_droplet.server.ipv4_address
}
