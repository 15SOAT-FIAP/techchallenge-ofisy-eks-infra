resource "aws_sns_topic" "this" {
  for_each = toset(local.topics)

  name                        = "${local.project_name}-${each.key}-events.fifo"
  fifo_topic                  = true
  content_based_deduplication = true

  tags = {
    Name = "${local.project_name}-${each.key}-events.fifo"
  }
}
