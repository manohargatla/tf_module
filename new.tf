provider "aws" {
  region = "us-east-1"
}

module "tf_module" {
    source = "git::https://github.com/manohargatla/tf_module"
  
}