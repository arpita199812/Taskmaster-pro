variable "ssh_key_name" {
  description = "The name of the SSH key pair to use for instances"
  type        = string
  default     = "taskpro"
}

variable "tags" {
   description = "Tags given"
   type        = string
   default     = "taskpro"
}
