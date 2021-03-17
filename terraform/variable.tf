variable "environment_tf_state_bucket" {
  type = string
}
variable "project_id" {
  type = string
}

variable "env" {
  type = string
}

variable "terraform_sa_email" {
  type = string
}

variable "region" {
  type    = string
  default = "europe-west1"
}

variable "activate_apis" {
  type = set(string)
  default = [
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "oslogin.googleapis.com",
    "stackdriver.googleapis.com",
    "storage-api.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "pubsub.googleapis.com",
    "artifactregistry.googleapis.com",
  ]
}
