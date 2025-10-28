output "ec2_public_id" {
  value = aws_instance.ec2_public.id
}

output "eip_allocate_ec2_api" {
  value = aws_eip.eip_allocate_ec2_api.public_ip
}