GCP Artifact Registry and GitHub Actions: Remediation Steps

This document explains why you saw the error:

  denied: Permission "artifactregistry.repositories.uploadArtifacts" denied on resource "projects/***/locations/us/repositories/gcr.io" (or it may not exist)

and provides copy-paste PowerShell-ready commands to fix it, plus an alternative using Container Registry (gcr.io).

1) Causes
- The service account used by GitHub Actions does not have permissions to upload images to the Artifact Registry repository.
- The referenced repository path may not exist (e.g., using an Artifact Registry-style path when only Container Registry exists).
- The workflow authenticates but attempts to push to a repository the SA can't access.

2) gcloud commands (PowerShell-ready)

# Variables - replace these values
$env:PROJECT=PROJECT_ID
$env:REGION=us-central1
$env:REPO=demo-repo
$env:SA=github-actions-deployer

# Enable required APIs
gcloud services enable artifactregistry.googleapis.com --project $env:PROJECT
gcloud services enable run.googleapis.com --project $env:PROJECT
gcloud services enable iam.googleapis.com --project $env:PROJECT

# Create an Artifact Registry docker repository (regional)
gcloud artifacts repositories create $env:REPO --repository-format=docker --location=$env:REGION --description="Docker repo for demo"

# Create service account
gcloud iam service-accounts create $env:SA --display-name="GitHub Actions deployer" --project $env:PROJECT

# Grant minimal roles to the service account
# Artifact Registry push
gcloud projects add-iam-policy-binding $env:PROJECT --member="serviceAccount:$env:SA@$env:PROJECT.iam.gserviceaccount.com" --role="roles/artifactregistry.writer"
# Cloud Run deploy and access
gcloud projects add-iam-policy-binding $env:PROJECT --member="serviceAccount:$env:SA@$env:PROJECT.iam.gserviceaccount.com" --role="roles/run.admin"
# Allow acting as the service account when deploying to Cloud Run
gcloud projects add-iam-policy-binding $env:PROJECT --member="serviceAccount:$env:SA@$env:PROJECT.iam.gserviceaccount.com" --role="roles/iam.serviceAccountUser"

# Create JSON key (store locally temporarily)
gcloud iam service-accounts keys create key.json --iam-account=$env:SA@$env:PROJECT.iam.gserviceaccount.com

# The file 'key.json' is the JSON you'll paste into the GitHub secret GCP_SA_KEY

3) Container Registry (gcr.io) alternative
If you prefer the older Container Registry (gcr.io) instead of Artifact Registry, the artifact repository does not need to exist. Instead you need Storage permissions on the project (Container Registry uses Google Cloud Storage under the hood):

# Grant storage role for gcr.io push (less recommended than Artifact Registry)
gcloud projects add-iam-policy-binding $env:PROJECT --member="serviceAccount:$env:SA@$env:PROJECT.iam.gserviceaccount.com" --role="roles/storage.admin"

Notes: Artifact Registry is recommended for new projects.

4) GitHub repository secrets to add
- GCP_PROJECT — your GCP project id (e.g. my-gcp-project)
- CLOUD_RUN_REGION — region for Cloud Run (e.g. us-central1)
- ARTIFACT_REGISTRY_REPO — the Artifact Registry repository name (demo-repo)
- GCP_SA_KEY — the full JSON content of the service account key (key.json)

Adding secrets via GitHub web UI:
- Go to your repository -> Settings -> Secrets and variables -> Actions -> New repository secret
- Add the name and paste the value

Optional: Using gh CLI (if installed)
# Example (PowerShell)
gh secret set GCP_PROJECT --body "PROJECT_ID"
gh secret set CLOUD_RUN_REGION --body "us-central1"
gh secret set ARTIFACT_REGISTRY_REPO --body "demo-repo"
gh secret set GCP_SA_KEY --body "$(Get-Content key.json -Raw)"

5) Notes on IAM roles used
- roles/artifactregistry.writer: required to upload images to Artifact Registry repositories
- roles/run.admin: required to deploy Cloud Run services
- roles/iam.serviceAccountUser: allows the deployer to impersonate/use the service account when deploying
- If using Container Registry instead, use roles/storage.admin or more restricted roles like roles/storage.objectAdmin

6) Security recommendation
- For public GitHub repositories, using JSON keys is risky; consider using Workload Identity Federation (WIF) and google-github-actions/auth without storing long-lived keys. This doc uses JSON keys for simplicity.


