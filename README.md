# Template terraform for create aws instance


## Layout terraform file
```
.
├── aws
    ├── README.MD
    ├── modules
    │   └── ec2_instance
    │       ├── main.tf
    │       ├── outputs.tf
    │       └── variables.tf
    └── sekolahlinux-terraform
        ├── main.tf
        └── provisioning
            ├── ansible_hosts
            ├── ansible-deploy.sh
            └── userdata.txt

```

## How to use terraform aws template 
* export varibale dibawah pada host tempat kita akan menjalankan terraform template

```
export AWS_ACCESS_KEY_ID='XXXXXXXXXXXXXXXXXXXXXXXXXXXX'
export AWS_SECRET_ACCESS_KEY='XXXXXXXXXXXXXXXXXXXXXXXXXXXX'
```

* copy **terraform/aws/sekolahlinux-terraform** dengan nama project yang akan dibuat misalkan menjadi **terraform/aws/sekolahlinux-webserver**

* buka **terraform/aws/sekolahlinux-webserver/main.tf** dan rubah paramater dibawah sesuai dengan project yang akan dibuat

```
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
```

## Variable
didalam terraform terdapat 3 type  variable yaitu **strings, maps, lists, boolean** detailnya kamu bisa baca di link **[type_variable_terraform](https://www.terraform.io/docs/configuration/variables.html)** , berikut dibawah ini paramater yang harus kamu rubah beserta penjelasannya pada template terraform untuk pembuatan instance di aws

* **instance_count**

variable **instance_count** untuk menentukan berapa jumlah instance yang ingin kamu buat dalam sekali execute pada contoh script diatas saya memberikan value 2, yang menandakan saya ingin membuat sebanyak 2 instance

* **tags_name**

variable **tags_name** untuk menentukan Tag Name pada instance aws yang akan kamu buat

* **tags_hostname**

variable **tags_hostname** untuk menentukan Tag Hostname pada instance aws, juga digunakan untuk keperluan generate ansible host, yang mana value dari tag ini akan digunakan sebagai inventory_hostname pada host ansible

* **tags_title_number**

variable **tags_title_number** untuk menentukan angka atau nomer dibelakang value dari tags_name, misal jika kita mengisi value tags ini dengan angka **1** dengan jumlah instance_count **2** makanya numbering akan dimulai dari angka satu seperti ini **(webserver-sekolahlinux1, webserver-sekolahlinux2)** namun jika tags_title_number dimulai dari angka 7 maka hasilnya akan seperti berikut **(webserver-sekolahlinux7, webserver-sekolahlinux8)**

* **ami**

variable **ami** digunakan untuk menentukan ami mana yang akan kita gunakan, pada value ami diatas saya menggunakan ami ubuntu dengan id **ami-81cefcfd** dan nama ami nya **ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-20180522**

* **instance_type**

variable **instance_type** digunakan untuk menentukan size resource untuk instance aws yang kita gunakan, untuk melihat list type instance kalian bisa ke link ini => **[instance_type aws](https://aws.amazon.com/ec2/instance-types/)**

* **key_name**

varibale **key_name** digunakan untuk menentukan ssh_pubkey existing mana yang akan kita inject kedalam instance tersebut

* **monitoring**

variable **monitoring** memiliki type bolean, jadi disini kamu hanya bisa memberi value true atau false, tag ini sendiri berguna untuk mengaktifkan feature moniroting aws pada instance tersebut atau tidak

* **vpc_security_group_ids**

variable **vpc_security_group_ids** digunakan untuk menentukan secgroup pada instance tersebut, value harus berisi secgroup_id, bagaima jika ada lebih dari 1 vpc secgroup, kalian bisa mengisi seperti berikut ["sg-3c166256", "sg-1c916326"]

* **subnet_id**

variable **subnet_id** digunakan untuk menentukan vpc & subnet mana yang akan kita gunakan untuk instance yang akan kita buat

* **associate_public_ip_address**

variable **associate_public_ip_address** memiliki type bolean, dan variable ini digunakan untuk menentukan apakah instance kamu ingin diberikan dynamic public_ip atau tidak

* **user_data**

variable **user_data** digunakan untuk menyisipkan script_bash yang akan dijalankan didalam os intance yang akan kita buat saat pertama kali instance tersebut hidup, misal kita ingin mematikan feature autoupdate saat sebuah instance dengan os ubuntu berjalan pertama kali
  
* **root_block_device**

variable **root_block_device** digunakan untuk menentukan size root disk os dari instance yang akan kita buat, untuk variable ini typenya adalah list didalamnya ada sub default variable **volume_size** pada variable ini kamu tidak dapat sembarangan menambahkan sub variable, hanya sub default variable dari variable **root_block_device** saja yang bisa kamu tambahkan, contoh seperti dibawah

```
  root_block_device = {
    volume_size = "100"
  }
```

* **tags**

variable **tags** digunakan untuk menyisipkan sub tags variable tambahan diluar dari tags default di module **(Name, Hostname)** yang sudah dibuat, disini kamu bisa menambahkan sub tags, sesuai keinginan kamu, type variable tags adalah maps

```
  tags = {
    Environtment	= "production"
    CreateBy        = "terraform"
}
```

## How to run terraform (ikuti urutan dibawah ini untuk eksekusinya)
* **terraform init**

jalankan perintah **terraform init** untuk melakukan download plugin terraform aws dan juga melakukan mapping terhadap module

* **terraform plan**

jalankan perintah **terraform plan** untuk melihat/mereview template terraform sebelum dilakukan implementasi di aws

* **terraform apply**

jalankan perintah **terraform apply** untuk mengeksekusi template terraform dan mengimplementasikan ke aws

## Provisioning terraform AWS
tujuan dari provisioning pada terraform adalah untuk melakukan automasi konfigurasi lebih lanjut terhadap instance yang sudah selesai dibuat dengan terraform

* buka **(hello/terraform/aws/sekolahlinux-webserver/main.tf)** dan rubah paramater dibawah sesuai dengan project yang akan dibuat
```
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
```
tujuan dari provisioning diatas adalah untuk generate file **terraform/aws/sekolahlinux-webserver/provisioning/ansible_hosts**, berdasarkan dari ip_address baik public ataupun private yang dihasilkan dari pembuatan instance dengan terraform, file **ansible_hosts** lalu setelahnya akan menjalankan script **ansible-deploy.sh** untuk melakukan provisioning dengan aws
