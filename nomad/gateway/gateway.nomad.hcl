job "otel-gateway" {
    type = "service"
    datacenters = ["*"]

    group "gateway" {
        count = 3

        network {
            port "http" {
                to = 12345
            }
            port "otlp_grpc" {
                to = 4317
            }
            port "otlp_http" {
                to = 4318
            }
        }

        task "alloy" {
            driver = "docker"

            config {
                image = "grafana/alloy:latest"
                
                args = [
                    "run",
                    "--server.http.listen-addr=0.0.0.0:12345",
                    "--storage.path=${NOMAD_ALLOC_DIR}/data",
                    "${NOMAD_TASK_DIR}/gateway.alloy" 
                ]   
                ports = ["http", "otlp_grpc", "otlp_http"]

            }

            template {
                data = file("gateway.alloy")
                destination = "local/gateway.alloy"
            }
            template {
                data = file("backends.yaml")
                destination = "local/backends.yaml"   
            }
        }

        service {
            provider = "nomad"
            name = "otel-gateway-alloy"
            port = "http"
            
        }
        service {
            provider = "nomad"
            name = "otel-gateway-otlp-http"
            port = "http"
            check {
                type = "http"
                path = "/-/ready"
                interval = "10s"
                timeout = "2s"
                port = "http"
            }
        }
    }
}