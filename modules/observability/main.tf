# CloudWatch dashboards + X-Ray tracing + alarms

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "${var.name}-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "EKS Node CPU Utilization"
          metrics = [["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name]]
          period  = 300
          stat    = "Average"
          region  = var.region
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "RDS CPU Utilization"
          metrics = [["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${var.name}-postgres"]]
          period  = 300
          stat    = "Average"
          region  = var.region
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "ALB Request Count"
          metrics = [["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.name]]
          period  = 60
          stat    = "Sum"
          region  = var.region
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title = "Redis Cache Hits vs Misses"
          metrics = [
            ["AWS/ElastiCache", "CacheHits", "CacheClusterId", "${var.name}-redis"],
            ["AWS/ElastiCache", "CacheMisses", "CacheClusterId", "${var.name}-redis"]
          ]
          period = 300
          stat   = "Sum"
          region = var.region
        }
      }
    ]
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU utilization above 80%"

  dimensions = {
    DBInstanceIdentifier = "${var.name}-postgres"
  }

  alarm_actions = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []
}

resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "${var.name}-high-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 50
  alarm_description   = "ALB 5xx errors above 50 per minute"

  alarm_actions = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []
}

# X-Ray sampling rule
resource "aws_xray_sampling_rule" "this" {
  rule_name      = "${var.name}-default"
  priority       = 1000
  version        = 1
  reservoir_size = 1
  fixed_rate     = 0.05 # Sample 5% of requests
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = "*"
  resource_arn   = "*"
}

# X-Ray group for filtering traces
resource "aws_xray_group" "this" {
  group_name        = var.name
  filter_expression = "service(\"${var.name}\")"
}
