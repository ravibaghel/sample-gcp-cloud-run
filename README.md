# Spring Boot Cloud Run Sample

This is a minimal Spring Boot application that returns "Hello, world!" at the root endpoint. It's intended as a demo for building and deploying to Google Cloud Run.

Prerequisites
- Java 17
- Maven
- Docker (optional for local container testing)
- gcloud CLI configured with your Google Cloud project and authenticated

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

1. Initialize git and commit:

```powershell
git init
git add .
git commit -m "chore: initial Spring Boot Cloud Run sample"
```

2. Create a GitHub repo (via web UI or `gh` CLI), then push:

```powershell
git remote add origin https://github.com/<YOUR-USER>/<REPO>.git
git branch -M main
git push -u origin main
```

Notes
- This sample uses Maven and Eclipse Temurin JRE in the runtime image. You can swap to distroless images for smaller images.
- For production, enable vulnerability scanning, use Artifact Registry, and restrict unauthenticated access as needed.

