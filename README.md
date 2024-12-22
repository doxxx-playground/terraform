# Rust API Server Helm Chart

This project provides a Helm chart for deploying a Rust API server in a Kubernetes environment.
The chart includes configurations for the API deployment, service, and environment variables.

The Rust API server is designed to be a scalable and efficient backend service.
It includes health check endpoints, Prometheus metrics exposure, and configurable database connections.
This chart allows for easy deployment and configuration of the API server across different environments.

## Repository Structure

```mermaid
graph TB
    subgraph Kubernetes["Kubernetes Cluster"]
        subgraph mon["Monitoring Namespace"]
            PROM["Prometheus Stack"]
            GRAF["Grafana"]
            ALERT["Alertmanager"]
            KSM["Kube State Metrics"]
            NODE["Node Exporter"]
            SM["Service Monitor"]
            
            PROM --> GRAF
            PROM --> ALERT
            PROM --> KSM
            PROM --> NODE
            SM --> PROM
        end

        subgraph def["Default Namespace"]
            API["Rust API Server"]
            DB[("PostgreSQL")]
            
            API --> DB
        end

        SM -.- API
    end

    subgraph Helm["Helm Charts"]
        HC1["postgresql-chart"]
        HC2["api-chart"]
        HC3["kube-prometheus-stack"]
    end

    HC1 --> DB
    HC2 --> API
    HC3 --> PROM

    classDef namespace fill:#326ce5,stroke:#fff,stroke-width:2px,color:#fff
    classDef app fill:#00c7b7,stroke:#fff,stroke-width:2px,color:#fff
    classDef monitoring fill:#e6522c,stroke:#fff,stroke-width:2px,color:#fff
    classDef helm fill:#0F1689,stroke:#fff,stroke-width:2px,color:#fff

    class mon,def namespace
    class API,DB app
    class PROM,GRAF,ALERT,KSM,NODE,SM monitoring
    class HC1,HC2,HC3 helm
```

```
.
├── helm
│   └── api
│       ├── Chart.yaml
│       ├── templates
│       │   ├── configmap.yaml
│       │   ├── deployment.yaml
│       │   └── service.yaml
│       └── values.yaml
├── main.tf
├── monitoring.tf
├── provider.tf
└── variables.tf
```

- `helm/api/`: Contains the Helm chart for the Rust API server
  - `Chart.yaml`: Defines the Helm chart metadata
  - `templates/`: Contains Kubernetes resource templates
    - `configmap.yaml`: Defines environment variables for the API
    - `deployment.yaml`: Specifies the API deployment configuration
    - `service.yaml`: Defines the Kubernetes service for the API
  - `values.yaml`: Default configuration values for the Helm chart
- `main.tf`, `monitoring.tf`, `provider.tf`, `variables.tf`: Terraform configuration files (not detailed in this README)

## Usage Instructions

### Prerequisites

- Kubernetes cluster (version 1.16+)
- Helm (version 3.0+)
- kubectl configured to communicate with your cluster

### Installation

1. Clone the repository:

```bash
git clone <repository-url>
cd <repository-name>/helm/api
```

2. Update the `values.yaml` file with your specific configuration:

```yaml
image:
  repository: your-docker-registry/api
  tag: your-version
  pullPolicy: IfNotPresent

replicaCount: 2

service:
  type: ClusterIP
  port: 8080

configmap:
  HOST: "0.0.0.0"
  PORT: "8080"
  RUST_LOG: "info"
  DATABASE_URL: "postgres://your-user:your-password@your-db-host:5432/your-db-name?sslmode=disable"
```

3. Install the Helm chart:

```bash
helm install my-api-release ./
```

Replace `my-api-release` with your desired release name.

### Configuration

The following table lists the configurable parameters of the Rust API server chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Docker image repository | `api` |
| `image.tag` | Docker image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `replicaCount` | Number of API replicas | `1` |
| `service.type` | Kubernetes Service type | `ClusterIP` |
| `service.port` | Kubernetes Service port | `8080` |
| `configmap.HOST` | API server host | `"0.0.0.0"` |
| `configmap.PORT` | API server port | `"8080"` |
| `configmap.RUST_LOG` | Rust log level | `"info"` |
| `configmap.DATABASE_URL` | Database connection URL | `"postgres://myuser:mypass@postgresql-dev:5432/mydb?sslmode=disable"` |

To override these values, you can either edit the `values.yaml` file or use the `--set` flag when running `helm install` or `helm upgrade`.

### Accessing the API

After deploying the chart, you can access the API within your cluster using the service name and port:

```
http://<release-name>-api:8080
```

To access the API from outside the cluster, you may need to set up an Ingress or change the service type to LoadBalancer.

### Health Checks

The API deployment includes liveness and readiness probes configured to check the `/health` endpoint on port 8080.
These ensure that Kubernetes can monitor the health of your API pods.
![img_1.png](img_1.png)
### Metrics

The service is configured with annotations for Prometheus to scrape metrics from the `/metrics` endpoint on port 8080.
![img.png](img.png)
## Data Flow

The Rust API server follows a typical request-response flow:

1. Client sends a request to the Kubernetes Service
2. Service routes the request to one of the API pods
3. API pod processes the request, potentially interacting with the database
4. API pod sends the response back to the client

```
Client -> Service -> API Pod -> Database
           ^                     |
           |                     |
           +---------------------+
```

The API pods are stateless and can be scaled horizontally for increased performance.
Database connections are managed using the `DATABASE_URL` environment variable.

## Troubleshooting

### Common Issues

1. Pods failing to start:
   - Check the pod logs: `kubectl logs <pod-name>`
   - Ensure the Docker image is accessible and correctly specified in `values.yaml`
   - Verify that the database URL is correct and the database is reachable

2. API not accessible:
   - Confirm the service is running: `kubectl get services`
   - Check if pods are in Ready state: `kubectl get pods`
   - Verify the service type and port in `values.yaml`

3. Database connection issues:
   - Double-check the `DATABASE_URL` in `values.yaml`
   - Ensure the database is running and accessible from the Kubernetes cluster
   - Check for any network policies that might be blocking the connection

### Debugging

To enable verbose logging:

1. Set the `RUST_LOG` environment variable to `debug` in `values.yaml`:

```yaml
configmap:
  RUST_LOG: "debug"
```

2. Upgrade the Helm release:

```bash
helm upgrade my-api-release ./
```

3. Check the pod logs for detailed output:

```bash
kubectl logs -f <pod-name>
```

### Performance Optimization

1. Monitor API response times and resource usage using Prometheus and Grafana
2. Adjust the `replicaCount` in `values.yaml` to scale the number of API pods
3. Optimize database queries and consider implementing caching if necessary
4. Use a profiling tool like `perf` or `flamegraph` to identify performance bottlenecks in the Rust code

For persistent performance issues, consider reviewing and optimizing the Rust code itself.
