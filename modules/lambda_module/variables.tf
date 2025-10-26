variable "function_name" { 
    description = "The name of the Lambda function"
    type = string 
}
variable "source_file_path" { 
    type = string 
    description = "Path to the Lambda source code file"
}    
variable "sqs_queue_arn" { 
    type = string 
    description = "The ARN of the SQS queue that Lambda will read from"
}
variable "sender_email" { 
    description = "Email đã xác thực trên SES để gửi" 
    type = string 
}
variable "to_email" {   
    description = "Email nhận cảnh báo"
    type = string
}