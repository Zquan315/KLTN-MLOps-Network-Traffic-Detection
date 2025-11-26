#load balancer
load_balancer_type_value = "application" # Application Load Balancer
http_port_value = 80 # HTTP port for the Application Load Balancer

# auto scaling group
ami_id_value = "ami-0f9de6e2d2f067fca" # ubuntu 22.04 ami
instance_type_value = "t3.medium" # t3.medium instance type
key_name_value = "KLTN" # my key pair name
volume_size_value = 30
volume_type_value = "gp2" # General Purpose SSD (gp2) volume type
desired_capacity_value = 2
min_size_value = 2
max_size_value = 3
user_data_path_value = "../script/honey_pot.sh"

# lambda function
function_name_value = "send_email_for_honey_pot_alert"
lambda_source_file_path_value = "../lambda_code/"
sender_email_value = "tocongquan315@gmail.com"
to_email_value = "tocongquan315@gmail.com"