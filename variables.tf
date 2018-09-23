variable "environment" {
  # ENV name
}

variable "image_id" {
  # Image which will be used
}

variable "instance_type" {
  # Application Instance type
  default = "t2.micro"
}

variable "key_name" {
  # Public key name
}

variable "enable_monitoring" {
  # enable detailed monitoring for instances
  default = false
}

variable "vpc_id" {
  # VPC ID 
}

variable "private_subnets" {
  # List of private subnet
  type = "list"
}

variable "public_subnets" {
  # List of subnets for which application can use
  type = "list"
}

variable "availability_zones" {
  # List of availability zones where application can be started (should match to subnets)
  type = "list"
}

variable "min_size" {
  # minimum count of instances in the Autoscaling group
  default = "1"
}

variable "max_size" {
  # maximum count of instances in the Autoscaling group
  default = "1"
}

variable "scaleup_threshold" {
  # information for scaling up CloudWatch metric
  type = "map"

  default = {
    eval_periods = "3"
    period       = "60"
    threshold    = "70"
  }
}

variable "scaledown_threshold" {
  # information for scaling down CloudWatch metric
  type = "map"

  default = {
    eval_periods = "5"
    period       = "60"
    threshold    = "25"
  }
}

variable "associate_public_ip_address" {
  # associate public ip with instance
  default = false
}
