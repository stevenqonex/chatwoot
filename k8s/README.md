# Chatwoot Kubernetes Deployment Guide

This guide explains how to deploy Chatwoot to Kubernetes using the existing Dockerfile with 3 separate deployments:
1. **Web Deployment** - Rails server (API + Frontend)
2. **Worker Deployment** - Sidekiq background jobs
3. **Database & Cache** - PostgreSQL and Redis

## Prerequisites

- Kubernetes cluster (1.20+)
- kubectl configured
- Docker registry access
- Helm (optional, for easier deployment)

## Step 1: Build and Push Docker Image

```bash
# Build the production image
docker build -t your-registry/chatwoot:latest -f docker/Dockerfile .

# Push to your registry
docker push your-registry/chatwoot:latest
```

## Step 2: Generate Secrets

```bash
# Generate SECRET_KEY_BASE
SECRET_KEY_BASE=$(bundle exec rails secret)
echo "SECRET_KEY_BASE: $(echo -n $SECRET_KEY_BASE | base64)"

# Generate database password
DB_PASSWORD=$(openssl rand -base64 32)
echo "POSTGRES_PASSWORD: $(echo -n $DB_PASSWORD | base64)"

# Generate Redis password
REDIS_PASSWORD=$(openssl rand -base64 32)
echo "REDIS_PASSWORD: $(echo -n $REDIS_PASSWORD | base64)"
```

## Step 3: Deploy Infrastructure

```bash
# Create namespace
kubectl apply -f namespace.yaml

# Deploy storage PVC
kubectl apply -f storage-pvc.yaml

# Deploy PostgreSQL
kubectl apply -f postgres.yaml

# Deploy Redis
kubectl apply -f redis.yaml

# Wait for databases to be ready
kubectl wait --for=condition=ready pod -l app=chatwoot-postgres -n chatwoot --timeout=300s
kubectl wait --for=condition=ready pod -l app=chatwoot-redis -n chatwoot --timeout=300s
```

## Step 4: Deploy Application

```bash
# Deploy secrets and config
kubectl apply -f secret.yaml
kubectl apply -f configmap.yaml

# Deploy worker first (background jobs)
kubectl apply -f worker-deployment.yaml

# Deploy web application
kubectl apply -f web-deployment.yaml

# Deploy ingress
kubectl apply -f ingress.yaml

# Optional: Deploy separate WebSocket ingress for better performance
# kubectl apply -f ingress-websocket.yaml
```

## Step 5: Initialize Database

```bash
# Run database setup
kubectl apply -f db-init-job.yaml

# Check job status
kubectl get jobs -n chatwoot
kubectl logs job/chatwoot-db-init -n chatwoot
```

## Step 6: Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n chatwoot

# Check services
kubectl get svc -n chatwoot

# Test the application
kubectl port-forward svc/chatwoot-web 3000:3000 -n chatwoot
```

## Devtron Deployment Guide

### Prerequisites for Devtron

- Devtron installed and configured
- Container registry configured in Devtron
- Kubernetes cluster connected to Devtron

### Step 1: Create Applications in Devtron

You'll need to create **two separate applications** in Devtron:

1. **Chatwoot Web** - Rails server (API + Frontend)
2. **Chatwoot Worker** - Sidekiq background jobs

### Step 2: Configure Web Application

#### Basic Configuration
- **App Name**: `chatwoot-web`
- **Project**: Select your project
- **Environment**: Select your environment (dev/staging/prod)

#### Git Repository
- **Git Provider**: Select your Git provider
- **Repository URL**: Your Chatwoot repository URL
- **Branch**: `main` or your target branch

#### Build Configuration
- **Dockerfile Path**: `docker/Dockerfile`
- **Docker Context**: `.` (root directory)
- **Target Platform**: `linux/amd64` (or your target platform)

#### Deployment Template Configuration

**Container Configuration:**
```yaml
# Image
image: your-registry/chatwoot:latest
imagePullPolicy: IfNotPresent

# Container Port
ContainerPort:
  - envoyPort: 8799
    idleTimeout: 1800s
    name: app
    port: 3000  # Rails port
    servicePort: 443
    supportStreaming: false
    useHTTP2: false

# Command and Arguments
command:
  enabled: true
  value:
    - "docker/entrypoints/rails.sh"

args:
  enabled: true
  value:
    - "bundle"
    - "exec"
    - "rails"
    - "s"
    - "-p"
    - "3000"
    - "-b"
    - "0.0.0.0"
```

**Resource Configuration:**
```yaml
resources:
  limits:
    cpu: "1"
    memory: 2Gi
  requests:
    cpu: "500m"
    memory: 1Gi
```

**Health Checks:**
```yaml
LivenessProbe:
  Path: "/health"
  port: 3000
  failureThreshold: 3
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5

ReadinessProbe:
  Path: "/health"
  port: 3000
  failureThreshold: 3
  initialDelaySeconds: 20
  periodSeconds: 10
  timeoutSeconds: 5
