
terraform {
  backend "gcs" {
    prefix = "terraform/idp/state"
    #  bucket = "em52-bk-prd-data-terraform-state-86799" #fixme must be passed as backend-config=bucket=<>
  }
}
