# Kubernetes Guestbook Lab

> My first Kubernetes practice project - A hands-on tutorial for learning K8s fundamentals

**Goal**: Learn Kubernetes deployments, services, and scaling by building a multi-tier web application with Redis backend and PHP frontend.

## Table of Contents
- [Architecture](#architecture)
- [Quick Setup](#quick-setup)
- [Kubernetes Manifests](#kubernetes-manifests)
- [Verify and Monitor](#verify-and-monitor)
- [Scaling](#scaling)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)
- [References](#references)

## References

**Source**: [Google Cloud Kubernetes Engine Tutorial](https://cloud.google.com/kubernetes-engine/docs/tutorials/guestbook)

**Additional Resources**:
- [Kubernetes Official Documentation](https://kubernetes.io/docs/)
- [Kubernetes Concepts](https://kubernetes.io/docs/concepts/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                       │
│                                                             │
│  ┌─────────────────┐    ┌─────────────────────────────────┐ │
│  │   Frontend      │    │           Backend               │ │
│  │   (3 replicas)  │    │                                 │ │
│  │                 │    │  ┌─────────────┐                │ │
│  │ ┌─────────────┐ │    │  │Redis Leader │                │ │
│  │ │  PHP App    │ │◄───┤  │ (1 replica) │                │ │
│  │ │   Pod 1     │ │    │  │   (writes)  │                │ │
│  │ └─────────────┘ │    │  └─────────────┘                │ │
│  │ ┌─────────────┐ │    │         │                       │ │
│  │ │  PHP App    │ │    │         ▼                       │ │
│  │ │   Pod 2     │ │    │  ┌─────────────┐                │ │
│  │ └─────────────┘ │    │  │Redis Follower│               │ │
│  │ ┌─────────────┐ │    │  │ (2 replicas) │               │ │
│  │ │  PHP App    │ │◄───┤  │   (reads)   │               │ │
│  │ │   Pod 3     │ │    │  └─────────────┘                │ │
│  │ └─────────────┘ │    │                                 │ │
│  └─────────────────┘    └─────────────────────────────────┘ │
│           │                                                 │
│           ▼                                                 │
│  ┌─────────────────┐                                       │
│  │Frontend Service │                                       │
│  │   (NodePort)    │                                       │
│  │  Port: 30959    │                                       │
│  └─────────────────┘                                       │
│           │                                                 │
└───────────┼─────────────────────────────────────────────────┘
            │
            ▼
    ┌─────────────────┐
    │ External Access │
    │ http://<node-ip>│
    │     :30959      │
    └─────────────────┘
```

**Components:**
- **Frontend**: 3 PHP pods serving web UI
- **Redis Leader**: 1 pod handling writes
- **Redis Followers**: 2 pods handling reads
- **Services**: Internal cluster communication + NodePort for external access
- **Access**: NodePort on port 30959 (`http://<node-ip>:30959`)

## Quick Setup

### 1. Deploy Redis Leader
```bash
kubectl apply -f redis-leader-deployment.yaml
```
```
deployment.apps/redis-leader created
```


```bash
kubectl get pods
```
```
NAME                            READY   STATUS    RESTARTS   AGE
redis-leader-665d87459f-nlq45   1/1     Running   0          4m
```

### 2. Deploy Redis Followers  
```bash
kubectl apply -f redis-follower-deployment.yaml
```
```
deployment.apps/redis-follower created
```



```bash
kubectl get pods
```
```
NAME                              READY   STATUS    RESTARTS   AGE
redis-follower-66847965fb-h8nlv   1/1     Running   0          3s
redis-follower-66847965fb-vbdd2   1/1     Running   0          3s
redis-leader-665d87459f-nlq45     1/1     Running   0          17m
```

### 3. Deploy Frontend
```bash
kubectl apply -f frontend-deployment.yaml
```
```
deployment.apps/frontend created
```


```bash
kubectl get pods -l app=guestbook -l tier=frontend
```
```
NAME                        READY   STATUS    RESTARTS   AGE
frontend-6b46678c94-lksnc   1/1     Running   0          64m
frontend-6b46678c94-mqqx2   1/1     Running   0          64m
frontend-6b46678c94-p5nrg   1/1     Running   0          64m
```

### 4. Access Application

#### Method 1: NodePort (Direct Node Access)
The frontend service is configured as **NodePort** on port 30959 for direct external access:

```bash
kubectl get service frontend-nodeport
```
```
NAME                TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
frontend-nodeport   NodePort   10.103.66.175   <none>        80:30959/TCP   5m
```

**Access the application**:
- On bare metal/VM: `http://<node-ip>:30959`
- On Minikube: `minikube service frontend-nodeport`

To find your node IP:
```bash
kubectl get nodes -o wide
```

#### Method 2: Port Forwarding (Temporary/Development)
```bash
kubectl port-forward svc/frontend-nodeport 8081:80
```
```
Forwarding from 127.0.0.1:8081 -> 80
Forwarding from [::1]:8081 -> 80
```
Open: http://localhost:8081/

#### Method 3: LoadBalancer (Cloud Production)
For cloud environments, edit [frontend-service.yaml](frontend-service.yaml) to change type to LoadBalancer:
```yaml
type: LoadBalancer  # Change from NodePort
```
```bash
kubectl apply -f frontend-service.yaml
kubectl get service frontend-nodeport
```
```
NAME                TYPE           CLUSTER-IP      EXTERNAL-IP        PORT(S)        AGE
frontend-nodeport   LoadBalancer   10.51.242.136   109.197.92.229     80:32372/TCP   1m
```

### 5. Scale Application
```bash
kubectl scale deployment frontend --replicas=5
```
```
deployment.apps/frontend scaled
```

```bash
kubectl get pods
```
```
NAME                              READY   STATUS    RESTARTS   AGE
frontend-6b46678c94-lksnc         1/1     Running   0          72m
frontend-6b46678c94-mqqx2         1/1     Running   0          72m
frontend-6b46678c94-p4php         1/1     Running   0          6s
frontend-6b46678c94-p5nrg         1/1     Running   0          72m
frontend-6b46678c94-z9pqm         1/1     Running   0          6s
redis-follower-66847965fb-h8nlv   1/1     Running   0          77m
redis-follower-66847965fb-vbdd2   1/1     Running   0          77m
redis-leader-665d87459f-nlq45     1/1     Running   0          94m
```

---

## Kubernetes Manifests

### Redis Leader (Backend - Write Operations)

**Deployment** ([redis-leader-deployment.yaml](redis-leader-deployment.yaml)):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-leader
  labels:
    app: redis
    role: leader
    tier: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
        role: leader
        tier: backend
    spec:
      containers:
      - name: leader
        image: "docker.io/redis:6.0.5"
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
        ports:
        - containerPort: 6379
```

**Service** ([redis-leader-service.yaml](redis-leader-service.yaml)):
```yaml
apiVersion: v1
kind: Service
metadata:
  name: redis-leader
  labels:
    app: redis
    role: leader
    tier: backend
spec:
  ports:
  - port: 6379
    targetPort: 6379
  selector:
    app: redis
    role: leader
    tier: backend
```

**Key Concepts**:
- Single replica for write consistency
- ClusterIP service (internal only)
- Selector matches pod labels for routing

### Redis Follower (Backend - Read Operations)

**Deployment** ([redis-follower-deployment.yaml](redis-follower-deployment.yaml)):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-follower
  labels:
    app: redis
    role: follower
    tier: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
        role: follower
        tier: backend
    spec:
      containers:
      - name: follower
        image: us-docker.pkg.dev/google-samples/containers/gke/gb-redis-follower:v2
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
        ports:
        - containerPort: 6379
```

**Service** ([redis-follower-service.yaml](redis-follower-service.yaml)):
```yaml
apiVersion: v1
kind: Service
metadata:
  name: redis-follower
  labels:
    app: redis
    role: follower
    tier: backend
spec:
  ports:
  - port: 6379
  selector:
    app: redis
    role: follower
    tier: backend
```

**Key Concepts**:
- 2 replicas for read scalability
- Automatic replication from leader
- Service load balances across replicas

### Frontend (PHP Application)

**Deployment** ([frontend-deployment.yaml](frontend-deployment.yaml)):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
        app: guestbook
        tier: frontend
  template:
    metadata:
      labels:
        app: guestbook
        tier: frontend
    spec:
      containers:
      - name: php-redis
        image: us-docker.pkg.dev/google-samples/containers/gke/gb-frontend:v5
        env:
        - name: GET_HOSTS_FROM
          value: "dns"
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
        ports:
        - containerPort: 80
```

**Service** ([frontend-service.yaml](frontend-service.yaml)):
```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-nodeport
spec:
  selector:
    app: guestbook
    tier: frontend
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30959
  type: NodePort
```

**Key Concepts**:
- 3 replicas for high availability
- Environment variable for DNS-based service discovery
- NodePort service for external access
- Service selector must match pod labels exactly

---

## Verify and Monitor

### Check All Resources
```bash
kubectl get pods                    # Check all pods
kubectl get services               # Check all services
kubectl get deployments            # Check deployments
```

**Example output**:
```
NAME             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
frontend         ClusterIP   10.103.66.175   <none>        80/TCP     2s
kubernetes       ClusterIP   10.96.0.1       <none>        443/TCP    113m
redis-follower   ClusterIP   10.102.77.64    <none>        6379/TCP   68m
redis-leader     ClusterIP   10.109.136.67   <none>        6379/TCP   76m
```

### Useful Monitoring Commands
```bash
# Watch pod status in real-time
kubectl get pods -w

# Describe a specific pod (for debugging)
kubectl describe pod <pod-name>

# View pod logs
kubectl logs <pod-name>

# View logs for all pods with a label
kubectl logs -l app=guestbook

# Get detailed info about a service
kubectl describe service frontend
```

---

## Scaling

You can easily scale your deployments up or down:

```bash
# Scale frontend to 5 replicas
kubectl scale deployment frontend --replicas=5
```

**Verify scaling**:
```bash
kubectl get pods
```

**Example output**:
```
NAME                              READY   STATUS    RESTARTS   AGE
frontend-6b46678c94-lksnc         1/1     Running   0          72m
frontend-6b46678c94-mqqx2         1/1     Running   0          72m
frontend-6b46678c94-p4php         1/1     Running   0          6s
frontend-6b46678c94-p5nrg         1/1     Running   0          72m
frontend-6b46678c94-z9pqm         1/1     Running   0          6s
redis-follower-66847965fb-h8nlv   1/1     Running   0          77m
redis-follower-66847965fb-vbdd2   1/1     Running   0          77m
redis-leader-665d87459f-nlq45     1/1     Running   0          94m
```

**Scale back down**:
```bash
kubectl scale deployment frontend --replicas=3
```

---

## Troubleshooting

### Check Service Endpoints

If your service isn't working, verify the endpoints are properly configured:

```bash
kubectl get endpoints frontend-nodeport
```

**Expected output**:
```
NAME                ENDPOINTS                                      AGE
frontend-nodeport   10.244.0.61:80,10.244.0.62:80,10.244.0.63:80   37h
```

If you see **no endpoints**, check that:
1. Pod labels match service selector exactly
2. Pods are in `Running` state
3. Container ports match targetPort in service

### Test Service Access (Minikube)

For Minikube users, you can access the service directly:

```bash
minikube service frontend-nodeport
```

**Expected output**:
```
┌───────────┬───────────────────┬─────────────┬───────────────────────────┐
│ NAMESPACE │       NAME        │ TARGET PORT │            URL            │
├───────────┼───────────────────┼─────────────┼───────────────────────────┤
│ default   │ frontend-nodeport │ nodeport/80 │ http://192.168.49.2:30959 │
└───────────┴───────────────────┴─────────────┴───────────────────────────┘
🎉  Opening service default/frontend-nodeport in default browser...
```

### Common Issues

**Pods not starting**:
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

**Service not routing traffic**:
```bash
# Check service endpoints
kubectl get endpoints

# Verify service selector matches pod labels
kubectl get pods --show-labels
kubectl describe service frontend-nodeport
```

**Can't access application**:
```bash
# For NodePort services
kubectl get nodes -o wide  # Get node IP
kubectl get svc            # Get NodePort

# Access at: http://<node-ip>:<node-port>
```

---

## Cleanup

### Quick Cleanup Script

Use the included [delete-all.sh](delete-all.sh) script:

```bash
kubectl delete deployment -l app=redis
kubectl delete service -l app=redis
kubectl delete deployment frontend
kubectl delete service frontend
```

**Expected output**:
```
deployment.apps "redis-follower" deleted
deployment.apps "redis-leader" deleted
service "redis-follower" deleted
service "redis-leader" deleted
deployment.apps "frontend" deleted
service "frontend" deleted
```

### Quick Deploy Script

Use the included [create-all.sh](create-all.sh) script to deploy everything at once:

```bash
#!/bin/bash
# Deploy all resources in the correct order

# Backend: Redis Leader
kubectl apply -f redis-leader-service.yaml
kubectl apply -f redis-leader-deployment.yaml

# Backend: Redis Followers
kubectl apply -f redis-follower-deployment.yaml
kubectl apply -f redis-follower-service.yaml

# Frontend
kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml

# View status
echo "=== Checking Pods ==="
kubectl get pods

echo "=== Checking Services ==="
kubectl get services

echo "=== Checking Deployments ==="
kubectl get deployments
```

---

## Key Learnings

### Kubernetes Concepts Practiced

1. **Deployments**: Managed stateless applications with desired replica counts
2. **Services**: Provided stable networking and service discovery
3. **Labels & Selectors**: Connected services to pods using label matching
4. **Scaling**: Dynamically adjusted replicas without downtime
5. **Multi-tier Architecture**: Separated frontend and backend concerns

### Service Types Comparison

| Type | Use Case | External Access |
|------|----------|-----------------|
| **ClusterIP** | Internal services (Redis) | No |
| **NodePort** | Dev/testing (Frontend) | Yes (via node IP:port) |
| **LoadBalancer** | Production external access | Yes (via cloud LB) |

### Important Label Patterns

```yaml
# Frontend pods use:
app: guestbook
tier: frontend

# Backend pods use:
app: redis
role: leader/follower
tier: backend
```

**Critical**: Service `selector` must match pod `labels` exactly for traffic routing!

---

## Next Steps

- Try modifying the number of replicas
- Experiment with different service types
- Add resource limits and requests
- Implement health checks (liveness/readiness probes)
- Set up Ingress for better routing
- Practice with `kubectl` commands
- Learn about ConfigMaps and Secrets for configuration

---

## Questions & Notes

_Add your own notes, questions, or observations here as you learn!_