```

**Environment Variables:**
```yaml
EnvVariables:
  - name: RAILS_ENV
    value: "production"
  - name: NODE_ENV
    value: "production"
  - name: POSTGRES_HOST
    value: "chatwoot-postgres"
  - name: POSTGRES_PORT
    value: "5432"
  - name: POSTGRES_DATABASE
    value: "chatwoot_production"
  - name: POSTGRES_USERNAME
    value: "chatwoot_prod"
  - name: REDIS_URL
    value: "redis://chatwoot-redis:6379"
  - name: FRONTEND_URL
    value: "https://chatwoot.yourdomain.com"
```

**Scaling Configuration:**
```yaml
replicaCount: 2

autoscaling:
  enabled: true
  MinReplicas: 2
  MaxReplicas: 10
  TargetCPUUtilizationPercentage: 70
  TargetMemoryUtilizationPercentage: 80
```

### Step 3: Configure Worker Application

#### Basic Configuration
- **App Name**: `chatwoot-worker`
- **Project**: Same project as web app
- **Environment**: Same environment as web app

#### Git Repository
- **Same repository** as web application
- **Same branch** as web application

#### Build Configuration
- **Same Dockerfile** as web application
- **Same build context** as web application

#### Deployment Template Configuration

**Container Configuration:**
```yaml
# Image (same as web)
image: your-registry/chatwoot:latest
imagePullPolicy: IfNotPresent

# No ContainerPort needed for worker
ContainerPort: []

# Command and Arguments (different from web)
command:
  enabled: true
  value:
    - "docker/entrypoints/rails.sh"

args:
  enabled: true
  value:
    - "bundle"
    - "exec"
    - "sidekiq"
    - "-C"
    - "config/sidekiq.yml"
```

**Resource Configuration:**
```yaml
resources:
  limits:
    cpu: "500m"
    memory: 1Gi
  requests:
    cpu: "250m"
    memory: 512Mi
```

**Health Checks (Command-based):**
```yaml
LivenessProbe:
  command:
    - "pgrep"
    - "-f"
    - "sidekiq"
  port: 0
  failureThreshold: 3
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5

ReadinessProbe:
  command:
    - "pgrep"
    - "-f"
    - "sidekiq"
  port: 0
  failureThreshold: 3
  initialDelaySeconds: 20
  periodSeconds: 10
  timeoutSeconds: 5
```

**Environment Variables (same as web):**
```yaml
EnvVariables:
  - name: RAILS_ENV
    value: "production"
  - name: NODE_ENV
    value: "production"
  - name: POSTGRES_HOST
    value: "chatwoot-postgres"
  - name: POSTGRES_PORT
    value: "5432"
  - name: POSTGRES_DATABASE
    value: "chatwoot_production"
  - name: POSTGRES_USERNAME
    value: "chatwoot_prod"
  - name: REDIS_URL
    value: "redis://chatwoot-redis:6379"
```

**Scaling Configuration:**
```yaml
replicaCount: 1

autoscaling:
  enabled: true
  MinReplicas: 1
  MaxReplicas: 5
  TargetCPUUtilizationPercentage: 70
  TargetMemoryUtilizationPercentage: 80
```

### Step 4: Configure Secrets in Devtron

#### Create Secrets
1. Go to **Global Configurations** → **Secrets**
2. Create a new secret with the following data:

```yaml
# Base64 encoded values
SECRET_KEY_BASE: <base64-encoded-secret-key>
POSTGRES_PASSWORD: <base64-encoded-db-password>
REDIS_PASSWORD: <base64-encoded-redis-password>
SMTP_USERNAME: <base64-encoded-smtp-username>
SMTP_PASSWORD: <base64-encoded-smtp-password>
```

#### Link Secrets to Applications
1. Go to each application's **ConfigMaps & Secrets**
2. Add the secret with appropriate key mappings

### Step 5: Configure Ingress

#### Web Application Ingress (Minimal)
```yaml
ingress:
  enabled: true
  annotations:
    # Essential: Force HTTPS
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    
    # Essential: File upload support (Chatwoot handles attachments)
    nginx.ingress.kubernetes.io/proxy-body-size: "100m"
    
    # Essential: WebSocket support for ActionCable (real-time messaging)
    nginx.ingress.kubernetes.io/proxy-http-version: "1.1"
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header Connection $http_connection;
      proxy_set_header Upgrade $http_upgrade;
  hosts:
    - host: chatwoot.yourdomain.com
      pathType: Prefix
      paths:
        - /
  tls:
    - secretName: chatwoot-tls
```

#### Worker Application
- **No Ingress needed** (worker doesn't serve HTTP)

#### Optional Ingress Enhancements

The minimal configuration above includes only what's essential. You can add these if needed:

```yaml
# Optional: Extended timeouts for long requests
nginx.ingress.kubernetes.io/proxy-read-timeout: "300"
nginx.ingress.kubernetes.io/proxy-send-timeout: "300"

# Optional: Rate limiting
nginx.ingress.kubernetes.io/rate-limit: "300"
nginx.ingress.kubernetes.io/rate-limit-window: "1m"

