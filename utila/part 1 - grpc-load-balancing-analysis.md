# Part 1: Analysis of gRPC Load-Balancing Issues

## Task 1: Identify the Issues

### Why gRPC with DNS can cause load-balancing problems

gRPC normally uses HTTP/2, which multiplexes many RPC requests over a single, long-lived TCP connection.

In Kubernetes, a standard `Service` DNS name usually resolves to one virtual `ClusterIP`. Kubernetes load balancing—typically implemented through kube-proxy—is performed when a new TCP connection is established, not for every individual gRPC request.

The request flow is therefore:

1. The gRPC client resolves the Kubernetes Service DNS name.
2. It opens an HTTP/2 connection to the Service IP.
3. Kubernetes selects one backend pod for that connection.
4. The client multiplexes many RPC calls over the same connection.
5. Those RPCs continue to reach the originally selected pod.

DNS identifies the service, but it does not automatically distribute individual RPCs among the service's pods.

A headless Service can return multiple pod IP addresses instead of a `ClusterIP`. However, this alone does not guarantee balanced traffic. Distribution still depends on the gRPC resolver and the client's load-balancing policy. If the client selects one address and maintains one connection, most or all traffic can still be sent to one pod.

## Issues caused by this approach

### 1. Uneven traffic distribution

One backend pod can receive most of the requests while the remaining replicas are underused.

For example, a service with three replicas might receive traffic like this:

| Pod | Requests per second |
| --- | ---: |
| `service-a-1` | 950 |
| `service-a-2` | 30 |
| `service-a-3` | 20 |

The overloaded pod may experience:

- High CPU or memory usage
- Increased response latency
- Request timeouts
- Out-of-memory termination
- More frequent readiness or liveness probe failures

Meanwhile, the deployment may still have plenty of unused capacity on its other replicas.

### 2. Scaling does not immediately redistribute traffic

When Kubernetes adds replicas, existing HTTP/2 connections remain attached to the original pods. A DNS update does not force healthy, established connections to reconnect.

For example:

1. A deployment scales from 3 pods to 10 pods.
2. Existing clients keep their connections to the original 3 pods.
3. The 7 new pods receive little or no traffic.
4. The original pods remain overloaded despite the additional capacity.

This reduces the effectiveness of the Horizontal Pod Autoscaler. It may also cause repeated scaling events because the metrics from the original pods remain high.

### 3. Slow reaction to pod changes

DNS records may be cached and periodically refreshed. More importantly, discovering a new address does not necessarily replace an existing healthy HTTP/2 connection.

If a pod becomes unhealthy or begins terminating:

- Clients may continue using its existing connection until it fails.
- Requests may experience errors or delays while the client reconnects.
- Multiple in-flight RPCs may fail together because they share the same connection.
- Retries may produce a sudden traffic spike against another pod.

This can reduce service reliability during deployments, pod restarts, node failures, or scaling events.

### 4. Poor fault distribution

A single HTTP/2 connection can carry many concurrent RPCs. If that connection or its selected backend pod fails, many in-flight requests can be affected at the same time.

Using multiple connections distributed across multiple pods reduces the percentage of client traffic affected by one pod or connection failure.

## Kubernetes reliability and scaling examples

### Rolling deployment

During a rolling deployment, Kubernetes creates replacement pods and terminates old ones. Long-lived gRPC connections can remain attached to old pods until those connections are closed. Requests may fail during termination if connection draining and graceful shutdown are not configured correctly.

### Horizontal scaling

When traffic increases, the Horizontal Pod Autoscaler creates more replicas. Existing gRPC clients may not open new connections, so the new replicas remain idle while the old replicas continue operating at high utilization.

### Pod or node failure

If the pod handling a client's HTTP/2 connection crashes, many RPCs may fail together. The client must detect the failure, resolve or select another endpoint, establish a new connection, and retry eligible requests.

## Why HTTP/1.1 is less affected

HTTP/1.1 cannot multiplex many concurrent requests over one connection in the same way as HTTP/2. Clients commonly use a pool of multiple TCP connections and may create new connections as concurrency increases or existing connections expire.

Each new TCP connection gives Kubernetes another opportunity to choose a backend pod:

```text
Connection 1 -> Pod A
Connection 2 -> Pod B
Connection 3 -> Pod C
Connection 4 -> Pod A
```

With gRPC over HTTP/2, the traffic pattern is often closer to:

```text
One long-lived connection -> Pod A
├── RPC 1
├── RPC 2
├── RPC 3
└── RPC 1000
```

