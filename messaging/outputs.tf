output "topic_arns" {
  description = "ARN do tópico SNS de cada microsserviço publicador"
  value       = { for key, topic in aws_sns_topic.this : key => topic.arn }
}

output "queue_urls" {
  description = "URL da fila SQS consumida por cada microsserviço"
  value       = { for key, queue in aws_sqs_queue.this : key => queue.url }
}
