locals {
  gcp_project_id      = var.project_id #data.terraform_remote_state.team_managed_ressources_state.outputs.idp_application_application_projet_id
  gcs_bucket_location = "EUROPE-WEST1"
  gcs_bucket_class    = "STANDARD"
  bq_dataset_location = "EU"

  gcs_bucket_landing    = format("tt-servier-idp-%s-landing", var.env)
  gcs_bucket_archive    = format("tt-servier-idp-%s-archive", var.env)
  gcs_bucket_quarantine = format("tt-servier-idp-%s-quarantine", var.env)
  gcs_bucket_azure      = format("tt-servier-idp-%s-azure", var.env)
  gcs_bucket_conf       = format("tt-servier-idp-%s-conf", var.env)

  bq_dataset_bronze     = "bronze"
  bq_dataset_silver     = "silver"
  bq_dataset_gold       = "gold"
  bq_dataset_monitoring = "monitoring"

  log_name_cpland   = "cpland"
  log_name_pipeline = "pipeline"

  pubsub_topic_landed    = "bronze-landed"
  pubsub_sub_eventsource = "eventsource"

  pubsub_topic_azure = "azure-landed"
  pubsub_sub_central = "cpland"
}

resource "google_project_service" "project_apis" {
  for_each           = var.activate_apis
  project            = local.gcp_project_id
  service            = each.value
  disable_on_destroy = false
}

// -----------------------------------------------------------------------------
// ---- Storage
// -----------------------------------------------------------------------------
resource "google_bigquery_dataset" "bronze" {
  dataset_id = local.bq_dataset_bronze
  location   = local.bq_dataset_location
  project    = local.gcp_project_id

}

resource "google_bigquery_dataset" "silver" {
  dataset_id = local.bq_dataset_silver
  location   = local.bq_dataset_location
  project    = local.gcp_project_id

}

resource "google_bigquery_dataset" "gold" {
  dataset_id = local.bq_dataset_gold
  location   = local.bq_dataset_location
  project    = local.gcp_project_id

}

resource "google_bigquery_dataset" "monitoring" {
  dataset_id = local.bq_dataset_monitoring
  location   = local.bq_dataset_location
  project    = local.gcp_project_id

}

resource "google_storage_bucket" "landing" {
  name                        = local.gcs_bucket_landing
  location                    = local.gcs_bucket_location
  storage_class               = local.gcs_bucket_class
  uniform_bucket_level_access = true
  project                     = local.gcp_project_id

}

resource "google_storage_bucket" "archive" {
  name                        = local.gcs_bucket_archive
  location                    = local.gcs_bucket_location
  storage_class               = local.gcs_bucket_class
  uniform_bucket_level_access = true
  project                     = local.gcp_project_id

}

resource "google_storage_bucket" "quarantine" {
  name                        = local.gcs_bucket_quarantine
  location                    = local.gcs_bucket_location
  storage_class               = local.gcs_bucket_class
  uniform_bucket_level_access = true
  project                     = local.gcp_project_id

}

resource "google_storage_bucket" "azure" {
  name                        = local.gcs_bucket_azure
  location                    = local.gcs_bucket_location
  storage_class               = local.gcs_bucket_class
  uniform_bucket_level_access = true
  project                     = local.gcp_project_id

}

resource "google_storage_bucket" "conf" {
  name                        = local.gcs_bucket_conf
  location                    = local.gcs_bucket_location
  storage_class               = local.gcs_bucket_class
  uniform_bucket_level_access = true
  project                     = local.gcp_project_id

}

// -----------------------------------------------------------------------------
// ---- Monitoring
// -----------------------------------------------------------------------------
resource "google_logging_project_sink" "pipeline" {
  name                   = local.log_name_pipeline
  destination            = format("bigquery.googleapis.com/projects/%s/datasets/%s", local.gcp_project_id, google_bigquery_dataset.monitoring.dataset_id)
  filter                 = format("resource.type = global AND log_name=projects/%s/logs/%s", local.gcp_project_id, local.log_name_pipeline)
  unique_writer_identity = true
  project                = local.gcp_project_id

  bigquery_options {
    use_partitioned_tables = true
  }
}

resource "google_bigquery_dataset_access" "pipeline" {
  dataset_id    = google_bigquery_dataset.monitoring.dataset_id
  project       = local.gcp_project_id
  role          = "WRITER"
  user_by_email = trimprefix(google_logging_project_sink.pipeline.writer_identity, "serviceAccount:")
}

resource "google_logging_project_sink" "cpland" {
  name                   = local.log_name_cpland
  project                = local.gcp_project_id
  destination            = format("bigquery.googleapis.com/projects/%s/datasets/%s", local.gcp_project_id, google_bigquery_dataset.monitoring.dataset_id)
  filter                 = format("resource.type = global AND log_name=projects/%s/logs/%s", local.gcp_project_id, local.log_name_cpland)
  unique_writer_identity = true
  bigquery_options {
    use_partitioned_tables = true
  }
}

resource "google_bigquery_dataset_access" "cpland" {
  dataset_id    = google_bigquery_dataset.monitoring.dataset_id
  role          = "WRITER"
  user_by_email = trimprefix(google_logging_project_sink.cpland.writer_identity, "serviceAccount:")
  project       = local.gcp_project_id

}

// -----------------------------------------------------------------------------
// ---- Trigerring
// -----------------------------------------------------------------------------
resource "google_pubsub_topic" "landed" {
  name    = local.pubsub_topic_landed
  project = local.gcp_project_id
}

resource "google_pubsub_topic" "azure" {
  name    = local.pubsub_topic_azure
  project = local.gcp_project_id
}

resource "google_pubsub_subscription" "cpland" {
  project               = local.gcp_project_id
  name                  = local.pubsub_sub_central
  topic                 = google_pubsub_topic.azure.name
  retain_acked_messages = false
  ack_deadline_seconds  = 600
}

resource "google_pubsub_subscription" "eventsource" {
  project               = local.gcp_project_id
  name                  = local.pubsub_sub_eventsource
  topic                 = google_pubsub_topic.landed.name
  retain_acked_messages = false
  ack_deadline_seconds  = 600
}



// -----------------------------------------------------------------------------
// ---- Data transfer
// -----------------------------------------------------------------------------
// The current version of Terraform does not support Azure Storage as a source
// in the Cloud Transfer service. See: https://github.com/hashicorp/terraform-provider-google/issues/6224