HTTP/1.1 can still be affected by DNS caching, keep-alive connections, and connection-pool configuration. It is not completely immune to uneven traffic. However, because it usually creates or uses multiple TCP connections, Kubernetes connection-level load balancing tends to distribute HTTP/1.1 traffic more evenly than traffic sent through a single long-lived HTTP/2 connection.

## Summary

The main problem is a mismatch between the two load-balancing levels:

- Kubernetes normally balances TCP connections.
- gRPC sends many logical requests through one HTTP/2 connection.

As a result, DNS-based discovery by itself does not provide effective per-request load balancing for gRPC. This can lead to uneven pod utilization, ineffective scaling, slower failover, and a larger impact when a connection or pod fails.

---

# Part 2: Solutions Proposal

The following solutions can solve the gRPC load-balancing problem.

## 1. Golang client-side load balancing

gRPC-Go supports client-side load balancing. The client can use the `round_robin` policy instead of the default `pick_first` policy.

In Kubernetes, this should normally be combined with a headless Service:

```yaml
spec:
  clusterIP: None
```

A normal Kubernetes Service returns one `ClusterIP`. A headless Service returns the IP addresses of the pods, allowing the gRPC client to create connections to multiple backends.

The Go client can then use a configuration similar to:

```go
conn, err := grpc.NewClient(
    "dns:///orders.default.svc.cluster.local:50051",
    grpc.WithTransportCredentials(creds),
    grpc.WithDefaultServiceConfig(`{
        "loadBalancingConfig": [
            { "round_robin": {} }
        ]
    }`),
)
```

This is the simplest solution. It has no sidecar, no additional network hop, and very little infrastructure overhead.

The disadvantage is that every service must use the correct client configuration. The development team is also responsible for handling deadlines, retries, health checks, security, and observability. DNS-based round robin is suitable for basic balancing inside one cluster, but it does not provide advanced regional failover or centralized traffic management.

## 2. Linkerd

Linkerd is a lightweight Kubernetes service mesh. It adds a small proxy to each application pod. The proxy understands HTTP/2 and gRPC, discovers all available backend pods, and balances individual RPC calls between them.

Linkerd also provides useful features such as:

- Automatic mTLS
- Metrics and service monitoring
- Retries and timeouts
- Authorization policies

Linkerd is easier to operate than a complex Envoy or Istio deployment and usually requires few application changes.

Its main disadvantage is that it normally requires a sidecar proxy in every pod. Each proxy consumes CPU and memory and adds another network hop. Linkerd is therefore a good option when the company wants a simple Kubernetes service mesh and does not mind using sidecars.

## 3. Envoy

Envoy is a powerful Layer 7 proxy with native support for HTTP/2 and gRPC. It can discover backend endpoints and perform request-level load balancing using policies such as round robin, least request, weighted round robin, and ring hash.

Envoy also supports:

- Active health checks
- Retries and timeouts
- Circuit breaking
- Locality-aware routing
- Traffic splitting
- Detailed metrics and tracing

Envoy is more flexible than Linkerd, but it is also more complex. The company must operate Envoy configuration, upgrades, monitoring, and usually an xDS control plane. Envoy commonly runs as a sidecar, although it can also run as a shared gateway or node-level proxy.

A shared Envoy proxy avoids a sidecar in every pod, but it introduces an extra network tier that must be highly available and can become a bottleneck or a larger failure point.

Envoy is a good option for environments that need advanced traffic control or support many programming languages and protocols.

## 4. Managed service mesh

A managed service mesh provides the control plane as a cloud service. This reduces the amount of infrastructure that the company must install, upgrade, monitor, and maintain.

For GCP, the main managed solution is **Google Cloud Service Mesh**. Older documentation may refer to Traffic Director or Anthos Service Mesh.

Cloud Service Mesh can use Envoy proxies, but it can also configure supported gRPC clients directly through the xDS API. This is called **proxyless gRPC**.

With proxyless gRPC:

1. The Go application connects using an `xds:///` target.
2. gRPC-Go connects to the Cloud Service Mesh control plane.
3. The control plane provides endpoint and traffic information.
4. The client connects directly to healthy backend services.
5. The gRPC client performs the load balancing without a sidecar.

This provides managed service discovery, health-aware routing, traffic policies, and regional failover without sending application traffic through a proxy.

The disadvantages are greater dependency on GCP, additional cost, and some feature limitations. Proxyless gRPC does not support every feature available through a full Envoy service mesh. The supported functionality also depends on the gRPC-Go version.

Google's current SLA coverage is also different between Cloud Service Mesh deployment types. If the company requires the complete Istio feature set or the applicable managed-mesh SLA, it should verify whether the Envoy-based managed mesh is required.

## Avoiding sidecar proxies

