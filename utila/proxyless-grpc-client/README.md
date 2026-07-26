# Proxyless gRPC client

This Go client imports grpc-go's xDS implementation, connects to the configured
`xds:///` target, and calls `helloworld.v1.Greeter/SayHello` every five seconds.

The default target is:

```text
xds:///grpc-server.utila.svc.cluster.local:50051
```

Cloud Service Mesh must provide a valid gRPC xDS bootstrap configuration to the
pod, normally through the `GRPC_XDS_BOOTSTRAP` or
`GRPC_XDS_BOOTSTRAP_CONFIG` environment variable.

## Build

```bash
docker build -t grpc-client:1.0.0 .
```

For an Apple Silicon Mac when the GKE nodes use AMD64:

```bash
docker buildx build \
  --platform linux/amd64 \
  -t grpc-client:1.0.0 \
  --load \
  .
```

## Test against the server on the Mac

Start the server container:

```bash
docker run --rm \
  --name grpc-server \
  -p 50051:50051 \
  grpc-server:1.0.0
```

In a second terminal, run the client with a DNS target. The xDS credentials use
their insecure fallback for this non-xDS local connection:

```bash
docker run --rm \
  -e GRPC_TARGET=dns:///host.docker.internal:50051 \
  -e HELLO_NAME=Almog \
  -e REQUEST_INTERVAL=5s \
  grpc-client:1.0.0
```

## Push to Artifact Registry

```bash
docker tag grpc-client:1.0.0 \
  europe-west1-docker.pkg.dev/project-595dfcb1-d16e-4c23-83d/utila/grpc-client:1.0.0

docker push \
  europe-west1-docker.pkg.dev/project-595dfcb1-d16e-4c23-83d/utila/grpc-client:1.0.0
```

## Deploy

Before applying the sample Deployment, ensure Cloud Service Mesh supplies the
xDS bootstrap configuration to the client pod.

```bash
kubectl apply -f k8s/deployment.yaml
kubectl logs -n utila deployment/grpc-client -f
```
