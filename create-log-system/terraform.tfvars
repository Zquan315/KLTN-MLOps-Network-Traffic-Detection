# Value for variables in create-log-system
# Load Balancer
load_balancer_type_value = "application" # "application" or "network"
http_port_value = 80
# EC2 Instance
ami_id_value = "ami-0f9de6e2d2f067fca" # Amazon Ubuntu 22.04, SSD Volume Type
instance_type_value = "t3.large"
key_name_value = "KLTN" # your key pair name
volume_size_value = 30
volume_type_value = "gp2" # General Purpose SSD (gp2)
desired_capacity_value = 2
min_size_value = 2
max_size_value = 4
user_data_path_value = "../script/log-system.sh"
# Route53
route53_zone_name_value = "logs.qm.uit"
route53_record_type_value = "A"

# CodeDeploy application and deployment group
code_deploy_app_name_value = "code_deploy_app"
compute_platform_value = "Server" 
deployment_group_name_value = "code_deploy_deployment_group"
deployment_option_value = "WITH_TRAFFIC_CONTROL" # "WITH_TRAFFIC_CONTROL" - loadbalancer or "WITHOUT_TRAFFIC_CONTROL" - no loadbalancer
# CodeBuild project
code_build_project_name_value = "codebuild_project"

# CodePipeline
code_pipeline_name_value = "codePipeline"
github_repo_value = "KLTN-Log-system-app"
github_owner_value = "Zquan315"