packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "amazon_linux" {
  ami_name        = "sample-app-packer-${uuidv4()}"
  ami_description = "Amazon Linux 2 AMI with a Node.js sample app."
  instance_type   = "t3.micro"
  region          = "us-east-2"
  source_ami      = "ami-0900fe555666598a2"
  ssh_username    = "ec2-user"
}

build {
  sources = ["source.amazon-ebs.amazon_linux"]

  provisioner "file" {
    source      = "app.js"
    destination = "/home/ec2-user/app.js"
  }

  provisioner "shell" {
    pause_before = "30s"
    inline = [
      "curl -fsSL https://rpm.nodesource.com/setup_14.x | sudo bash -",
      "sudo yum install -y nodejs"
    ]
  }
}
