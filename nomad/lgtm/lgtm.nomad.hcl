job "lgtm" {
  datacenters = ["dc1"]
  type        = "service"

  group "mimir" {
    count = 3 # mimir requires 3 instances
    network {
      port "http" {
        to = 8080
      }
      port "memberlist" {
        to = 7946
      }
    }

    task "mimir" {
      driver = "docker"
      config {
        image   = "grafana/mimir:2.15.0"
        args = ["-config.file=/local/mimir.yaml"]
        # hostname ?

        hostname = "mimir-${NOMAD_ALLOC_INDEX}"
        ports = ["http", "memberlist"]
      }

      resources {
        memory = 1024
      }
      template {
        destination = "local/mimir.yaml"
        data        = file("mimir.yaml")
      }
      template {
        destination = "local/alertmanager-fallback-config.yaml"
        data        = file("alertmanager-fallback-config.yaml")
      }
    }

    service {
      name = "mimir"
      port = "http"
      provider = "nomad"
      check {
        type     = "http"
        path     = "/ready"
        interval = "10s"
        timeout  = "2s"
      }
    }
    service {
      name = "mimir-memberlist"
      port = "memberlist"
      provider = "nomad"
    }

  }

  group "loki" {

    count = 1

    network {
      port "http" {
        to = 3100
      }
    }

    task "loki" {
      driver = "docker"

      config {
        image = "grafana/loki:3.3.2"
        ports = ["http"]

        args = [
          "-config.file=local/loki.yaml"
        ]
      }

      resources {
        memory = 1024
      }
      template {

        destination = "local/loki.yaml"
        data        = file("loki.yaml")
      }
    }
    service {

      name     = "loki"
      port     = "http"
      provider = "nomad"
      check {
        type     = "http"
        path     = "/ready"
        interval = "10s"
        timeout  = "2s"
      }
    }
  }

  group "tempo" {

    count = 1

    network {
      port "http" {
        to = 3100
      }
      port "grpc" {

      }
      port "otlp_http" {
        to = 4318
      }
    }

    task "tempo" {
      driver = "docker"

      config {
        image = "grafana/tempo:latest"
        ports = ["http", "grpc", "otlp_http"]
        args = [
          "-target=all",
          "-config.file=/local/tempo.yaml",
          "-config.expand-env=true",
        ]
      }

      resources {
        memory = 1024
      }
      template {
        destination = "local/tempo.yaml"
        data        = file("tempo.yaml")
      }
    }

    service {
      name     = "tempo"
      port     = "http"
      provider = "nomad"
      check {
        type     = "http"
        path     = "/ready"
        interval = "10s"
        timeout  = "1s"
      }
    }
    service {
      name     = "tempo-otlp"
      port     = "otlp_http"
      provider = "nomad"
    }
  }
  group "grafana" {

    count = 1

    network {
      port "http" {
        static = 3000
      }
    }

    task "grafana" {
      driver = "docker"

      config {
        image = "grafana/grafana:latest"
        ports = ["http"]
      }

      env {
        GF_PATHS_PROVISIONING      = "/local/provisioning"
        GF_AUTH_ANONYMOUS_ENABLED  = "true"
        GF_AUTH_ANONYMOUS_ORG_ROLE = "Admin"
      }
      resources {
        memory = 512
      }

      template {
        destination = "local/provisioning/datasources/datasources.yaml"
        data        = file("datasources.yaml")

      }
    }
  }

  group "minio" {

    count = 1

    network {
      port "api" {
        to = 9000
      }
      port "console" {
        static = 9001
      }
    }

    task "minio" {
      driver = "docker"

      config {
        image = "bitnami/minio:latest"
        ports = ["api", "console"]

      }
      env {
        MINIO_DATA_DIR        = "/alloc/data"
        MINIO_DEFAULT_BUCKETS = "mimir,loki,tempo"
        MINIO_SERVER_URL      = "http://${NOMAD_ADDR_api}"
      }

      resources {
        memory = 512
      }
    }
    service {
      name = "minio-api"
      port = "api"
      check {
        type     = "http"
        path     = "/minio/health/live"
        interval = "10s"
        timeout  = "2s"
      }
      provider = "nomad"
    }
  }
}
