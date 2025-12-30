#load balancer
load_balancer_type_value = "application" # Application Load Balancer

# auto scaling group
ami_id_value = "ami-0f9de6e2d2f067fca" # ubuntu 22.04 ami
instance_type_value = "t3.large" # t3.large instance type
key_name_value = "KLTN" # my key pair name
volume_size_value = 30
volume_type_value = "gp2" # General Purpose SSD (gp2) volume type
desired_capacity_value = 2
min_size_value = 2
max_size_value = 4
user_data_path_value = "../script/ids.sh"
