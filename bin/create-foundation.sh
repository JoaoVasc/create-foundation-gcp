#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <company_name>"
  exit 1
fi

COMPANY_NAME=$1
BASE_DIR="foundation-$COMPANY_NAME"

# Create base directories
mkdir -p $BASE_DIR/{prod,dev,hml,common/prj-$COMPANY_NAME-host}

# Create main foundation file
cat <<EOT > $BASE_DIR/foundation.tf
provider "google" {
  project = var.project_id
  region  = var.region
}

module "prod_project" {
  source = "./prod"
}

module "dev_project" {
  source = "./dev"
}

module "hml_project" {
  source = "./hml"
}

module "common_resources" {
  source = "./common"
}
EOT

# Create VPC file for the common host project
cat <<EOT > $BASE_DIR/common/prj-$COMPANY_NAME-host/vpc.tf
resource "google_compute_network" "vpc_prod" {
  name    = "vpc-prod"
  project = var.project_id
}

resource "google_compute_network" "vpc_dev" {
  name    = "vpc-dev"
  project = var.project_id
}

resource "google_compute_network" "vpc_hml" {
  name    = "vpc-hml"
  project = var.project_id
}
EOT

echo "Foundation structure for $COMPANY_NAME created successfully."
