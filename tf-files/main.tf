# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group

resource "aws_alb_target_group" "app-lb-tg" {
  # Creates an Application Load Balancer (ALB) target group named "phonebook-lb-tg".
  name        = "phonebook-lb-tg"
  port        = 80 # The port on which the targets receive traffic (HTTP).
  protocol    = "HTTP" # The protocol to use for routing traffic to the targets.
  vpc_id      = data.aws_vpc.selected.id # Associates the target group with the selected VPC.
  target_type = "instance" # Specifies that the targets registered with this group are EC2 instances.


  health_check {
    healthy_threshold   = 2  # The number of consecutive health check successes required before considering an unhealthy target as healthy.
    unhealthy_threshold = 3 # The number of consecutive health check failures required before considering a target unhealthy.
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb

resource "aws_alb" "app-lb" {
  # Creates an Application Load Balancer (ALB) with the name "phonebook-lb-tf".
  # The name must be unique within your AWS account.
  name               = "phonebook-lb-tf" # Must be unique
  ip_address_type    = "ipv4" # Specifies the IP address type as IPv4 for the load balancer.

  # Sets the load balancer to be internet-facing.
  # If set to true, the load balancer is only accessible within a private network.
  internal           = false # If true, it can only be used in a private network
  load_balancer_type = "application" # Type of load balancer

  # Associates the ALB with the specified security group.
  # The security group controls the traffic allowed to and from the load balancer.
  security_groups    = [aws_security_group.alb-sg.id]

  # Specifies the subnets to attach to the load balancer.
  # The subnets are fetched using a data block.
  subnets            = data.aws_subnets.pb-subnets.ids
}


# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener

resource "aws_alb_listener" "app-listener" {
  # Associates this listener with the specified load balancer by its ARN.
  load_balancer_arn = aws_alb.app-lb.arn
  port              = 80
  protocol          = "HTTP"

  # Defines the default action the listener will take for incoming requests. If the incoming request does not match any specific rule, this default action is applied
  default_action {
    type             = "forward" # This means the listener will direct incoming traffic to a specific target group
    target_group_arn = aws_alb_target_group.app-lb-tg.arn # It is the ARN of the previously defined target group. This means the listener will forward the incoming HTTP requests to this target group
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template
# https://developer.hashicorp.com/terraform/language/functions/templatefile

resource "aws_launch_template" "asg-lt" {
  name                   = "phonebook-lt" # Creates a launch template named "phonebook-lt"
  image_id               = data.aws_ami.al2023.id
  instance_type          = "t2.micro"
  key_name               = var.key-name

  #Associates the instances with the specified security group by its ID, which controls the inbound and outbound traffic.
  vpc_security_group_ids = [aws_security_group.server-sg.id]

  # Provides user data to configure the instance at launch.
  # The user data script is encoded in base64 and references a template file "userdata.sh".
  # The template file is populated with the database endpoint, git token, and git name.
  user_data              = base64encode(templatefile("userdata.sh", { db-endpoint = aws_db_instance.db-server.address, user-data-git-token = var.git-token, user-data-git-name = var.git-name }))
  tag_specifications {
    resource_type = "instance" # Specifies that these tags are for EC2 instances.
    tags = {
      Name = "Web Server of Phonebook App" # Tag with key "Name" and value "Web Server of Phonebook App"
    }
  }
}


# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group

resource "aws_autoscaling_group" "app-asg" {
  max_size                  = 3 # Sets the maximum number of instances in the Auto Scaling Group to 3.
  min_size                  = 1 # Sets the minimum number of instances in the Auto Scaling Group to 1.
  desired_capacity          = 1 # Sets the desired capacity of instances in the Auto Scaling Group to 1.
  name                      = "phonebook-asg"
  health_check_grace_period = 300 # Sets the grace period for health checks to 300 seconds (5 minutes).
  health_check_type         = "ELB" # Specifies that the health check type is "ELB" (Elastic Load Balancer).
  target_group_arns         = [aws_alb_target_group.app-lb-tg.arn] # Associates the Auto Scaling Group with the specified target group.
  vpc_zone_identifier       = aws_alb.app-lb.subnets # Specifies the subnets for the Auto Scaling Group, using the subnets from the ALB.

  # Configures the launch template to be used by the Auto Scaling Group.
  launch_template {
    id      = aws_launch_template.asg-lt.id # References the ID of the previously defined launch template.
    version = aws_launch_template.asg-lt.latest_version # Uses the latest version of the launch template.
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance

resource "aws_db_instance" "db-server" {
  instance_class              = "db.t3.micro"
  allocated_storage           = 20
  vpc_security_group_ids      = [aws_security_group.db-sg.id] # Associates the database instance with the specified security group to control inbound and outbound traffic.
  allow_major_version_upgrade = false # Prevents major version upgrades of the database engine to avoid potential compatibility issues.
  auto_minor_version_upgrade  = true # Allows automatic minor version upgrades for the database engine to ensure security and stability updates.
  backup_retention_period     = 0 # Sets the backup retention period to 0 days, meaning no automated backups are retained.
  identifier                  = "phonebook-app-db" # Assigns a unique identifier to the database instance. This is name of RDS
  db_name                     = "phonebook"  # Value from phonebook-app.py
  engine                      = "mysql" # Sets the database engine to MySQL.
  engine_version              = "8.0.28" # Specifies the version of the MySQL engine to use.
  username                    = "admin" # Value from phonebook-app.py
  password                    = "Oliver_1" # Value from phonebook-app.py
  monitoring_interval         = 0
  multi_az                    = false # Indicates that the database instance is not deployed across multiple Availability Zones.
  port                        = 3306
  publicly_accessible         = false # Specifies that the database instance is not publicly accessible, enhancing security
  skip_final_snapshot         = true # Skips the final snapshot when the database instance is deleted, which speeds up the deletion process. so that it does not take snapshoot
}


# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record

resource "aws_route53_record" "phonebook" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "phonebook.${var.hosted-zone}"  # Defines the DNS name for the record. The full name will be "phonebook.<hosted-zone>".
  type    = "A" # Specifies the type of DNS record. Here, it is an "A" record, which maps a name to an IP address.

  alias {
    name                   = aws_alb.app-lb.dns_name # Sets the DNS name of the ALB (Application Load Balancer) as the alias target.
    zone_id                = aws_alb.app-lb.zone_id # Sets the hosted zone ID of the ALB as the alias target.
    evaluate_target_health = true # Enables evaluation of the target health. Route 53 will only route traffic to healthy targets.
  }
}


