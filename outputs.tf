output "vpc_id" {
  value = aws_vpc.prod.id
}
output "public_subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}
output "private_subnet_ids" {
  value = aws_subnet.private_subnets[*].id
}
output "internet_gateway_id" {
  value = aws_internet_gateway.igw.id
}
output "public_route_table_id" {
  value = aws_route_table.public_rt.id
}
output "instance_id" {
  value = aws_instance.my_web_server.id
}
output "eip" {
  value = aws_eip.eip.public_ip
}