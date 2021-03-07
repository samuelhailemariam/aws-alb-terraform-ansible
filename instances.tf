#Create key-pair for logging into EC2 in us-west-2
resource "aws_key_pair" "master-key" {
  key_name   = "apache"
  public_key = file("~/.ssh/apache.pub")
}

#Create EC2 in us-west-2
resource "aws_instance" "web" {
  count = var.instance_count

  ami           = data.aws_ssm_parameter.linuxAmi.value
  instance_type = var.instance_type
  key_name      = aws_key_pair.master-key.key_name

  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  subnet_id                   = element(aws_subnet.public.*.id, count.index)

  tags = {
    Name = "${var.stack}-web-${count.index + 1}"
  }

  # depends_on = [aws_route_table_association.route-association]

  provisioner "local-exec" {
    command = <<EOF
aws --profile ${var.aws_profile} ec2 wait instance-status-ok --region ${var.aws_region} --instance-ids ${self.id}
ansible-playbook --extra-vars 'passed_in_hosts=${self.public_ip}' install-apache.yml
EOF
  }


}


