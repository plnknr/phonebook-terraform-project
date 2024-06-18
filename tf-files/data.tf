
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc
# Retrieves information about the default VPC in the AWS account.
data "aws_vpc" "selected" {
  default = true
}


# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami
# Retrieves the most recent Amazon Linux 2023 AMI (Amazon Machine Image) provided by Amazon.
data "aws_ami" "al2023" {
  most_recent = true # Gets the most recent version of the AMI.
  owners      = ["amazon"] # Only AMIs owned by Amazon.

  filter {
    name   = "virtualization-type" # Filters for AMIs with hardware virtual machine (HVM) virtualization type.
    values = ["hvm"] 
  }

  filter {
    name   = "architecture" # Filters for AMIs with x86_64 architecture.
    values = ["x86_64"]
  }

  filter {
    name   = "name" # Filters for AMIs with names starting with "al2023-ami-2023".
    values = ["al2023-ami-2023*"]
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets
# Retrieves a list of subnets in the selected VPC that have names starting with "default".
data "aws_subnets" "pb-subnets" {
  filter {
    name   = "vpc-id" # Filters subnets by the VPC ID of the selected VPC.
    values = [data.aws_vpc.selected.id]
  }
  filter { #  Notes:  A load balancer cannot be attached to multiple subnets in the same Availability Zone.
    name   = "tag:Name" # Filters subnets by their name tag, looking for names starting with "default".
    values = ["default*"]
  }
}

# Retrieves information about a specific Route 53 hosted zone by its name.
data "aws_route53_zone" "selected" {
  name         = var.hosted-zone # The name of the hosted zone, specified by the variable "hosted-zone".
}
