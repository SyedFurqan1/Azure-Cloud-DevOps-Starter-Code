variable "prefix" {
  description = "The prefix that will be added with the name of most of the resources created by this Terraform project."
}

variable "name_rg" {
  type        = string
  description = "The name of the Resource Group the resources have to be deployed in."
}

variable "location_rg" {
  type        = string
  description = "The location of the Resource Group. The Azure Region."
  default     = "UAE North"
}

variable "number_of_VMs" {
  type        = number
  description = "The number of virtual machines to be created in the availability set."
}

variable "VM_admin_username" {
  type        = string
  description = "The username of admin"
}

variable "VM_admin_password" {
  description = "The password of admin user."
  type        = string
}

variable "custom_image_name" {
  type        = string
  description = "The name of the server template custom image that was created using packer."
}

variable "custom_image_rg" {
  type        = string
  description = "The name of the resource group the server template custom image is stored in."
}
