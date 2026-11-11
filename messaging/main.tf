terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  project_name = "ofisy"

  # Tópico em que cada microsserviço publica seus eventos
  topics = ["service-order", "billing", "stock", "execution"]

  # Fila que cada microsserviço consome
  queues = ["service-order", "billing", "stock", "execution", "notification"]

  # Roteamento tópico -> fila, filtrado pelo campo type do envelope
  subscriptions = {
    service-order-execution = {
      topic  = "service-order"
      queue  = "execution"
      events = ["ServiceOrderCancelled"]
    }
    service-order-notification = {
      topic  = "service-order"
      queue  = "notification"
      events = ["ServiceOrderFinished"]
    }
    billing-stock = {
      topic  = "billing"
      queue  = "stock"
      events = ["QuoteCreated", "QuoteUpdated", "QuoteReproved"]
    }
    billing-service-order = {
      topic  = "billing"
      queue  = "service-order"
      events = ["QuoteSentForApproval", "QuoteApproved", "PaymentConfirmed", "QuoteCancelled"]
    }
    billing-notification = {
      topic  = "billing"
      queue  = "notification"
      events = ["QuoteSentForApproval", "PaymentCheckoutCreated", "PaymentConfirmed", "PaymentFailed"]
    }
    billing-execution = {
      topic  = "billing"
      queue  = "execution"
      events = ["QuoteApproved"]
    }
    stock-billing = {
      topic  = "stock"
      queue  = "billing"
      events = ["StockConsumed", "StockConsumptionFailed"]
    }
    stock-notification = {
      topic  = "stock"
      queue  = "notification"
      events = ["StockLow"]
    }
    stock-service-order = {
      topic  = "stock"
      queue  = "service-order"
      events = ["StockRefunded"]
    }
    execution-service-order = {
      topic  = "execution"
      queue  = "service-order"
      events = ["ExecutionStarted", "AllExecutionsCompleted"]
    }
    execution-stock = {
      topic  = "execution"
      queue  = "stock"
      events = ["AllExecutionsCancelled"]
    }
  }
}
