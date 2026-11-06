resource "aws_sns_topic_subscription" "this" {
  for_each = local.subscriptions

  topic_arn            = aws_sns_topic.this[each.value.topic].arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.this[each.value.queue].arn
  raw_message_delivery = true

  filter_policy_scope = "MessageBody"
  filter_policy = jsonencode({
    type = each.value.events
  })

  depends_on = [aws_sqs_queue_policy.this]
}
