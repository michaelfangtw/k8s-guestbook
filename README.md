# Kubernetes Guestbook Application

This tutorial shows you how to build and deploy a simple (not production ready), multi-tier web application using Kubernetes and Docker.

## Prerequisites

If you do not already have a cluster, you can create one by using minikube or you can use one of these Kubernetes playgrounds:

- [iximiuz Labs](https://labs.iximiuz.com/)
- [Killercoda](https://killercoda.com/)
- [KodeKloud](https://kodekloud.com/)
- [Play with Kubernetes](https://labs.play-with-k8s.com/)

**Note:** Your Kubernetes server must be at or later than version v1.14. To check the version, enter `kubectl version`.

## Architecture Overview

The guestbook application uses Redis to store its data and consists of:
- Redis Leader (for writes)
- Redis Followers (for reads)
- Frontend web application

## Start up the Redis Database

### Creating the Redis Leader Deployment

Create the Redis leader deployment manifest:
Start up the Redis Database
The guestbook application uses Redis to store its data.



## Start up the Redis Database 
The guestbook application uses Redis to store its data.

### Creating the Redis Deployment
- vi redis-leader-deployment.yaml


```
# SOURCE: https://cloud.google.com/kubernetes-engine/docs/tutorials/guestbook
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

Apply the deployment:

```bash
kubectl apply -f redis-leader-deployment.yaml
```

Verify the pod is running:

```bash
kubectl get pods
```

Expected output:
```
NAME                            READY   STATUS    RESTARTS   AGE
redis-leader-665d87459f-nlq45   1/1     Running   0          4m
```

### Creating the Redis Leader Service

Create the Redis leader service manifest:

```bash
vi redis-leader-service.yaml
```

```yaml
# SOURCE: https://cloud.google.com/kubernetes-engine/docs/tutorials/guestbook
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

Apply the service:

```bash
kubectl apply -f redis-leader-service.yaml
```

Verify the service is created:

```bash
kubectl get service
```

Expected output:
```
NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
kubernetes     ClusterIP   10.96.0.1       <none>        443/TCP    33m
redis-leader   ClusterIP   10.109.136.67   <none>        6379/TCP   8m13s
```

## Set up Redis Followers

### Creating the Redis Follower Deployment

Create the Redis follower deployment manifest:

```bash
vi redis-follower-deployment.yaml
```

```yaml
# SOURCE: https://cloud.google.com/kubernetes-engine/docs/tutorials/guestbook
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

Apply the deployment:

```bash
kubectl apply -f redis-follower-deployment.yaml
```

Verify the pods are running:

```bash
kubectl get pods
```

Expected output:
```
NAME                              READY   STATUS    RESTARTS   AGE
redis-follower-66847965fb-h8nlv   1/1     Running   0          3s
redis-follower-66847965fb-vbdd2   1/1     Running   0          3s
redis-leader-665d87459f-nlq45     1/1     Running   0          17m
```

### Creating the Redis Follower Service

Create the Redis follower service manifest:

```bash
vi redis-follower-service.yaml
```

```yaml
# SOURCE: https://cloud.google.com/kubernetes-engine/docs/tutorials/guestbook
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
    # the port that this service should serve on
  - port: 6379
  selector:
    app: redis
    role: follower
    tier: backend
```

Apply the service:

```bash
kubectl apply -f redis-follower-service.yaml
```

Verify the service is created:

```bash
kubectl get service
```

Expected output:
```
NAME             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
kubernetes       ClusterIP   10.96.0.1       <none>        443/TCP    44m
redis-follower   ClusterIP   10.102.77.64    <none>        6379/TCP   6s
redis-leader     ClusterIP   10.109.136.67   <none>        6379/TCP   8m13s
```

## Set up and Expose the Guestbook Frontend

### Creating the Frontend Deployment

Create the frontend deployment manifest:

```bash
vi frontend-deployment.yaml
```

```yaml
# SOURCE: https://cloud.google.com/kubernetes-engine/docs/tutorials/guestbook
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

Apply the deployment:

```bash
kubectl apply -f frontend-deployment.yaml
```

Verify the pods are running:

```bash
kubectl get pods -l app=guestbook -l tier=frontend
```

Expected output:
```
NAME                        READY   STATUS    RESTARTS   AGE
frontend-6b46678c94-lksnc   1/1     Running   0          64m
frontend-6b46678c94-mqqx2   1/1     Running   0          64m
frontend-6b46678c94-p5nrg   1/1     Running   0          64m
```

### Creating the Frontend Service

Create the frontend service manifest:

```bash
vi frontend-service.yaml
```

```yaml
# SOURCE: https://cloud.google.com/kubernetes-engine/docs/tutorials/guestbook
apiVersion: v1
kind: Service
metadata:
  name: frontend
  labels:
    app: guestbook
    tier: frontend
spec:
  # if your cluster supports it, uncomment the following to automatically create
  # an external load-balanced IP for the frontend service.
  # type: LoadBalancer
  #type: LoadBalancer
  ports:
    # the port that this service should serve on
  - port: 80
  selector:
    app: guestbook
    tier: frontend
```

Apply the service:

```bash
kubectl apply -f frontend-service.yaml
```

Verify the service is created:

```bash
kubectl get services
```

Expected output:
```
NAME             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
frontend         ClusterIP   10.103.66.175   <none>        80/TCP     2s
kubernetes       ClusterIP   10.96.0.1       <none>        443/TCP    113m
redis-follower   ClusterIP   10.102.77.64    <none>        6379/TCP   68m
redis-leader     ClusterIP   10.109.136.67   <none>        6379/TCP   76m
```

## Accessing the Application

### Method 1: Port Forwarding (Temporary)

Use kubectl port-forward for temporary access:

```bash
kubectl port-forward svc/frontend 8081:80
```

Output:
```
Forwarding from 127.0.0.1:8081 -> 80
Forwarding from [::1]:8081 -> 80
```

Open your browser and navigate to: http://localhost:8081/

### Method 2: LoadBalancer (Production)

If you deployed the frontend-service.yaml manifest with `type: LoadBalancer`, find the external IP address:

```bash
kubectl get service frontend
```

Expected output:
```
NAME       TYPE           CLUSTER-IP      EXTERNAL-IP        PORT(S)        AGE
frontend   LoadBalancer   10.51.242.136   109.197.92.229     80:32372/TCP   1m
```

## Scaling the Application

### Scale the Web Frontend

Scale up the frontend to 5 replicas:

```bash
kubectl scale deployment frontend --replicas=5
```

Verify the scaling:

```bash
kubectl get pods
```

Expected output:
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

Scale down the frontend to 2 replicas:

```bash
kubectl scale deployment frontend --replicas=2
```

Verify the scaling:

```bash
kubectl get pods
```

Expected output:
```
NAME                              READY   STATUS    RESTARTS   AGE
frontend-6b46678c94-mqqx2         1/1     Running   0          74m
frontend-6b46678c94-p5nrg         1/1     Running   0          74m
redis-follower-66847965fb-h8nlv   1/1     Running   0          79m
redis-follower-66847965fb-vbdd2   1/1     Running   0          79m
redis-leader-665d87459f-nlq45     1/1     Running   0          96m
```

## Cleaning Up

To remove all resources created in this tutorial:

```bash
kubectl delete deployment -l app=redis
kubectl delete service -l app=redis
kubectl delete deployment frontend
kubectl delete service frontend
```

Expected output:
```
deployment.apps "redis-follower" deleted
deployment.apps "redis-leader" deleted
service "redis-follower" deleted
service "redis-leader" deleted
deployment.apps "frontend" deleted
service "frontend" deleted
```