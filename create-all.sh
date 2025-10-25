#create all
kubectl apply -f redis-leader-service.yaml
kubectl apply -f redis-leader-deployment.yaml
kubectl apply -f redis-follower-deployment.yaml
kubectl apply -f redis-follower-service.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml

#view status
kubectl get pods                    # Check all pods
kubectl get services               # Check all services
kubectl get deployments          # Check deployments



