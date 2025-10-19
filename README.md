# Kubernetes Guestbook Lab

**Goal**: Learn Kubernetes deployments, services, and scaling by building a multi-tier web application with Redis backend and PHP frontend.

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
│  │  (ClusterIP)    │                                       │
│  └─────────────────┘                                       │
│           │                                                 │
└───────────┼─────────────────────────────────────────────────┘
            │
            ▼
    ┌─────────────────┐
    │ External Access │
    │ Port Forward /  │
    │ LoadBalancer    │
    └─────────────────┘
```

**Components:**
- **Frontend**: 3 PHP pods serving web UI
- **Redis Leader**: 1 pod handling writes  
- **Redis Followers**: 2 pods handling reads
- **Services**: Internal cluster communication
- **Access**: Port-forward or LoadBalancer

## Quick Setup

### 1. Deploy Redis Leader
```bash
kubectl apply -f redis-leader-deployment.yaml
```
```
deployment.apps/redis-leader created
```

```bash
kubectl apply -f redis-leader-service.yaml
```
```
service/redis-leader created
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
kubectl apply -f redis-follower-service.yaml
```
```
service/redis-follower created
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
kubectl apply -f frontend-service.yaml
```
```
service/frontend created
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

#### Method 1: Port Forwarding (Temporary)
```bash
kubectl port-forward svc/frontend 8081:80
```
```
Forwarding from 127.0.0.1:8081 -> 80
Forwarding from [::1]:8081 -> 80
```
Open: http://localhost:8081/

#### Method 2: LoadBalancer (Production)
Edit frontend-service.yaml to uncomment LoadBalancer type:
```bash
# Uncomment type: LoadBalancer in frontend-service.yaml
kubectl apply -f frontend-service.yaml
```
```
service/frontend configured
```

```bash
kubectl get service frontend
```
```
NAME       TYPE           CLUSTER-IP      EXTERNAL-IP        PORT(S)        AGE
frontend   LoadBalancer   10.51.242.136   109.197.92.229     80:32372/TCP   1m
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

### 6. Clean Up
```bash
kubectl delete deployment -l app=redis
kubectl delete service -l app=redis  
kubectl delete deployment frontend
kubectl delete service frontend
```
```
deployment.apps "redis-follower" deleted
deployment.apps "redis-leader" deleted
service "redis-follower" deleted
service "redis-leader" deleted
deployment.apps "frontend" deleted
service "frontend" deleted
```

## Verify Commands
```bash
kubectl get pods                    # Check all pods
kubectl get services               # Check all services
kubectl get deployments          # Check deployments
```
```
NAME             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
frontend         ClusterIP   10.103.66.175   <none>        80/TCP     2s
kubernetes       ClusterIP   10.96.0.1       <none>        443/TCP    113m
redis-follower   ClusterIP   10.102.77.64    <none>        6379/TCP   68m
redis-leader     ClusterIP   10.109.136.67   <none>        6379/TCP   76m
```