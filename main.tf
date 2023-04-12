# creating securoty group for Rabbitmq
resource "aws_security_group" "rds" {
  name        = "${var.env}-Rabbitmq-security-group"
  description = "${var.env}-Rabbitmq-security-group"
  vpc_id      = var.vpc_id
  ingress {
    description = "Rabbitmq"
    from_port   = 5672
    to_port     = 5672
    protocol    = "tcp"
    cidr_blocks = var.allow_cidr
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(
    local.common_tags,
    { Name = "${var.env}-Rabbitmq-security-group" }
  )
}


#rabbitmq configuration
resource "aws_mq_configuration" "Rabbitmq" {
  description    = "${var.env}-Rabbitmq-configuration"
  name           = "${var.env}-Rabbitmq-configuration"
  engine_type    = var.engine_type
  engine_version = var.engine_version

  data = ""
}

#creating rabbitmq

resource "aws_mq_broker" "Rabbitmq" {
  broker_name = "${var.env}-Rabbitmq"

  configuration {
    id       = aws_mq_con figuration.rabbitmq.id
    revision = aws_mq_configuration.rabbitmq.latest_revision
  }

  engine_type        = "ActiveMQ"
  engine_version     = "5.15.9"
  host_instance_type = var.host_instance_type
  security_groups    = [aws_security_group.test.id]

  user {
    username = "ExampleUser"
    password = "MindTheGap"
  }
}

