# generic chart - TBD

## TL;DR;

```console
$ helm install service .
```

## Introduction

This chart bootstraps a deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.
It provisions a fully featured service installation.

## Installing the Chart

To install the chart with the release name `service`:

```console
$ helm install service .
```

## Uninstalling the Chart

To uninstall the `service` deployment:

```console
$ helm uninstall service
```

## Configuration

The following table lists the configurable parameters of the service chart and their default values.

| Parameter | Description | Default |
|---|---|---|
| `fullnameOverride` | Optionally override the fully qualified name | `""` |
| `nameOverride` | Optionally override the name | `""` |
| `replicas` | The number of replicas to create | `1` |
| `image.repository` | The service image repository | `docker.io/jboss/service` |
| `image.tag` | Overrides the service image tag whose default is the chart version | `""` |
| `image.pullPolicy` | The service image pull policy | `IfNotPresent` |
| `imagePullSecrets` | Image pull secrets for the Pod | `[]` |
| `hostAliases` | Mapping between IPs and hostnames that will be injected as entries in the Pod's hosts files | `[]` |
| `enableServiceLinks` | Indicates whether information about services should be injected into Pod's environment variables, matching the syntax of Docker links | `true` |
| `restartPolicy` | Pod restart policy. One of `Always`, `OnFailure`, or `Never` | `Always` |
| `serviceAccount.create` | Specifies whether a ServiceAccount should be created | `true` |
| `serviceAccount.name` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template | `""` |
| `serviceAccount.annotations` | Additional annotations for the ServiceAccount | `{}` |
| `serviceAccount.labels` | Additional labels for the ServiceAccount | `{}` |
| `serviceAccount.imagePullSecrets` | Image pull secrets that are attached to the ServiceAccount | `[]` |
| `rbac.create` | Specifies whether RBAC resources are to be created | `false`
| `rbac.rules` | Custom RBAC rules, e. g. for KUBE_PING | `[]`
| `podSecurityContext` | SecurityContext for the entire Pod. Every container running in the Pod will inherit this SecurityContext. This might be relevant when other components of the environment inject additional containers into running Pods (service meshes are the most prominent example for this) | `{"fsGroup":1000}` |
| `securityContext` | SecurityContext for the service container | `{"runAsNonRoot":true,"runAsUser":1000}` |
| `extraInitContainers` | Additional init containers, e. g. for providing custom themes | `[]` |
| `extraContainers` | Additional sidecar containers, e. g. for a database proxy, such as Google's cloudsql-proxy | `[]` |
| `lifecycleHooks` | Lifecycle hooks for the service container | `{}` |
| `terminationGracePeriodSeconds` | Termination grace period in seconds for service shutdown. Clusters with a large cache might need to extend this to give Infinispan more time to rebalance | `60` |
| `clusterDomain` | The internal Kubernetes cluster domain | `cluster.local` |
| `command` | Overrides the default entrypoint of the service container | `[]` |
| `args` | Overrides the default args for the service container | `[]` |
| `extraEnv` | Additional environment variables for service | `""` |
| `extraEnvFrom` | Additional environment variables for service mapped from a Secret or ConfigMap | `""` |
| `affinity` | Pod affinity | Hard node and soft zone anti-affinity |
| `nodeSelector` | Node labels for Pod assignment | `{}` |
| `tolerations` | Node taints to tolerate | `[]` |
| `podLabels` | Additional Pod labels | `{}` |
| `podAnnotations` | Additional Pod annotations | `{}` |
| `livenessProbe` | Liveness probe configuration | `{"httpGet":{"path":"/health/live","port":"http"},"initialDelaySeconds":300,"timeoutSeconds":5}` |
| `readinessProbe` | Readiness probe configuration | `{"httpGet":{"path":"/auth/realms/master","port":"http"},"initialDelaySeconds":30,"timeoutSeconds":1}` |
| `resources` | Pod resource requests and limits | `{}` |
| `configmap` | Startup scripts to run before service starts up | `{"service.cli":"{{- .Files.Get "scripts/service.cli" \| nindent 2 }}"}` |
| `extraVolumes` | Add additional volumes, e. g. for custom themes | `""` |
| `extraVolumeMounts` | Add additional volumes mounts, e. g. for custom themes | `""` |
| `extraPorts` | Add additional ports, e. g. for admin console or exposing JGroups ports | `[]` |
| `podDisruptionBudget` | Pod disruption budget | `{}` |
| `deploymentAnnotations` | Annotations for the deployment | `{}` |
| `deploymentLabels` | Additional labels for the deployment | `{}` |
| `secrets` | Configuration for secrets that should be created | `{}` |
| `service.annotations` | Annotations for headless and HTTP Services | `{}` |
| `service.labels` | Additional labels for headless and HTTP Services | `{}` |
| `service.type` | The Service type | `ClusterIP` |
| `service.loadBalancerIP` | Optional IP for the load balancer. Used for services of type LoadBalancer only | `""` |
| `loadBalancerSourceRanges` | Optional List of allowed source ranges (CIDRs). Used for service of type LoadBalancer only | `[]`  |
| `service.extraPorts` | Service ports, e. g. for custom admin console | `[]` |
| `service.sessionAffinity` | sessionAffinity for Service, e. g. "ClientIP" | `""` |
| `service.sessionAffinityConfig` | sessionAffinityConfig for Service | `{}` |
| `ingress.enabled` | If `true`, an Ingress is created | `false` |
| `ingress.rules` | List of Ingress Ingress rule | see below |
| `ingress.rules[0].host` | Host for the Ingress rule | `{{ .Release.Name }}.service.example.com` |
| `ingress.rules[0].paths` | Paths for the Ingress rule | `[/]` |
| `ingress.servicePort` | The Service port targeted by the Ingress | `http` |
| `ingress.annotations` | Ingress annotations | `{}` |
| `ingress.labels` | Additional Ingress labels | `{}` |
| `ingress.tls` | TLS configuration | see below |
| `ingress.tls[0].hosts` | List of TLS hosts | `[service.example.com]` |
| `ingress.tls[0].secretName` | Name of the TLS secret | `""` |
| `networkPolicy.enabled` | If true, the ingress network policy is deployed | `false`
| `networkPolicy.extraFrom` | Allows to define allowed external traffic (see Kubernetes doc for network policy `from` format) | `[]`
| `autoscaling.enabled` | Enable creation of a HorizontalPodAutoscaler resource | `false` |
| `autoscaling.labels` | Additional labels for the HorizontalPodAutoscaler resource | `{}` |
| `autoscaling.minReplicas` | The minimum number of Pods when autoscaling is enabled | `3` |
| `autoscaling.maxReplicas` | The maximum number of Pods when autoscaling is enabled | `10` |
| `autoscaling.metrics` | The metrics configuration for the HorizontalPodAutoscaler | `[{"resource":{"name":"cpu","target":{"averageUtilization":80,"type":"Utilization"}},"type":"Resource"}]` |
| `autoscaling.metrics` | The metrics configuration for the HorizontalPodAutoscaler | `[{"resource":{"name":"memory","target":{"averageUtilization":80,"type":"Utilization"}},"type":"Resource"}]` |
| `autoscaling.behavior` | The scaling policy configuration for the HorizontalPodAutoscaler | `{"scaleDown":{"policies":[{"periodSeconds":300,"type":"Pods","value":1}],"stabilizationWindowSeconds":300}` |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example:

