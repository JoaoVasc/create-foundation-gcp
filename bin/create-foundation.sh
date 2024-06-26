#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <company_name>"
  exit 1
fi

COMPANY_NAME=$1
BASE_DIR="foundation-$COMPANY_NAME"
MODULES_DIR="$BASE_DIR/modules"
ENVIRONMENTS=("prod" "dev" "hml" "common")
FOLDERS=("Development" "UAT" "Production" "Common")

# Create base directories
mkdir -p $BASE_DIR/common/prj-$COMPANY_NAME-host
mkdir -p $MODULES_DIR/{folder,project}
for env in "${ENVIRONMENTS[@]}"; do
  mkdir -p $BASE_DIR/$env
done

# Create main foundation file
cat <<EOT > $BASE_DIR/foundation.tf
provider "google" {
  credentials = file("gcp-credentials.json")
}

locals {
  apis = [
    "cloudbilling.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com"
  ]
}
EOT

for i in "${!ENVIRONMENTS[@]}"; do
  env=${ENVIRONMENTS[$i]}
  folder=${FOLDERS[$i]}

  cat <<EOT >> $BASE_DIR/foundation.tf

module "${env}_folder" {
  source       = "./modules/folder"
  display_name = "${folder}"
  org_id       = var.org_id
}

module "${env}_project" {
  source          = "./modules/project"
  project_name    = "${folder} Project"
  project_id      = "${env}-\${var.project_name}"
  folder_id       = module.${env}_folder.folder.id
  billing_account = var.billing_account
}

resource "google_project_service" "${env}_apis" {
  for_each = toset(local.apis)
  project  = module.${env}_project.project.project_id
  service  = each.value
}
EOT
done

cat <<EOT >> $BASE_DIR/foundation.tf

resource "google_compute_network" "vpc_dev" {
  name    = "vpc-dev"
  project = module.dev_project.project.project_id
}

resource "google_compute_network" "vpc_uat" {
  name    = "vpc-uat"
  project = module.uat_project.project.project_id
}

resource "google_compute_network" "vpc_prod" {
  name    = "vpc-prod"
  project = module.prod_project.project.project_id
}
EOT

# Create variables file
cat <<EOT > $BASE_DIR/variables.tf
variable "org_id" {
  description = "ID da organização"
  type        = string
}

variable "project_name" {
  description = "Nome base do projeto"
  type        = string
}

variable "billing_account" {
  description = "Sua Billing Account"
  type        = string
}
EOT

# Create folder module
cat <<EOT > $MODULES_DIR/folder/main.tf
resource "google_folder" "folder" {
  display_name = var.display_name
  parent       = "organizations/\${var.org_id}"
}

variable "display_name" {
  description = "The display name of the folder"
  type        = string
}

variable "org_id" {
  description = "The organization ID"
  type        = string
}
EOT

# Create project module
cat <<EOT > $MODULES_DIR/project/main.tf
resource "google_project" "project" {
  name            = var.project_name
  project_id      = var.project_id
  folder_id       = var.folder_id
  billing_account = var.billing_account
  auto_create_network = false
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "project_id" {
  description = "The ID of the project"
  type        = string
}

variable "folder_id" {
  description = "The folder ID"
  type        = string
}

variable "billing_account" {
  description = "The billing account ID"
  type        = string
}
EOT

echo "Foundation structure for $COMPANY_NAME created successfully."
