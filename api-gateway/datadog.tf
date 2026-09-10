########################################
# DATADOG SYNTHETICS (uptime da API publica)
########################################

resource "datadog_synthetics_test" "api_uptime" {
  name      = "${local.project_name} - API Gateway Uptime"
  type      = "api"
  subtype   = "http"
  status    = "live"
  locations = ["aws:${var.aws_region}"]
  tags      = ["env:${local.project_name}", "managed-by:terraform"]

  request_definition {
    method  = "GET"
    url     = "${trimsuffix(aws_apigatewayv2_stage.default.invoke_url, "/")}/actuator/health"
    timeout = 30
  }

  assertion {
    type     = "statusCode"
    operator = "is"
    target   = "200"
  }

  options_list {
    tick_every = 300

    retry {
      count    = 2
      interval = 300
    }
  }
}
