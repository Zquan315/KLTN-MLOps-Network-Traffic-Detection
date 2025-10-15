

resource "aws_instance" "ec2_public" {
  associate_public_ip_address = var.associate_public_ip_address
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id_public
  vpc_security_group_ids      = var.security_group_id_public
  key_name                    = var.key_name
  tags = {
    Name = var.ec2_tag_name
  }
  user_data = filebase64(var.user_data_path)
  #iam_instance_profile        = var.ec2_instance_profile_name   
  root_block_device {
    volume_size = var.volume_size
    volume_type = var.volume_type
  }
}

resource "aws_eip" "eip_allocate_ec2_api" {
    network_border_group = "us-east-1"
    instance             = aws_instance.ec2_public.id
    tags = {
        Name = "eip-allocate-ec2-api"
    }
  
}

