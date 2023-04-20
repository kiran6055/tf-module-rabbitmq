# creating Iam role for ansible mechanism to have ansible pull mechanism
resource "aws_iam_role" "rabbitmqrole" {
  name = "${var.env}-${var.component}-rolenew"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = merge(
    local.common_tags,
    { Name = "${var.env}-${var.component}-rolenew" }
  )
}

# creating instance profile for role
resource "aws_iam_instance_profile" "profile" {
  name = "${var.env}-${var.component}-role"
  role = aws_iam_role.rabbitmqrole.name
}

#creating  policy to the role with the help of UI creating JSon code
resource "aws_iam_policy" "policy" {
  name        = "${var.env}-${var.component}-parameter-store-policy"
  path        = "/"
  description = "${var.env}-${var.component}-parameter-store-policy"


  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameterHistory",
          "ssm:GetParametersByPath",
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        "Resource" : [
          "arn:aws:ssm:us-east-1:742313604750:parameter/${var.env}.${var.component}*"
        ]
      },
      {
        "Sid" : "VisualEditor1",
        "Effect" : "Allow",
        "Action" : "ssm:DescribeParameters",
        "Resource" : "*"
      }
    ]
  })
}

#attaching role with policy
resource "aws_iam_role_policy_attachment" "role-attach" {
  role       = aws_iam_role.rabbitmqrole.name
  policy_arn = aws_iam_policy.policy.arn
}


# creating securoty group for Rabbitmq
resource "aws_security_group" "rabbitmq" {
  name        = "${var.env}-rabbitmq-security-group"
  description = "${var.env}-rabbitmq-security-group"
  vpc_id      = var.vpc_id
  ingress {
    description = "rabbitmq"
    from_port   = 5672
    to_port     = 5672
    protocol    = "tcp"
    cidr_blocks = var.allow_cidr
  }

  ingress {
      description = "ssh"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.bastion_cidr
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(
    local.common_tags,
    { Name = "${var.env}-rabbitmq-security-group" }
  )
}



// we moved service to ec2 node for rabbitmq, because our app doesn't support it

#resource "aws_mq_broker" "rabbitmq" {
#  broker_name        = "${var.env}-rabbitmq"
#  deployment_mode    = var.deployment_mode
#  engine_type        = var.engine_type
#  engine_version     = var.engine_version
#  host_instance_type = var.host_instance_type
# security_groups    = [aws_security_group.rabbitmq.id]
#  subnet_ids         = var.deployment_mode == "SINGLE_INSTANCE" ? [var.subnet_ids[0]] : var.subnet_ids

#  configuration {
#    id       = aws_mq_configuration.rabbitmq.id
#    revision = aws_mq_configuration.rabbitmq.latest_revision
#  }

#  encryption_options {
#    use_aws_owned_key = false
#    kms_key_id =data.aws_kms_key.key.arn
#  }

#  user {
#    username = data.aws_ssm_parameter.USER.value
#    password = data.aws_ssm_parameter.PASS.value
#  }
#}


# creating aws ssm parameter user for rabbitmq for running and adding schemaload which is given in app main

#resource "aws_ssm_parameter" "rabbitmq_endpoint" {
#  name  = "${var.env}.rabbitmq.Endpoint"
#  type  = "String"
#  value = replace(replace(aws_mq_broker.rabbitmq.instances.0.endpoints.0, "amqps://", ""), ":5671", "")
#}

#creating spot instance
resource "aws_spot_instance_request" "rabbitmq" {
  ami                       = data.aws_ami.centos8.image_id
  instance_type             = "t3.small"
  subnet_id                 = var.subnet_ids[0]
  vpc_security_group_ids    = [aws_security_group.rabbitmq.id]
  wait_for_fulfillment      = true
  user_data                 = base64encode(templatefile("${path.module}/user-data.sh", { component = "rabbitmq", env = var.env }))
  iam_instance_profile      = aws_iam_instance_profile.profile.name

  tags = merge(
    local.common_tags,
    { Name = "${var.env}-rabbitmq" }
  )
}

# creating route 53 record
resource "aws_route53_record" "rabbitmq" {
  zone_id = "Z05909301HWY2LI69YHHG"
  name    = "rabbitmq-${var.env}.kiranprav.link"
  type    = "A"
  ttl     = 30
  records = [aws_spot_instance_request.rabbitmq.private_ip]
}