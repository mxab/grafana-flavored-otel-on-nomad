job "otel-agent" {
    type = "system"
    datacenters = ["*"]

    group "agent" {

        restart {
            mode = "delay"
            interval = "20s"
            delay = "10s"
        }
        network {
            port "ui" {
                static = 12345
            }
            port "otlp_grpc" {
                static = 4317
            }
            port "otlp_http" {
                static = 4318
            }
        }

        task "alloy" {
            driver = "docker"

            config {
                image = "grafana/alloy:v1.6.1"
                
                args = [
                    "run",
                    "--stability.level=experimental",
                    "--server.http.listen-addr=0.0.0.0:12345",
                    "--storage.path=${NOMAD_ALLOC_DIR}/data",
                    "${NOMAD_TASK_DIR}/agent.alloy"
                ]   
                ports = ["ui", "otlp_grpc", "otlp_http"]

            }

            template {
                data = file("agent.alloy")
                destination = "local/agent.alloy"
            }
            template {
                data = <<-EOF
                {{- $allocID := env "NOMAD_ALLOC_ID" -}}
                [
                {{ range nomadService "otel-gateway-otlp-grpc" -}}"{{ .Address }}:{{ .Port }}",{{- end }}
                ]
                EOF
                destination = "local/gateways.yaml"
                change_mode = "noop"
            }
        }
    }
}