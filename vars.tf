variable "region" {
 type = string
 default = "eu-central-1"
 description = "Choose your region"  
}


variable "image_id" {
  type = string
  
  validation {
    # condition = can(regex("^ami-", var.image_id))
    condition = length(var.image_id) > 4 && substr(var.image_id,0,4)=="ami-"
    error_message = "Bad Image ID!"
  }
}

variable "key_name" {
 type = string
 default = "saeeday"
 description = "Choose your key name"  
}
variable "access_key" {
 type = string
 description = "Choose your access key"  
}
variable "secret_key" {
 type = string
 description = "Choose your secret key"  
}