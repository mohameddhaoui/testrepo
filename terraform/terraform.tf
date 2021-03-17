terraform {
  required_version = ">=0.13.0, <0.14"
  #https://www.terraform.io/upgrade-guides/0-13.html#explicit-provider-source-locations
  required_providers {
    google      = "~> 3.58.0"
    google-beta = "~> 3.58.0"
  }
}

provider "google" {
  alias   = "impersonate"
  project = "nautilus-sandbox-268214" #data.terraform_remote_state.team_managed_ressources_state.outputs.idp_application_application_projet_id
  region  = "eu-west1"
  scopes = [
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}

