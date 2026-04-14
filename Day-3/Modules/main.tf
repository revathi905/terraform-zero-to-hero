provider "aws" {
    region = "ap-south-2" 
}

resource "aws_instance" "terramodule" {
    ami = var.ami_value
    instance_type = var.instance_type_var
    subnet_id = var.subnet_id_var
    key_name = var.key_name_var
}