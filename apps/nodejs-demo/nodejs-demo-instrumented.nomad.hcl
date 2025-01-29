job "nodejs-demo" {
  datacenters = ["dc1"]
  type        = "service"
  group "nodejs-demo" {

    network {
      port "http" {
        static = 3333
        to     = 3000

      }
    }
    task "inject-otel" {
      lifecycle {
        sidecar = false
        hook    = "prestart"
      }
      driver = "docker"
      config {
        image = "node:22.13.1-alpine"
        args = [
          "sh",
          "/local/inject-otel.sh"
        ]

      }

      template {
        data        = <<EOF
#!/bin/sh

mkdir -p /alloc/otel/node_modules

npm install --prefix /alloc/otel @opentelemetry/api
npm install --prefix /alloc/otel @opentelemetry/auto-instrumentations-node
EOF
        destination = "local/inject-otel.sh"
        perms       = "0755"
      }

    }
    task "nodejs-demo" {
      driver = "docker"
      config {
        image = "nodejs-demo:1"
        ports = ["http"]
        volumes = [
          "../alloc/otel/node_modules:/node_modules"
        ]
      }
      template {
        env         = true
        data        = <<EOF
OTEL_TRACES_EXPORTER=otlp
OTEL_EXPORTER_OTLP_PROTOCOL="http/protobuf"
OTEL_EXPORTER_OTLP_ENDPOINT=http://{{ env "attr.unique.network.ip-address" }}:4318
OTEL_NODE_RESOURCE_DETECTORS=env,host,os
OTEL_SERVICE_NAME={{ env "NOMAD_TASK_NAME"}}
NODE_OPTIONS=--require @opentelemetry/auto-instrumentations-node/register
EOF
        destination = "local/otel.env"
      }

    }
    service {
      provider = "nomad"
      name     = "nodejs-demo"
      port     = "http"
      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }
  }
}