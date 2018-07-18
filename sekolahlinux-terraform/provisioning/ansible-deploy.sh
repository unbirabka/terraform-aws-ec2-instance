#!/bin/bash
cd /home/ubuntu/ansible-playbook/
ansible-playbook sekolahlinux-playbook.yml -i terraform/aws/sekolahlinux-terraform/provisioning/ansible_hosts --vault-pass=~/.vpass --extra-vars "user_deployment=ubuntu" --skip-tags "updateos"
