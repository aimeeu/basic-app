# basic-app.nomad.hcl
#
# HashiCorp Nomad job specification for the basic-app microservice.
# It defines two task groups:
#   - backend  : Go REST API
#   - frontend : React app served by Nginx
#
# Prerequisites:
#   - A Docker-enabled Nomad cluster
#   - The images must be built and pushed to a registry (or be available locally)
#
# Usage:
#   nomad job run nomad/basic-app.nomad.hcl
#
# Variables (override with -var or var-file):
variable "backend_image" {
  description = "Docker image for the backend API"
  type        = string
  default     = "basic-app-backend:latest"
}

variable "frontend_image" {
  description = "Docker image for the frontend app"
  type        = string
  default     = "basic-app-frontend:latest"
}

variable "backend_port" {
  description = "Port the backend API listens on"
  type        = number
  default     = 8080
}

variable "frontend_port" {
  description = "Port the frontend Nginx server listens on"
  type        = number
  default     = 80
}

variable "datacenter" {
  description = "Nomad datacenter to schedule the job in"
  type        = string
  default     = "dc1"
}

variable "backend_api_url" {
  description = <<-EOT
    URL the browser uses to reach the backend API.
    Override this with the actual host/IP where the backend is scheduled,
    e.g. http://10.0.1.5:8080 or your load-balancer address.
    With Consul service discovery you can replace this with the service
    DNS name, e.g. http://basic-app-backend.service.consul:8080.
  EOT
  type    = string
  default = "http://localhost:8080"
}

# ── Job definition ─────────────────────────────────────────────────────────────
job "basic-app" {
  datacenters = [var.datacenter]
  type        = "service"

  # ── Backend task group ───────────────────────────────────────────────────────
  group "backend" {
    count = 1

    network {
      port "http" {
        static = var.backend_port
        to     = var.backend_port
      }
    }

    service {
      name     = "basic-app-backend"
      port     = "http"
      provider = "nomad"

      check {
        type     = "http"
        path     = "/health"
        interval = "10s"
        timeout  = "3s"
      }
    }

    task "backend" {
      driver = "docker"

      config {
        image = var.backend_image
        ports = ["http"]
      }

      env {
        PORT = var.backend_port
      }

      resources {
        cpu    = 100
        memory = 64
      }

      restart {
        attempts = 3
        delay    = "15s"
        interval = "1m"
        mode     = "fail"
      }
    }
  }

  # ── Frontend task group ──────────────────────────────────────────────────────
  group "frontend" {
    count = 1

    network {
      port "http" {
        static = var.frontend_port
        to     = var.frontend_port
      }
    }

    service {
      name     = "basic-app-frontend"
      port     = "http"
      provider = "nomad"

      check {
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "3s"
      }
    }

    task "frontend" {
      driver = "docker"

      config {
        image = var.frontend_image
        ports = ["http"]
      }

      # BACKEND_API_URL is injected at container startup by docker-entrypoint.sh
      # and written to /usr/share/nginx/html/env-config.js which the browser loads.
      #
      # Set the backend_api_url job variable (or -var flag) to the address at
      # which the backend is reachable from end-user browsers, e.g.:
      #   nomad job run -var="backend_api_url=http://10.0.1.5:8080" nomad/basic-app.nomad.hcl
      env {
        BACKEND_API_URL = var.backend_api_url
      }

      resources {
        cpu    = 100
        memory = 64
      }

      restart {
        attempts = 3
        delay    = "15s"
        interval = "1m"
        mode     = "fail"
      }
    }
  }
}
