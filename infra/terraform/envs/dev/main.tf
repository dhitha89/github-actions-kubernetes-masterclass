terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

module "skillpulse" {
  source        = "../../"
  region        = var.region
  env           = var.env
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name
}

output "ec2_public_ip" {
  value = module.skillpulse.ec2_public_ip
}

output "ssh_command" {
  value = module.skillpulse.ssh_command
}
