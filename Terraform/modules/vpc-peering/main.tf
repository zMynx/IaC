# [Lior Dux] ==================== [ VPC Peering Connection ] ====================  [25-02-2023] #
#
# Set up vpc peering between 2 vpc's.
#

######################
## Work In Progress ##
######################
# 1. I'll set up VPC Peering using terraform, but I would NOT reccomend using it.
#     A better alternative will be setting up Transit Gateway which is scalable, and managed internal NAT so no cross CIDR problems.
# 2. Multi-region peering as an option.
# 3. Cross-Accounts peering as an option.
# 4. Check out pricing cost of peering against transit.
#     More on that here: https://cloudonaut.io/advanved-aws-networking-pitfalls-that-you-should-avoid/
#
# 5. Set up transtit gateway using terraform.
# 6. Allow choosing between the 2 options.

############################
## VPC Peering Connection ##
############################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.26"
      configuration_aliases = [ aws.accepter, aws.requester ]
    }
  }
}
# Taken from: https://awstip.com/aws-multi-region-vpc-peering-using-terraform-a0b8aabf084b
resource "aws_vpc_peering_connection" "this" {
  vpc_id      = var.requester_vpc_id
  peer_vpc_id = var.accpeter_vpc_id
  peer_region = var.accepter_region
  auto_accept = false
  provider    = aws.requester
  tags        = merge(var.tags, { Side = "Requester" })
}

resource "aws_vpc_peering_connection_accepter" "this" {
  provider                  = aws.accepter
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
  auto_accept               = true
  tags                      = merge(var.tags, { Side = "accepter" })
}

resource "aws_vpc_peering_connection_options" "this" {
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
  accepter {
    allow_remote_vpc_dns_resolution = true
  }
  provider = aws.accepter
}

locals {
  requester_route_tables_ids = data.aws_route_tables.requester.ids
  accepter_route_tables_ids  = data.aws_route_tables.accepter.ids
}