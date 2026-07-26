# Proxyless gRPC on GKE with Cloud Service Mesh

This Terraform project creates the Google Cloud infrastructure required to run a proxyless gRPC client and server on GKE.

The gRPC client connects directly to Google Cloud Service Mesh through the xDS API. No Envoy sidecar is required.

## Architecture

The project creates:

- A custom VPC and subnet
- Secondary IP ranges for GKE Pods and Services
- Cloud Router and Cloud NAT
- A private-node GKE cluster
- A dedicated GKE node service account
- Required Google Cloud APIs and IAM permissions
- A global Cloud Service Mesh resource
- A gRPC health check
- An `INTERNAL_SELF_MANAGED` GRPC backend service
- A `GRPCRoute`
- A firewall rule for Google health-check probes

The Kubernetes gRPC Service creates standalone zonal NEGs. Terraform attaches these NEGs to the Cloud Service Mesh backend service.

## Directory structure

```text
.
├── main.tf
├── outputs.tf
├── providers.tf
├── terraform.tfvars
├── variables.tf
└── modules
    ├── cloud-service-mesh
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── gke
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    └── network
        ├── main.tf
        ├── outputs.tf
        └── variables.tf
```

## Prerequisites

Install:

- Terraform 1.6 or later
- Google Cloud CLI
- `kubectl`
- `gke-gcloud-auth-plugin`

You also need:

- A Google Cloud project with billing enabled
- Permission to enable APIs
- Permission to create GKE, IAM and networking resources

## Authentication

Authenticate the Google Cloud CLI:

```bash
gcloud auth login
gcloud auth application-default login
```

Select the project:

```bash
gcloud config set project project-595dfcb1-d16e-4c23-83d
```

Terraform uses Application Default Credentials created by:

```bash
gcloud auth application-default login
```

## Configuration

Create `terraform.tfvars` with the required parameters according to the terraform.tfvars file.

The environment is declared only once:

```hcl
environment = "dev"
```

Terraform uses it to build resource names such as:

```text
dev-proxyless-grpc-gke
dev-proxyless-grpc-vpc
dev-proxyless-grpc-mesh
dev-proxyless-grpc-backend
dev-proxyless-grpc-route
```

## First Terraform deployment

Initialize Terraform:

```bash
terraform init
```

Format and validate:

```bash
terraform fmt -recursive
terraform validate
```

Review the plan:

```bash
terraform plan
```

Create the infrastructure:

```bash
terraform apply
```

## Connect to GKE

Display the generated credentials command:

```bash
terraform output -raw get_credentials_command
```

Run the returned command. For example, for a zonal cluster:

```bash
gcloud container clusters get-credentials \
  dev-proxyless-grpc-gke \
  --zone europe-west1-b \
  --project project-595dfcb1-d16e-4c23-83d
```

For a regional cluster, use `--region europe-west1` instead of `--zone`.

Verify access:

```bash
kubectl get nodes
```

## Deploy the gRPC server and create NEGs

Argo CD deploys the gRPC server and client into the `utila` namespace.

The gRPC server Service must include the standalone NEG annotation:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: grpc-server
  namespace: utila
  annotations:
    cloud.google.com/neg: '{"exposed_ports":{"50051":{"name":"dev-helloworld-grpc"}}}'
spec:
  type: ClusterIP
  ports:
    - name: grpc
      port: 50051
      targetPort: 50051
      protocol: TCP
  selector:
    app.kubernetes.io/name: grpc-server
```

Verify the applications:

```bash
kubectl get pods -n utila
```

Expected:

```text
grpc-server-...   1/1   Running
grpc-client-...   1/1   Running
```

## Test the application

Follow the client logs:

```bash
kubectl logs deployment/grpc-client \
  -n utila \
  -c grpc-client \
  --follow
```

Expected:

```text
SayHello response: Hello GKE client, from grpc-server-...
```

This confirms that the client received the server endpoints from Cloud Service Mesh through xDS and successfully called `SayHello`.

Verify the server:

```bash
kubectl logs deployment/grpc-server -n utila
```

Expected:

```text
gRPC server listening on :50051
```

`grpc-td-init` is only an init container that creates the xDS bootstrap file and exits.

## Cleanup

```bash
terraform destroy
```
