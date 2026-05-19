output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.skillpulse.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.skillpulse.public_dns
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = "ssh -i ~/.ssh/terraform-pem-keypair.pem ubuntu@${aws_instance.skillpulse.public_ip}"
}
