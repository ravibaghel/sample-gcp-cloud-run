# Spring Boot Cloud Run Sample

This is a minimal Spring Boot application that returns "Hello, world!" at the root endpoint. It's intended as a demo for building and deploying to Google Cloud Run.

Prerequisites
- Java 17
- Maven
- Docker (optional for local container testing)
- gcloud CLI configured with your Google Cloud project and authenticated
- (Optional) GitHub account and `gh` CLI or web access to create a repo

Build and run locally

1. Build with Maven:

```powershell
mvn -B -DskipTests package
```

2. Run the JAR locally:

```powershell
java -jar target/demo-0.0.1-SNAPSHOT.jar
```

3. Test the endpoint:

```powershell
curl http://localhost:8080/
# Should return: Hello, world!
```

Build and run in Docker (local)

```powershell
docker build -t demo:local .
docker run --rm -p 8080:8080 demo:local
```

Deploy to Google Cloud Run

1. Set your project and region:

```powershell
gcloud config set project PROJECT_ID
gcloud config set run/region REGION
```

2. Build and push a container image using Cloud Build (recommended):

```powershell
gcloud builds submit --tag gcr.io/PROJECT_ID/demo:latest
```

3. Deploy to Cloud Run:

```powershell
gcloud run deploy demo-service --image gcr.io/PROJECT_ID/demo:latest --platform managed --region REGION --allow-unauthenticated
```

After deployment, `gcloud` will print the service URL. A GET request to `/` should return `Hello, world!`.

Push to GitHub

1. Initialize git and commit (already done locally in this repo):

```powershell
# if you haven't already
git init
git add .
git commit -m "chore: initial Spring Boot Cloud Run sample"
```

2. Create a remote repository and push (two options):

- Using GitHub web UI: create a new repository and follow the instructions to push your local repo.
- Using `gh` CLI (if installed and authenticated):

```powershell
gh repo create sample-gcp-cloud-run-demo --public --source=. --remote=origin --push
```

3. Or manually add a remote and push:

```powershell
git remote add origin https://github.com/<YOUR-USER>/<REPO>.git
git branch -M main
git push -u origin main
```

Optional: GitHub Actions CI (build + test)

A small workflow is included at `.github/workflows/ci.yml` (builds with Maven and runs tests). You can extend this to build and push the container image to Artifact Registry or GCR.

## GitHub Actions: Automated build, push and deploy to Cloud Run

This repository includes a workflow at `.github/workflows/cloud-run-deploy.yml` that will:
- Build the Docker image
- Push the image to Google Container Registry (GCR)
- Deploy the image to Cloud Run

The workflow runs on pushes to `main` and requires the following GitHub repository secrets to be configured:
- `GCP_PROJECT` — your GCP project id (e.g. `my-gcp-project`)
- `GCP_SA_KEY` — JSON service account key (contents of the key file)
- `CLOUD_RUN_REGION` — the region to deploy Cloud Run to (e.g. `us-central1`)

How to create the service account and key

1. Create a service account and grant it permissions (run this with a user who has Owner or IAM Admin privileges):

```powershell
gcloud iam service-accounts create github-actions-sa --display-name "GitHub Actions CI";
```

2. Assign required roles to the service account (adjust as needed):

```powershell
gcloud projects add-iam-policy-binding PROJECT_ID --member "serviceAccount:github-actions-sa@PROJECT_ID.iam.gserviceaccount.com" --role "roles/run.admin";
gcloud projects add-iam-policy-binding PROJECT_ID --member "serviceAccount:github-actions-sa@PROJECT_ID.iam.gserviceaccount.com" --role "roles/storage.admin";
```

Notes: For pushing to GCR the service account needs permission to write to Container Registry (Storage roles). If you use Artifact Registry replace the storage role with `roles/artifactregistry.writer` and adjust the workflow.

3. Generate a JSON key for the service account and store it locally (the file will contain the JSON you will paste into the GitHub secret):

```powershell
gcloud iam service-accounts keys create key.json --iam-account github-actions-sa@PROJECT_ID.iam.gserviceaccount.com
```

4. Add the secrets to your GitHub repository (via web UI: Settings -> Secrets -> Actions -> New repository secret), or using the `gh` CLI:

```powershell
# Example using gh CLI (if installed and authenticated locally)
gh secret set GCP_PROJECT --body "PROJECT_ID"
gh secret set CLOUD_RUN_REGION --body "us-central1"
gh secret set GCP_SA_KEY --body "$(Get-Content key.json -Raw)"
```

Workflow details

- The workflow builds the Docker image and tags it as `gcr.io/<PROJECT>/demo:<commit-sha>`.
- It configures Docker to use the `gcloud` credential helper and pushes the image to GCR.
- It then deploys to Cloud Run (service name `demo-service`) in the region from `CLOUD_RUN_REGION` and allows unauthenticated access.

Security note

- Keep your `GCP_SA_KEY` secret secure. Use least privilege: consider creating a more restricted service account for production with only the roles it needs (for example, `roles/run.admin` + `roles/iam.serviceAccountUser` + `roles/storage.objectAdmin` or `roles/artifactregistry.writer`).

Troubleshooting

- If the workflow fails with authentication errors, confirm `GCP_SA_KEY` contains a valid JSON key for the service account and that `GCP_PROJECT` matches the project in the key.
- If the push to GCR fails, verify the service account has storage permissions or switch to Artifact Registry and update the workflow accordingly.

Notes
- This sample uses Maven and Eclipse Temurin JRE in the runtime image. You can swap to distroless images for smaller images.
- For production, enable vulnerability scanning, use Artifact Registry, and restrict unauthenticated access as needed.