```console
$ helm install service -n service --set replicas=1  .
```

Alternatively, a YAML file that specifies the values for the parameters can be provided while
installing the chart. For example:

```console
$ helm install service -n service --values values.yaml .
```

The chart offers great flexibility.
It can be configured to work with the official service Docker image but any custom image can be used as well.

For the offical Docker image, please check it's configuration at https://github.com/service/service-containers/tree/master/server.

### Usage of the `tpl` Function

The `tpl` function allows us to pass string values from `values.yaml` through the templating engine.
It is used for the following values:

* `extraInitContainers`
* `extraContainers`
* `extraEnv`
* `extraEnvFrom`
* `affinity`
* `extraVolumeMounts`
* `extraVolumes`
* `livenessProbe`
* `readinessProbe`

Additionally, custom labels and annotations can be set on various resources the values of which being passed through `tpl` as well.

It is important that these values be configured as strings.
Otherwise, installation will fail.
See example for Google Cloud Proxy or default affinity configuration in `values.yaml`.

### Examples

```yaml
extraEnv: |
  - name: KEY
    value: 'value'


extraVolumeMounts: |
  - name: demo
    mountPath: /mnt/
    readOnly: true

extraVolumes: |
  - name: demo
    secret:
      secretName: service-demo

rbac:
  create: true
  rules:
    - apiGroups:
        - ""
      resources:
        - pods
      verbs:
        - get
        - list

extraInitContainers: |
  - name: demo
    image: alpine
    imagePullPolicy: IfNotPresent
    command:
      - sh
    args:
      - -c
      - |
        echo "Hello World..."
    volumeMounts:
      - name: demo
        mountPath: /demo

extraVolumeMounts: |
  - name: demo
    mountPath: /mnt

extraVolumes: |
  - name: demo
    emptyDir: {}
```

#### Autoscaling

Due to the caches in service only replicating to a few nodes (two in the example configuration above) and the limited controls around autoscaling built into Kubernetes, it has historically been problematic to autoscale service.
However, in Kubernetes 1.18 [additional controls were introduced](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#support-for-configurable-scaling-behavior) which make it possible to scale down in a more controlled manner.

The example autoscaling configuration in the values file scales from three up to a maximum of ten Pods using CPU/Memory utilization as the metric. Scaling up is done as quickly as required but scaling down is done at a maximum rate of one Pod per five minutes.

Autoscaling can be enabled as follows:

```yaml
autoscaling:
  enabled: true
```

```yaml
livenessProbe: |
  httpGet:
    path: /liveness
    port: http
  initialDelaySeconds: 300
  timeoutSeconds: 5

readinessProbe: |
  httpGet:
    path: /readiness
    port: http
  initialDelaySeconds: 30
  timeoutSeconds: 1
```

The above YAML references introduces the custom value `contextPath` which is possible because `configmap`, `livenessProbe`, and `readinessProbe` are templated using the `tpl` function.
Note that it must not start with a slash.
Alternatively, you may supply it via CLI flag