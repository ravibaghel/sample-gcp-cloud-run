# Spring Boot -> Cloud Run (GitHub Actions driven)

This sample demonstrates a minimal Spring Boot application ("Hello, world!") and a GitHub Actions workflow that builds, publishes a Docker image to Google Artifact Registry and deploys to Cloud Run.

Goal for juniors
- Run and test the service locally without installing Docker (just Java + Maven).
- Push code to GitHub and manually trigger the provided GitHub Actions workflow to build the image and deploy to Cloud Run.

Key idea: no Docker is required on the developer workstation — CI (GitHub Actions) builds and pushes the container.

Prerequisites (local workstation)
- Java 17 (to run the app locally)
- Maven (to build the jar)
- Optional: `gh` CLI (convenient but not required for adding secrets)
- A Google Cloud project and an account with permissions to create Artifact Registry repos and service accounts

Quick local test (no Docker required)

1. Build the application (from repository root):

```powershell
mvn -B -DskipTests package
```

2. Run the application locally:

```powershell
java -jar target/demo-0.0.1-SNAPSHOT.jar
```

3. Test the endpoint in another shell:

```powershell
curl http://localhost:8080/
# Expect: Hello, world!
```

GitHub Actions driven deployment — overview
- The repository contains a workflow: `.github/workflows/cloud-run-deploy.yml`.
- The workflow is manual (workflow_dispatch). After you push code to GitHub, you (or a teammate) can run the workflow from the Actions tab.
- The workflow uses a service account key (stored in a GitHub Actions secret) to authenticate to GCP, builds the Docker image, pushes to Artifact Registry, and deploys to Cloud Run.

High-level steps to prepare GCP and GitHub (copy-paste friendly PowerShell)

Replace the placeholders PROJECT_ID, REGION, REPO and SA name with your values. Example values used in this repository: PROJECT_ID = `lingomatch-483108`, REGION = `asia-south2`, REPO = `demo-repo`, SA = `github-actions-deployer`.

1) Create Artifact Registry repo (if not already present)

```powershell
$project = "PROJECT_ID"
$region  = "asia-south2"   # or your chosen region
$repo    = "demo-repo"

# Enable API(s) if needed
gcloud services enable artifactregistry.googleapis.com --project $project

# Create the repo (regional)
gcloud artifacts repositories create $repo --repository-format=docker --location=$region --description="Docker repo for demo" --project $project
```

2) Create a service account and grant permissions (least-privilege for this sample)

```powershell
$saName = "github-actions-deployer"
$saEmail = "$saName@$project.iam.gserviceaccount.com"

# Create SA (skip if exists)
gcloud iam service-accounts create $saName --display-name="GitHub Actions deployer" --project $project

# Grant roles for Artifact Registry push and Cloud Run deploy
gcloud projects add-iam-policy-binding $project --member="serviceAccount:$saEmail" --role="roles/artifactregistry.writer"
gcloud projects add-iam-policy-binding $project --member="serviceAccount:$saEmail" --role="roles/run.admin"
gcloud projects add-iam-policy-binding $project --member="serviceAccount:$saEmail" --role="roles/iam.serviceAccountUser"

# Create a JSON key locally (key.json)
gcloud iam service-accounts keys create key.json --iam-account=$saEmail --project $project
```

Important: keep `key.json` secret. You will copy its contents into a GitHub repository secret.

3) Add required GitHub repository secrets

Required secrets used by the workflow:
- `GCP_PROJECT` — your project id (e.g. `lingomatch-483108`)
- `CLOUD_RUN_REGION` — the region to deploy to (e.g. `asia-south2`)
- `ARTIFACT_REGISTRY_REPO` — Artifact Registry repository name (e.g. `demo-repo`)
- `GCP_SA_KEY` — contents of the `key.json` file (paste entire JSON)

Add via GitHub UI: Repository -> Settings -> Secrets and variables -> Actions -> New repository secret. Or with `gh` CLI:

```powershell
gh secret set GCP_PROJECT --body "PROJECT_ID"
gh secret set CLOUD_RUN_REGION --body "asia-south2"
gh secret set ARTIFACT_REGISTRY_REPO --body "demo-repo"
gh secret set GCP_SA_KEY --body "$(Get-Content key.json -Raw)"
```

Make sure the secret values match the project/region/repo you created in GCP.

How to run the workflow manually
1. Push your code to a GitHub branch (for example `main`).

```powershell
git add .
git commit -m "chore: add GH Actions deploy docs"
git push origin main
```

2. In GitHub UI: Actions -> Build and push Docker image to Artifact Registry and deploy to Cloud Run -> Run workflow -> Select branch -> Run workflow

3. Watch the logs for these key phases:
- Authenticate to Google Cloud (google-github-actions/auth)
- Configure docker credential helper for the region (e.g. `asia-south2-docker.pkg.dev`)
- docker build and docker push to `asia-south2-docker.pkg.dev/PROJECT/REPO/demo:COMMIT_SHA`
- gcloud run deploy prints the service URL

4. Visit the printed Cloud Run service URL and verify `GET /` returns `Hello, world!`

Notes for juniors and instructors
- Local dev: you can run and test the API locally using Java and Maven; Docker is only required on the CI runner.
- CI building: the GitHub Actions runner will build the image, push, and deploy — no Docker on the developer machine required.
- Security: storing a long-lived JSON key in GitHub secrets is fine for a learning demo, but for public repos or production use Workload Identity Federation (WIF). If you want, I can provide WIF setup instructions and a workflow change that avoids JSON keys.

Troubleshooting quick hits
- Repository-not-found on push: ensure `ARTIFACT_REGISTRY_REPO` was created in the same region as `CLOUD_RUN_REGION`. The workflow builds an image for `{{CLOUD_RUN_REGION}}-docker.pkg.dev/PROJECT/REPO/...`.
- Permission denied on push: ensure the service account has `roles/artifactregistry.writer`.
- Auth errors: confirm `GCP_SA_KEY` JSON belongs to the same `GCP_PROJECT`.

Where to look for more help
- `docs/gcp-artifactregistry-remediation.md` — exact PowerShell commands to create the repo, SA, roles, and key.
- `docs/test-checklist.md` — guidance to test locally and via Actions.
- `docs/troubleshooting.md` — common errors and fixes.

Enjoy! Once you push this repo to GitHub and add the required secrets, anyone in your team can run the workflow manually to deploy to Cloud Run without running Docker locally.
