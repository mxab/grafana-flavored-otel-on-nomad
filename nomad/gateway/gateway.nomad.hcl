job "otel-gateway" {
    type = "service"
    datacenters = ["*"]

    group "gateway" {
        count = 3

        network {
            port "ui" {
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
                image = "grafana/alloy:v1.6.1"
                
                args = [
                    "run",
                    "--server.http.listen-addr=0.0.0.0:12345",
                    "--storage.path=${NOMAD_ALLOC_DIR}/data",
                    "${NOMAD_TASK_DIR}/gateway.alloy" 
                ]   
                ports = ["ui", "otlp_grpc", "otlp_http"]

            }

            template {
                data = file("gateway.alloy")
                destination = "local/gateway.alloy"
            }
            template {
                data = <<-EOF
                {{- $allocID := env "NOMAD_ALLOC_ID" -}}
                {{ range nomadService 1 $allocID "loki"}}
                logs: http://{{ .Address }}:{{ .Port }}/otlp
                {{- end }}
                {{ range nomadService 1 $allocID "mimir"}}
                metrics: http://{{ .Address }}:{{ .Port }}/otlp
                {{- end }}
                {{ range nomadService 1 $allocID "tempo-otlp"}}
                traces: http://{{ .Address }}:{{ .Port }}
                {{- end }}
                EOF
                destination = "local/backends.yaml"
                change_mode = "noop"

            }
        }


        service {
            provider = "nomad"
            name = "otel-gateway-otlp-grpc"
            port = "otlp_grpc"
            check {
                type = "http"
                path = "/-/ready"
                interval = "10s"
                timeout = "2s"
                port = "ui"
            }
        }
    }
}