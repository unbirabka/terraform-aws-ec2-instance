#################################################################################
#################################################################################
#################################################################################

provider "aws" {
  region     = "ap-southeast-1"
}

#################################################################################
#################################################################################
#################################################################################

module "ec2_instance" {
  source = "../modules/ec2_instance/"

  instance_count 	= 2
  tags_name		= "webserver-sekolahlinux"
  tags_hostname		= "webserver"
  tags_title_number	= 1

  ami                         = "ami-81cefcfd"
  instance_type               = "c5.xlarge"
  key_name                    = "sekolahlinux"
  monitoring                  = true
  vpc_security_group_ids      = ["sg-3c166256","sg-1c916326"]
  subnet_id                   = "subnet-2736a51e"
  associate_public_ip_address = false
  user_data		      = "./provisioning/userdata.txt"

  root_block_device = {
    volume_size = "100"
  }

  tags = {
    Environtment	= "production"
    CreateBy    	= "terraform"
}
}

#################################################################################
#################################################################################
#################################################################################

resource "null_resource" "sekolahlinux" {
  triggers {
    cluster_instance_ids = "${join("\n", module.ec2_instance.id)}"
  }

  provisioner "local-exec" {
    working_dir = "./provisioning"
    command = "echo '[webserver-ubuntu:vars] \nansible_ssh_private_key_file = /home/ubuntu/.ssh/id_rsa \n\n[webserver-ubuntu:children] \nwebserver-sekolahlinux \n\n[webserver-sekolahlinux]' > ansible_hosts"
  }

  provisioner "local-exec" {
    working_dir = "./provisioning"
    command = "echo '${join("\n", formatlist("%s ansible_host=%s ansible_port=22 ansible_user=ubuntu", module.ec2_instance.tags_hostname, module.ec2_instance.private_ip))}' >> ansible_hosts"
  }

  provisioner "local-exec" {
    working_dir = "./provisioning"
    command = "echo \"PLEASE WAIT 60s\" && sleep 60 && sh ansible-deploy.sh"
  }

}

#################################################################################
#################################################################################
#################################################################################

output "internal_ip" {
  description = "List of public IP addresses assigned to the instances, if applicable"
  value       = "${module.ec2_instance.private_ip}"
}

output "tags" {
  description = "List of public IP addresses assigned to the instances, if applicable"
  value       = "${module.ec2_instance.tags_name}"
}
