terraform {
  backend "s3" {
    bucket         = "regina-terraform"
    key            = "terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-shucknite-s3-backend"
  }
}