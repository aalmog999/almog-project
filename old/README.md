# Almog Project

This project contains two parts:

1. A Jenkins + Helm deployment flow for deploying a generic Helm chart to AKS.
2. A small Python Book Fetcher script using Pydantic and a public book API.

---

# Part 1: Generic Helm Chart Deployment to AKS

## Overview

This project deploys a simple web application to Azure Kubernetes Service using:

- Jenkins
- Helm
- kubectl
- Azure CLI
- kubelogin
- Azure Managed Identity

Jenkins is installed on an Azure VM.  
The VM connects to Azure using Managed Identity.

---

## AKS Details

```text
AKS name: devops-interview-aks
Resource group: devops-interview-rg
```

---

## Required Tools on Jenkins VM

The Jenkins VM should already have:

```bash
az
kubectl
kubelogin
helm
git
```

---

## Manual AKS Login Test

Run this on the Jenkins VM:

```bash
az login -i

az aks get-credentials \
  -n devops-interview-aks \
  -g devops-interview-rg \
  --overwrite-existing

export KUBECONFIG=~/.kube/config

kubelogin convert-kubeconfig -l msi

kubectl get nodes
```

---

## Example Helm Chart Structure

```text
.
├── Jenkinsfile
├── helm
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values.schema.json
│   └── templates
│       ├── deployment.yaml
│       ├── service.yaml
│       └── ingress.yaml
|       └── etc..
├── fetcher.py
├── requirements.txt
└── README.md
```

---

## Example Service Values

```yaml
service:
  annotations: {}
  labels: {}
  type: ClusterIP
  loadBalancerIP: ""
  ports:
    port: 80
    targetPort: 80
    name: "http"
```

---

## Example Ingress Values

This ingress exposes the application on the `/almog` path.

```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  labels: {}
  rules:
    - http:
        paths:
          - path: /almog
            pathType: Prefix
            backend:
              service:
                name: simple-web
                port:
                  number: 80
```

---

## Manual Helm Deploy

```bash
helm upgrade --install simple-web ./helm \
  --namespace almog \
  --create-namespace \
  --values ./helm/values.yaml \
  --set global.namespace=almog \
  --wait \
  --timeout 10m
```

---

## Manual Helm Destroy

```bash
helm uninstall simple-web -n almog
```

---

## Jenkins Pipeline

The Jenkins pipeline supports two actions:

```text
deploy
destroy
```

Example parameters:

```text
ACTION=deploy
NAMESPACE=almog
RELEASE_NAME=simple-web
CHART_PATH=./helm
VALUES_FILE=./helm/values.yaml
```

The pipeline does the following:

1. Checks out the GitHub repository
2. Logs in to Azure using Managed Identity
3. Gets AKS credentials
4. Converts kubeconfig using kubelogin
5. Deploys or destroys the Helm release

---

## Test the Deployment

Check the pods:

```bash
kubectl get pods -n almog
```

Check the service:

```bash
kubectl get svc -n almog
```

Check the ingress:

```bash
kubectl get ingress -n almog
```

Get the external IP:

```bash
kubectl get svc -A | grep -i LoadBalancer
```

Test externally:

```bash
curl -v http://<EXTERNAL-IP>/almog
```

Example:

```bash
curl -v http://20.160.150.7/almog
```

Expected result:

```text
HTTP/1.1 200 OK
```

---

### Pod is stuck in Pending

Check the pod events:

```bash
kubectl describe pod <pod-name> -n almog
```

Common reasons:

- Not enough CPU
- Node taints
- Node is unschedulable

Check nodes:

```bash
kubectl get nodes
kubectl top nodes
```

---

### Ingress is not working

Check ingress:

```bash
kubectl describe ingress simple-web -n almog
```

Check endpoints:

```bash
kubectl get endpoints -n almog
```

Check the ingress controller:

```bash
kubectl get pods -A | grep ingress
kubectl get svc -A | grep LoadBalancer
```

---

# Part 2: Python Small Book Fetcher

## Overview

This is a small Python script that:

- Calls the Open Library public API
- Parses the response using Pydantic models
- Filters books by two criteria
- Writes the filtered results to a JSON file
- Uses a simple output writer interface so more output formats can be added later

---

## Public API

The script uses:

```text
https://openlibrary.org/search.json?q=python
```

Browser-like headers are used because Open Library may return `403 Forbidden` for simple non-browser requests.

---

## Requirements

Python 3.10 or newer is recommended.

Install dependencies:

```bash
python3 -m pip install -r requirements.txt
```

Example `requirements.txt`:

```text
requests
pydantic
```

---

## Run the Script

```bash
python3 fetcher.py
```

The script creates:

```text
filtered_books.json
```

---

## Filtering Criteria

The script filters books by:

```text
1. Title contains the keyword "python"
2. First publish year is greater than or equal to 2010
```

These values are configured in `main()`:

```python
query = "python"
title_keyword = "python"
min_publish_year = 2010
```

---

## Example Output

```json
[
  {
    "title": "Python Crash Course",
    "authors": ["Eric Matthes"],
    "first_publish_year": 2015,
    "edition_count": 10,
    "open_library_key": "/works/OL..."
  }
]
```

---

## Code Structure

The script is split into simple sections:

```text
Pydantic models
API client
Filtering logic
Output writer
Main function
```

Main models:

```text
Book
OpenLibraryBookItem
OpenLibraryResponse
```

Main classes/functions:

```text
OpenLibraryClient
filter_books()
BookOutputWriter
JsonBookOutputWriter
main()
```

---

## Future Output Formats

Only JSON output is implemented.

The code uses this interface:

```python
class BookOutputWriter(ABC):
    @abstractmethod
    def write(self, books: list[Book], output_path: str | Path) -> None:
        pass
```

This makes it easy to add more writers later, for example:

```text
CsvBookOutputWriter
YamlBookOutputWriter
TextBookOutputWriter
```

---

## Example Successful Run

```text
Fetched books: 50
Filtered books: 12
Output file: filtered_books.json
```
