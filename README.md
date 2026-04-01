# basic-app

A configurable basic microservice web application with a Go backend API and a React frontend, designed to be deployed on [HashiCorp Nomad](https://www.nomadproject.io/).

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Browser                             │
└─────────────────────────────┬───────────────────────────────┘
                              │ HTTP :80
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Frontend  (React + Nginx)                      │
│   Reads BACKEND_API_URL from /env-config.js at startup     │
└─────────────────────────────┬───────────────────────────────┘
                              │ HTTP :8080
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Backend API  (Go)                              │
│   GET /health        – liveness check                       │
│   GET /api/items     – list of sample items                 │
└─────────────────────────────────────────────────────────────┘
```

## Project Structure

```
basic-app/
├── backend/                  # Go REST API
│   ├── main.go
│   ├── go.mod
│   └── Dockerfile
├── frontend/                 # React SPA served by Nginx
│   ├── public/
│   │   ├── index.html
│   │   ├── env-config.js             # Dev-time fallback
│   │   └── env-config.js.template    # Substituted at container startup
│   ├── src/
│   │   ├── index.js
│   │   ├── App.js
│   │   └── App.css
│   ├── nginx.conf
│   ├── docker-entrypoint.sh
│   ├── Dockerfile
│   └── package.json
├── nomad/
│   └── basic-app.nomad.hcl   # Nomad job specification
└── README.md
```

## Environment Variables

### Backend (`backend/`)

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT`   | `8080`  | Port the API server listens on |

### Frontend (`frontend/`)

| Variable | Default | Description |
|----------|---------|-------------|
| `BACKEND_API_URL` | `http://localhost:8080` | URL of the backend API (**runtime**, injected into `env-config.js` at container startup by `docker-entrypoint.sh`) |
| `REACT_APP_BACKEND_API_URL` | `http://localhost:8080` | Optional **build-time** fallback via CRA |

The frontend uses a runtime injection pattern so that the same Docker image can be promoted across environments (dev → staging → production) without rebuilding.

## Quick Start (Docker Compose)

```bash
# Build images
docker build -t basic-app-backend:latest ./backend
docker build -t basic-app-frontend:latest ./frontend

# Run backend
docker run -d --name backend -p 8080:8080 basic-app-backend:latest

# Run frontend (point it at the backend)
docker run -d --name frontend \
  -e BACKEND_API_URL=http://localhost:8080 \
  -p 80:80 \
  basic-app-frontend:latest

# Open the app
open http://localhost
```

## Building the Images

### Backend

```bash
docker build -t basic-app-backend:latest ./backend
```

### Frontend

```bash
# Optional build-time default (overridden at runtime via BACKEND_API_URL)
docker build \
  --build-arg REACT_APP_BACKEND_API_URL=http://localhost:8080 \
  -t basic-app-frontend:latest \
  ./frontend
```

## Running Locally (without Docker)

### Backend

```bash
cd backend
PORT=8080 go run .
```

### Frontend

```bash
cd frontend
REACT_APP_BACKEND_API_URL=http://localhost:8080 npm start
```

## Deploying to Nomad

### Prerequisites

- A Nomad cluster with the Docker task driver enabled
- Images pushed to a registry accessible by Nomad client nodes

### Steps

```bash
# 1. Build and push images
docker build -t your-registry/basic-app-backend:latest ./backend
docker push your-registry/basic-app-backend:latest

docker build -t your-registry/basic-app-frontend:latest ./frontend
docker push your-registry/basic-app-frontend:latest

# 2. Submit the job (override variables as needed)
nomad job run \
  -var="backend_image=your-registry/basic-app-backend:latest" \
  -var="frontend_image=your-registry/basic-app-frontend:latest" \
  -var="datacenter=dc1" \
  nomad/basic-app.nomad.hcl

# 3. Check job status
nomad job status basic-app
```

### Nomad Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `backend_image` | `basic-app-backend:latest` | Backend Docker image |
| `frontend_image` | `basic-app-frontend:latest` | Frontend Docker image |
| `backend_api_url` | `http://localhost:8080` | URL browsers use to reach the backend API |
| `backend_port` | `8080` | Backend port |
| `frontend_port` | `80` | Frontend port |
| `datacenter` | `dc1` | Nomad datacenter |

## API Reference

### `GET /health`

Returns the health status of the backend.

```json
{
  "status": "ok",
  "timestamp": "2024-01-15T10:30:00Z",
  "version": "1.0.0"
}
```

### `GET /api/items`

Returns a list of sample items.

```json
[
  { "id": 1, "name": "Widget A", "description": "A high-quality widget for all your needs" },
  ...
]
```
