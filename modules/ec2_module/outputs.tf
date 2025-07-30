output "ec2_public_id" {
  value = aws_instance.ec2_public.id
}

output "ami_id" {
  value = aws_ami_from_instance.ami.id
}