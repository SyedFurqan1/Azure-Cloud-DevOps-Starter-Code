variable "prefix" {
  description = "The prefix that will be added with the name of most of the resources created by this Terraform project."
  default     = "udacity-project-1"
}

variable "name_rg" {
  type        = string
  description = "The name of the Resource Group the resources have to be deployed in."
  default     = "project-1"
}

variable "location_rg" {
  type        = string
  description = "The location of the Resource Group. The Azure Region."
  default     = "UAE North"
}

variable "number_of_VMs" {
  type        = number
  description = "The number of virtual machines to be created in the availability set."
  default     = 2
}

variable "VM_admin_username" {
  type        = string
  description = "The username of admin"
  default     = "admin_azure"
}

variable "VM_admin_password" {
  description = "The password of admin user."
  type        = string
  default     = "shouldnotkeepdefaultvalueHere1"
}

variable "custom_image_name" {
  type        = string
  description = "The name of the server template custom image that was created using packer."
  default     = "serverTemplateImage"
}

variable "custom_image_rg" {
  type        = string
  description = "The name of the resource group the server template custom image is stored in."
  default     = "project-1-udacity-image-rg"
}
