Troubleshooting common errors

1) Error: denied: Permission "artifactregistry.repositories.uploadArtifacts" denied
Cause: SA missing roles/artifactregistry.writer or repository doesn't exist.
Fix: Grant roles/artifactregistry.writer to the SA and ensure the repository name and region match. See `docs/gcp-artifactregistry-remediation.md`.

2) Error: gcloud: not authenticated or insufficient permissions
Cause: Invalid or missing `GCP_SA_KEY` secret, or project mismatch.
Fix: Confirm the JSON key matches the project, and `GCP_PROJECT` secret matches project_id in the key file.

3) Error: Could not find repository us-docker.pkg.dev/PROJECT/REPO
Cause: Artifact Registry repo missing or wrong region.
Fix: Create the repo in the region your workflow uses and confirm `ARTIFACT_REGISTRY_REPO` secret.

4) Docker push hangs on "Waiting" and then fails
Cause: Credentials/permissions issue or incorrect docker auth configuration.
Fix: Ensure `gcloud auth configure-docker us-docker.pkg.dev --quiet` ran successfully in the workflow and SA has artifactregistry.writer role.

5) Deploy fails with permission denied to impersonate service account
Cause: Missing roles/iam.serviceAccountUser binding.
Fix: Run: gcloud projects add-iam-policy-binding PROJECT --member="serviceAccount:SA@PROJECT.iam.gserviceaccount.com" --role="roles/iam.serviceAccountUser"

6) For public repositories
Risk: Storing long-lived JSON keys in a public repo's secrets is risky if secrets leak.
Mitigation: Use Workload Identity Federation with google-github-actions/auth (no long-lived SA key) — see Google docs for configuration.


