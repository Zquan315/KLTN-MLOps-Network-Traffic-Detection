resource "aws_sqs_queue" "queue" {
  name                      = var.sqs_queue_name
  delay_seconds             = 0
  receive_wait_time_seconds = 20 
}