# Optional: Security headers (if not handled by application)
nginx.ingress.kubernetes.io/configuration-snippet: |
  add_header X-Frame-Options "SAMEORIGIN" always;
  add_header X-Content-Type-Options "nosniff" always;

# Optional: CORS (if not handled by Rails application)
nginx.ingress.kubernetes.io/enable-cors: "true"
```

### Step 6: Deploy Infrastructure First

Before deploying applications, ensure PostgreSQL and Redis are running:

```bash
# Deploy using kubectl or Devtron Charts
kubectl apply -f postgres.yaml
kubectl apply -f redis.yaml
```

### Step 7: Deploy Applications

1. **Deploy Worker First** (background jobs)
2. **Deploy Web Application** (main application)
3. **Verify Deployments** in Devtron UI

### Step 8: Database Initialization

Create a one-time job for database setup:

```yaml
# In Devtron, create a Job application
job:
  enabled: true
  command:
    - "docker/entrypoints/rails.sh"
  args:
    - "bundle"
    - "exec"
    - "rails"
    - "db:create"
    - "db:migrate"
    - "db:seed"
```

### Devtron-Specific Tips

1. **Use Environment Overrides** for different environments
2. **Configure Notifications** for deployment status
3. **Set up Monitoring** with Prometheus/Grafana
4. **Use Resource Browser** to debug deployments
5. **Configure Approval Policies** for production deployments

### Troubleshooting in Devtron

1. **Check Application Metrics** in Devtron UI
2. **View Pod Logs** using Resource Browser
3. **Use Ephemeral Containers** for debugging
4. **Check Deployment History** for rollback options

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Ingress       │    │   Web Pods      │    │  Worker Pods    │
│   (Nginx)       │───▶│   (Rails)       │    │   (Sidekiq)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │                        │
                              ▼                        ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   PostgreSQL    │    │     Redis       │
                       │   (StatefulSet) │    │   (StatefulSet) │
                       └─────────────────┘    └─────────────────┘
```

## Scaling

### Manual Scaling

```bash
# Scale web pods
kubectl scale deployment chatwoot-web --replicas=3 -n chatwoot

# Scale worker pods
kubectl scale deployment chatwoot-worker --replicas=2 -n chatwoot
```

### Automatic Scaling (HPA)

The deployment includes a HorizontalPodAutoscaler that automatically scales based on:
- **CPU utilization** > 70%
- **Memory utilization** > 80%

```bash
# Check HPA status
kubectl get hpa -n chatwoot

# View HPA metrics
kubectl describe hpa chatwoot-web-hpa -n chatwoot
```

### Scaling Considerations

✅ **Web Deployment Scaling**:
- **Stateless**: Each instance is independent
- **Load Balanced**: Ingress distributes traffic
- **Shared Storage**: File uploads use PVC
- **Session Management**: Redis handles sessions
- **WebSocket Support**: ActionCable works across instances

✅ **Worker Deployment Scaling**:
- **Queue-based**: Sidekiq handles job distribution
- **Independent**: Each worker processes jobs independently
- **Auto-balancing**: Jobs are distributed automatically

⚠️ **Database Scaling**:
- **Single Instance**: PostgreSQL runs as StatefulSet
- **Connection Limits**: Monitor database connections
- **Consider Read Replicas**: For high read workloads

## Monitoring

```bash
# View logs
kubectl logs -f deployment/chatwoot-web -n chatwoot
kubectl logs -f deployment/chatwoot-worker -n chatwoot

# Check resource usage
kubectl top pods -n chatwoot
```

## Ingress Configuration

### Key Features

✅ **WebSocket Support**: Properly configured for ActionCable real-time messaging
✅ **File Uploads**: 100MB limit for file attachments
✅ **Security Headers**: XSS protection, content type validation
✅ **Rate Limiting**: Configurable rate limits for API protection
✅ **SSL/TLS**: Automatic HTTPS redirect and secure connections
✅ **Performance**: Optimized buffer settings and timeouts

### WebSocket Configuration

Chatwoot uses ActionCable for real-time features:
- **Connection Path**: `/cable`
- **Redis Backend**: Shared across all instances
- **Authentication**: Token-based via `pubsub_token`
- **Events**: Messages, typing indicators, presence updates

### Optional Optimizations

```bash
# Deploy separate WebSocket ingress for high-traffic scenarios
kubectl apply -f ingress-websocket.yaml
```

## Troubleshooting

### Common Issues

1. **Database connection issues**: Check PostgreSQL pod status and credentials
2. **Redis connection issues**: Verify Redis pod is running and password is correct
3. **Asset compilation errors**: Ensure NODE_ENV and RAILS_ENV are set correctly
4. **Memory issues**: Adjust resource limits in deployment files
5. **WebSocket connection issues**: Check ingress annotations and Redis connectivity
6. **File upload failures**: Verify ingress body size limits

### Debug Commands

```bash
# Check pod events
kubectl describe pod <pod-name> -n chatwoot

# Execute into pod
kubectl exec -it <pod-name> -n chatwoot -- /bin/sh

# Check environment variables
kubectl exec <pod-name> -n chatwoot -- env | grep RAILS
``` 