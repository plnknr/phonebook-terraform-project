# Load Balancer sec group
resource "aws_security_group" "alb-sg" {
  # Creates a security group named "ALBSecurityGroup" within the specified VPC.
  name   = "ALBSecurityGroup"
  vpc_id = data.aws_vpc.selected.id # Associates the security group with the selected VPC.

  # Adds tags to the security group for identification and management purposes.
  tags = {
    Name = "TF_ALBSecurityGroup"
  }

  # Ingress rules: define inbound traffic that is allowed.
  ingress {
    from_port   = 80 # Starting port for the rule (HTTP).
    protocol    = "tcp" # Protocol for the rule.
    to_port     = 80 # Ending port for the rule (HTTP).
    cidr_blocks = ["0.0.0.0/0"] # Allows inbound traffic from any IP address.
  }

  # Egress rules: define outbound traffic that is allowed.
  egress {
    from_port   = 0 # Starting port for the rule.
    protocol    = "-1" # Protocol for the rule (-1 means all protocols).
    to_port     = 0 # Ending port for the rule.
    cidr_blocks = ["0.0.0.0/0"] # Allows outbound traffic to any IP address.
  }

}

# Server sec-group auto-scaling ile oluşacak sec-group
resource "aws_security_group" "server-sg" {
  name   = "WebServerSecurityGroup"
  vpc_id = data.aws_vpc.selected.id
  tags = {
    Name = "TF_WebServerSecurityGroup"
  }

  ingress {
    from_port       = 80
    protocol        = "tcp"
    to_port         = 80
    security_groups = [aws_security_group.alb-sg.id] # Allows inbound traffic from the specified security group.
  }

  # we used for troubleshooting
  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "db-sg" {
  name   = "RDSSecurityGroup"
  vpc_id = data.aws_vpc.selected.id
  tags = {
    "Name" = "TF_RDSSecurityGroup"
  }
  ingress {
    security_groups = [ aws_security_group.server-sg.id ] # Allows inbound traffic from the specified security group.
    from_port       = 3306
    protocol        = "tcp"
    to_port         = 3306
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = -1
    to_port     = 0
  }
}