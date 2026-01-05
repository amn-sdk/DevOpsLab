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
  ami_description = "Amazon Linux 2023 AMI with a Node.js sample app."
  instance_type   = "t3.micro"
  region          = "us-east-2"
  source_ami      = "ami-00e428798e77d38d9"
  ssh_username    = "ec2-user"
}

build {                                               
  sources = ["source.amazon-ebs.amazon_linux"]

  provisioner "file" {                                
    source      = "app.js"
    destination = "/home/ec2-user/app.js"
  }

  provisioner "shell" {                               
    inline = [
      "curl -fsSL https://rpm.nodesource.com/setup_21.x | sudo bash -",
      "sudo yum install -y nodejs"
    ]
    pause_before = "30s"
  }
}