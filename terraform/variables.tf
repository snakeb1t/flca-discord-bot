# make a terraform.tf file with these variable names and values, eg: "nocodb_token=foo"
variable "nocodb_token" {
	type = string
	description = "nocoDB API token"
	sensitive = true
}

variable "nocodb_domain" {
	type = string
	description = "nocoDB domain"
	sensitive = true
}

variable "ships_table_id" {
	type = string
	description = "nocoDB table id for ships table"
	sensitive = true
}

variable "discord_bot_public_key" {
	type = string
	description = "discord bot public key"
	sensitive = true
}

variable "region" {
	type = string
	description = "aws region"
}

variable "profile" {
	type = string
	description = "aws profile"
}
