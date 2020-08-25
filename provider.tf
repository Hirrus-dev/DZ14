variable "do_token" {}
variable "pub_key" {}
variable "pvt_key" {}
variable "ssh_fingerprint" {}
variable "s3_access_id" {}
variable "s3_secret_key" {}
variable "s3-name" {}

provider "digitalocean" {
    token = var.do_token
    spaces_access_id  = file (var.s3_access_id)
    spaces_secret_key  = file (var.s3_secret_key)
}
