output "instance_ip" {
	description = "Public IP of the launced instance"
	value = aws_instance.sample01-instance01.public_ip
}
