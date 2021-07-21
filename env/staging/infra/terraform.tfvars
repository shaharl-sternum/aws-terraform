vpc_name = "staging"
vpc_cidr = "10.0.0.0/16"
private_subnet_cidrs = ["10.0.10.0/23", "10.0.20.0/23", "10.0.30.0/23"]
public_subnet_cidrs = ["10.0.110.0/23", "10.0.120.0/23", "10.0.130.0/23"]
region = "us-east-2"
env = "staging"
eks_instance_type = "t3.medium"
cluster_name = "alex-staging-cluster"
cluster_version = "1.20"
elasticsearch_node_count = "2"
elasticsearch_volume_size = "100"
elasticsearch_instance_type = "r5.large.elasticsearch"
elasticsearch_dedicated_master_type = "r5.large.elasticsearch"
elasticsearch_dedicated_master_enabled = false
map_users = []