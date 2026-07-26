# Proxyless gRPC Server

This project contains the standalone Go gRPC server for the Cloud Service Mesh assignment.

## Included files

```text
proxyless-grpc-server/
├── cmd/server/server.go
├── proto/helloworld/v1/helloworld.proto
├── k8s/deployment.yaml
├── Dockerfile
├── go.mod
├── .dockerignore
└── .gitignore
```

The server:

- Implements `Greeter.SayHello`.
- Listens on port `50051`.
- Returns the pod hostname in each response.
- Implements the standard gRPC health service.
- Gracefully stops when Kubernetes sends `SIGTERM`.

## xDS responsibility

Cloud Service Mesh sends xDS discovery and load-balancing configuration to the proxyless gRPC **client**. The backend server does not select another server and therefore does not perform load balancing.

The server is prepared for the proxyless deployment by:

- Listening on the port used by the backend service and NEG.
- Implementing the gRPC health protocol required by the Google health check.
- Being directly reachable through the pod IP endpoints in the standalone NEG.

## Build the container

The Docker build generates the Go protobuf files and compiles a static server binary:

```bash
docker build -t grpc-server:1.0.0 .
```

On an Apple Silicon Mac, build an AMD64 image when the GKE node pool uses
AMD64 nodes:

```bash
docker buildx build \
  --platform linux/amd64 \
  -t grpc-server:1.0.0 \
  --load \
  .
```

For a direct multi-platform push to Artifact Registry:

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t REGION-docker.pkg.dev/PROJECT_ID/REPOSITORY/grpc-server:1.0.0 \
  --push \
  .
```

Run it locally:

```bash
docker run --rm -p 50051:50051 grpc-server:1.0.0
```

## Push to Artifact Registry

Replace the uppercase placeholders:

```bash
gcloud auth configure-docker REGION-docker.pkg.dev

docker tag grpc-server:1.0.0 \
  REGION-docker.pkg.dev/PROJECT_ID/REPOSITORY/grpc-server:1.0.0

docker push \
  REGION-docker.pkg.dev/PROJECT_ID/REPOSITORY/grpc-server:1.0.0
```

Update the image in `k8s/deployment.yaml`, then deploy:

```bash
kubectl apply -f k8s/deployment.yaml
kubectl rollout status deployment/grpc-server
```

Confirm that GKE created the standalone NEG:

```bash
gcloud compute network-endpoint-groups list \
  --filter="name=dev-helloworld-grpc"
```

Add the NEG self-link to `backend_neg_self_links` in the separate Terraform project and run `terraform apply`.


### test locally
```bash
brew install grpcurl
cd ./utila/proxyless-grpc-server

grpcurl \
  -plaintext \
  -import-path ./proto \
  -proto helloworld/v1/helloworld.proto \
  -d '{"name":"Almog"}' \
  localhost:50051 \
  helloworld.v1.Greeter/SayHello

output: 
{
  "message": "Hello Almog, from <container-id>"
}
```
