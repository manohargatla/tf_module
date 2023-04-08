variable "region" {
  type        = string
  default     = "us-east-1"
  description = "variable for to change required region"
}
## variable for vpc cidr
variable "lb_vpc_info" {
  type = object({
    lb_vpc_cidr          = string
    lb_subnet_names      = list(string)
    lb_subnets_names_azs = list(string)
    rollout_versions = string
  })
  default = {
    lb_subnet_names      = ["web", "app"]
    lb_subnets_names_azs = ["a", "b"]
    lb_vpc_cidr          = "192.168.0.0/16"
    rollout_versions = "0.0.0.0"
  }
}