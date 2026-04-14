output "instance_id" {
  value = aws_instance.link_monitor.id
}

output "public_ip" {
  value = aws_instance.link_monitor.public_ip
}
