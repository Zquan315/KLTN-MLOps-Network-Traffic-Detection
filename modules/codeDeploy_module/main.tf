resource "aws_codedeploy_app" "code_deploy_app" {
    name             = var.code_deploy_app_name
    compute_platform = var.compute_platform
}

resource "aws_codedeploy_deployment_group" "code_deploy_deployment_group" {
    app_name              = aws_codedeploy_app.code_deploy_app.name
    deployment_group_name = var.deployment_group_name
    service_role_arn      = var.code_deploy_role_arn

    deployment_style {
        deployment_type = "IN_PLACE"
        deployment_option = var.deployment_option
    }
    
    autoscaling_groups = var.autoscaling_groups


    deployment_config_name = "CodeDeployDefault.OneAtATime"
    
    load_balancer_info {
        dynamic "target_group_info" {
            for_each = var.target_group_name
            content {
                name = target_group_info.value
            }
        }
    }

    auto_rollback_configuration {
        enabled = true
        events  = ["DEPLOYMENT_FAILURE"]
    }
  
}