For a Golang-based environment, the best way to avoid sidecars is to use gRPC-Go as the data plane.

There are two practical options:

- Use a headless Kubernetes Service with gRPC-Go `round_robin`.
- Use Cloud Service Mesh proxyless gRPC with the xDS resolver.

The first option is simple and works well for basic balancing inside one GKE cluster. The second option provides centralized and managed discovery, health information, routing, and failover.

Removing the sidecar reduces CPU and memory usage and avoids an additional network hop. However, mesh functionality becomes dependent on the Go library. All services must use compatible gRPC-Go versions, and features that exist only in Envoy cannot be used by proxyless clients.

## Recommendation

For a small system running only inside one GKE cluster, the recommended solution is **gRPC-Go `round_robin` with a headless Kubernetes Service**. It solves the immediate load-balancing problem with the lowest cost and complexity.

For a larger production GCP environment, the recommended solution is **Google Cloud Service Mesh with proxyless gRPC and xDS**. It is the best fit for Golang microservices because it:

- Balances individual RPC calls instead of only TCP connections.
- Does not require a sidecar proxy.
- Integrates directly with GCP.
- Provides managed endpoint discovery and health information.
- Supports regional routing and failover.
- Reduces the operational work of managing a service-mesh control plane.

Linkerd would be recommended if the company wants a simple Kubernetes mesh and accepts sidecars. Envoy would be recommended if the company needs the most advanced traffic-management features or must support many languages and protocols.

If full Istio compatibility, every Envoy feature, or Google's applicable managed-mesh SLA is a strict requirement, the company should use **managed Cloud Service Mesh with Envoy sidecars** instead of proxyless gRPC.

## References

### gRPC and Golang

- [gRPC: Custom Load Balancing Policies](https://grpc.io/docs/guides/custom-load-balancing/)
- [gRPC: Service Config](https://grpc.io/docs/guides/service-config/)
- [gRPC: Load Balancing](https://grpc.io/blog/grpc-load-balancing/)
- [gRPC-Go `roundrobin` package](https://pkg.go.dev/google.golang.org/grpc/balancer/roundrobin)
- [gRPC-Go xDS example](https://github.com/grpc/grpc-go/tree/master/examples/features/xds)
- [gRPC xDS feature status by language and version](https://github.com/grpc/grpc/blob/master/doc/grpc_xds_features.md)

### Kubernetes

- [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Kubernetes DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [Kubernetes EndpointSlices](https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/)

### Linkerd

- [Linkerd load balancing](https://linkerd.io/docs/features/load-balancing/)
- [Linkerd features](https://linkerd.io/docs/features/)
- [Linkerd: gRPC Load Balancing on Kubernetes](https://linkerd.io/2018/11/14/grpc-load-balancing-on-kubernetes-without-tears/)
- [Linkerd native sidecars](https://linkerd.io/docs/features/native-sidecars/)

### Envoy

- [Envoy load-balancing overview](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/load_balancing/overview)
- [Envoy supported load balancers](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/load_balancing/load_balancers)
- [Envoy request lifecycle](https://www.envoyproxy.io/docs/envoy/latest/intro/life_of_a_request)
- [Envoy locality-weighted load balancing](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/load_balancing/locality_weight)

### Google Cloud Service Mesh

- [Cloud Service Mesh overview](https://docs.cloud.google.com/service-mesh/docs/overview)
- [Cloud Service Mesh proxyless gRPC overview](https://docs.cloud.google.com/service-mesh/docs/service-routing/proxyless-overview)
- [Set up proxyless gRPC services](https://docs.cloud.google.com/service-mesh/docs/service-routing/set-up-proxyless-mesh)
- [Proxyless gRPC supported features](https://docs.cloud.google.com/service-mesh/docs/service-routing/features)
- [Proxyless gRPC limitations](https://docs.cloud.google.com/service-mesh/docs/service-routing/limitations-proxyless)
- [Proxyless gRPC security](https://docs.cloud.google.com/service-mesh/docs/service-routing/security-overview)
- [Proxyless gRPC observability](https://docs.cloud.google.com/service-mesh/docs/service-routing/observability-proxyless-grpc)
- [Cloud Service Mesh supported platforms](https://docs.cloud.google.com/service-mesh/docs/supported-platforms)
- [Managed Cloud Service Mesh control plane on GKE](https://docs.cloud.google.com/service-mesh/docs/onboarding/provision-control-plane)
- [Cloud Service Mesh SLA overview](https://cloud.google.com/service-mesh/sla-overview)
- [Cloud Service Mesh pricing](https://cloud.google.com/service-mesh/pricing)
