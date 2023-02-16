locals {
  function_name        = "fluentd-lambda-extension-example"
  function_runtime     = "go1.x"
  function_mem         = 2048
  function_timeout     = 60
  instance_type        = "t3a.medium"
  instance_volume_type = "gp3"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.16"

  name = local.function_name

  cidr = "10.1.0.0/16"

  azs             = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24"]
  public_subnets  = ["10.1.11.0/24", "10.1.12.0/24"]

  enable_nat_gateway = false # false is just faster

  tags = {
    Name = local.function_name
  }
}


#Get AWS ECS optimized ami
data "aws_ami" "ecs" {
  owners      = ["amazon"]
  most_recent = true
  name_regex  = "^amzn2-ami-ecs-hvm-2.0.\\d{8}-x86_64-ebs"
}

## EC2 instance profile
module "ec2_profile" {
  source  = "terraform-aws-modules/ecs/aws//modules/ecs-instance-profile"
  version = "3.5.0"

  name        = local.function_name
  include_ssm = true
}


# Instance security group for access Kibana
module "instance_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "${local.function_name}-instance"
  vpc_id      = module.vpc.vpc_id
  description = "${local.function_name} instance security group for Kibana"

  ingress_with_cidr_blocks = [
    {
      from_port   = 5601
      to_port     = 5601
      protocol    = "tcp"
      description = "for Kibana access"
      cidr_blocks = "171.246.135.193/32"
    },
    {
      rule        = "all-all"
      cidr_blocks = module.vpc.vpc_cidr_block
    }
  ]

  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

#Create fluentd instance
module "instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  name           = local.function_name
  instance_count = 1

  ami                    = data.aws_ami.ecs.id
  instance_type          = local.instance_type
  vpc_security_group_ids = [module.instance_sg.security_group_id]
  subnet_id              = module.vpc.public_subnets[0]

  iam_instance_profile = module.ec2_profile.iam_instance_profile_id
  user_data_base64     = base64encode(templatefile("${path.module}/templates/_user_data.tpl", {}))

  root_block_device = [
    {
      volume_type = local.instance_volume_type
      volume_size = 30
    }
  ]

  tags = {
    cluster_name = local.function_name
  }
}


# Build function package
module "build_function_package" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "4.0.2"

  create_function = false

  runtime = "python3.9"
  source_path = [
    "${abspath(path.module)}/function/lambda_function.py",
    {
      pip_requirements = "${abspath(path.module)}/function/requirements.txt"
    }
  ]

  build_in_docker = true #false - if want to build without docker
}

module "lambda_layer_extension" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "4.0.2"

  create_layer = true

  layer_name          = "fluentd-lambda-extension"
  description         = "The extention lambda layer to send log to fluentd"
  compatible_runtimes = [local.function_runtime, "python3.9", "nodejs14.x", "nodejs16.x", "python3.8"]

  source_path = [
    {
      path          = "${abspath(path.module)}/../extensions/bin/fluentd-lambda-extension"
      prefix_in_zip = "extensions"
    }
  ]

  build_in_docker = false #false - if want to build without docker
}

# Deploy lambda function from package which build success above resource
module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "4.0.2"

  create_package         = false
  local_existing_package = module.build_function_package.local_filename
  depends_on = [
    module.build_function_package,
    module.lambda_layer_extension
  ]

  function_name = local.function_name
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"

  vpc_subnet_ids         = module.vpc.public_subnets
  vpc_security_group_ids = [module.instance_sg.security_group_id]

  memory_size = local.function_mem
  timeout     = local.function_timeout

  layers = [
    module.lambda_layer_extension.lambda_layer_arn,
  ]

  environment_variables = {
    FLUENTD_HOST = module.instance.private_ip[0]
  }

  create_current_version_allowed_triggers = false
  attach_cloudwatch_logs_policy           = false
  attach_policy_statements                = false
  attach_network_policy                   = true
}
