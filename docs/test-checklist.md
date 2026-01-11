Testing checklist — local and GitHub Actions

Local quick tests

1) Build the JAR
```powershell
mvn -B -DskipTests package
```

2) Run locally
```powershell
java -jar target/demo-0.0.1-SNAPSHOT.jar
# then in another shell
curl http://localhost:8080/
# expect: Hello, world!
```

3) Build and run Docker locally
```powershell
docker build -t demo:local .
docker run --rm -p 8080:8080 demo:local
curl http://localhost:8080/
```

GitHub Actions: manual run

1) Ensure repository secrets are set: `GCP_PROJECT`, `CLOUD_RUN_REGION`, `ARTIFACT_REGISTRY_REPO`, `GCP_SA_KEY`.
2) From GitHub UI: Actions -> select "Build and push Docker image to Artifact Registry and deploy to Cloud Run" -> Run workflow (choose branch and inputs if configured).
3) Watch the run logs. Key steps to confirm:
  - Authenticate to GCP (google-github-actions/auth step)
  - Build and push the Docker image (docker build + docker push). The push must not fail with permission errors.
  - gcloud run deploy should finish and print a service URL.
4) Visit the service URL; GET / should return "Hello, world!".

Notes
- If workflow fails at push with permission error, check Artifact Registry repo name and IAM bindings (see remediation doc).
- For offline debugging, download the workflow logs and the runner diagnostics from the Actions UI.

