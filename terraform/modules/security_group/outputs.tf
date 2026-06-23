output "ec2_security_group_id" {
    value = aws_security_group.ec2_security_group.id
}
output "alb_sg_id" {
    value = aws_security_group.alb_sg.id
}