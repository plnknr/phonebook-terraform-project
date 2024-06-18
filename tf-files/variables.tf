variable "git-name" {
  default = "github-user"
}

variable "git-token" {
  default = "xxxxxxxxxxxx"
}

variable "key-name" {
  default = "phonebook-key"
}

# eğer hosted-zone'un varsa bu kısmı ekleyebilrsin yoksa problem değil.
variable "hosted-zone" {
  default = "pelindevopsjourney.click"
}