job "nacp" {
  datacenters = ["dc1"]
  type        = "service"

  group "nacp" {
    network {
      port "http" {
        static = 6464
      }
    }

    task "nacp" {
      driver = "docker"
      config {
        image = "ghcr.io/mxab/nacp:v0.7.0"
        ports = ["http"]
        args  = ["-config", "/local/nacp.conf.hcl"]
      }
      template {
        data        = file("nacp.conf.hcl")
        destination = "local/nacp.conf.hcl"
      }
      template {
        data        = file("rule/otel.rego")
        destination = "local/otel.rego"
        left_delimiter = "[[["
        right_delimiter = "]]]"
      }
    }

    service {
      name = "nacp"
      port = "http"
      provider = "nomad"
      check {
        type     = "tcp"
        
        interval = "10s"
        timeout  = "2s"
      }
    }

  }
}