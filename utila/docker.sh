PROJECT_ID="project-595dfcb1-d16e-4c23-83d"
REGION="europe-west1"
REPOSITORY="utila"
IMAGE_NAME="grpc-server"
IMAGE_TAG="1.0.0"

gcloud auth login
gcloud config set project "$PROJECT_ID"

gcloud services enable artifactregistry.googleapis.com

gcloud artifacts repositories describe "$REPOSITORY" \
  --location="$REGION" \
  --project="$PROJECT_ID" >/dev/null 2>&1 || \
gcloud artifacts repositories create "$REPOSITORY" \
  --repository-format=docker \
  --location="$REGION" \
  --description="Utila Docker images" \
  --project="$PROJECT_ID"

gcloud auth configure-docker "${REGION}-docker.pkg.dev"

REMOTE_IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${IMAGE_NAME}:${IMAGE_TAG}"

docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "$REMOTE_IMAGE"
docker push "$REMOTE_IMAGE"

echo "Pushed image: $REMOTE_IMAGE"