resource "aws_route_table" "route_table_private" {
  vpc_id = var.vpc_id_value
  tags = {
    Name = "route_table_private"
  }
}

resource "aws_route_table" "route_table_public" {
  vpc_id = var.vpc_id_value
  tags = {
    Name = "route_table_public"
  }
}

resource "aws_route" "route_private" {
  route_table_id         = aws_route_table.route_table_private.id
  destination_cidr_block = var.destination_cidr_block_private
  gateway_id             = var.gateway_id_private
}

resource "aws_route_table_association" "route_table_association_private" {
  count          = length(var.subnet_id_private)
  subnet_id      = var.subnet_id_private[count.index]
  route_table_id = aws_route_table.route_table_private.id
}

resource "aws_route" "route_public" {
  route_table_id         = aws_route_table.route_table_public.id
  destination_cidr_block = var.destination_cidr_block_public
  gateway_id             = var.gateway_id_public
}
resource "aws_route_table_association" "route_table_association_public" {
  count          = length(var.subnet_id_public)
  subnet_id      = var.subnet_id_public[count.index]
  route_table_id = aws_route_table.route_table_public.id
}