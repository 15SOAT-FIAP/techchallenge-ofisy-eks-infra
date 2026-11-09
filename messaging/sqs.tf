resource "aws_sqs_queue" "dlq" {
  for_each = toset(local.queues)

  name       = "${local.project_name}-${each.key}-dlq.fifo"
  fifo_queue = true

  tags = {
    Name = "${local.project_name}-${each.key}-dlq.fifo"
  }
}

resource "aws_sqs_queue" "this" {
  for_each = toset(local.queues)

  name       = "${local.project_name}-${each.key}.fifo"
  fifo_queue = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[each.key].arn
    maxReceiveCount     = 5
  })

  tags = {
    Name = "${local.project_name}-${each.key}.fifo"
  }
}

# Permite que os tópicos SNS entreguem mensagens nas filas
resource "aws_sqs_queue_policy" "this" {
  for_each = toset(local.queues)

  queue_url = aws_sqs_queue.this[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.this[each.key].arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = [for topic in aws_sns_topic.this : topic.arn]
        }
      }
    }]
  })
}
