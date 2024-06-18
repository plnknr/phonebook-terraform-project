output "websiteurl" {
  value = "http://${aws_route53_record.phonebook.name}"
  # The value of this output is the full URL of the website using the DNS name created by the Route 53 record.
}

output "dns-name" {
  value = "http://${aws_alb.app-lb.dns_name}"
  # The value of this output is the full DNS name of the Application Load Balancer.
}

output "db-addr" {
  value = aws_db_instance.db-server.address
  # The value of this output is the address (hostname) of the RDS database instance.
}

output "db-endpoint" {
  value = aws_db_instance.db-server.endpoint
  # The value of this output is the full endpoint (including port) of the RDS database instance.
}