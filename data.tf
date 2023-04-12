data "aws_kms_key" "key" {
  key_id = "alias/roboshop"
}


data "aws_ssm_parameter" "DB_ADMIN_USER" {
  name = "${var.env}.rabbitmq.USER"
}

data "aws_ssm_parameter" "DB_ADMIN_PASS" {
  name = "${var.env}.rabbitmq.PASS"
}