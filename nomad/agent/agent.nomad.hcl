job "otel-agent" {
    type = "system"
    datacenters = ["*"]

    group "agent" {

        restart {
            mode = "delay"
        }
        network {
            port "http" {
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
                image = "grafana/alloy:latest"
                
                args = [
                    "run",
                    "--server.http.listen-addr=0.0.0.0:12345",
                    "--storage.path=${NOMAD_ALLOC_DIR}/data",
                    "${NOMAD_TASK_DIR}/agent.alloy"
                ]   
                ports = ["http", "otlp_grpc", "otlp_http"]

            }

            template {
                data = file("agent.alloy")
                destination = "local/agent.alloy"
            }
            template {
                data = file("gateways.yaml")
                destination = "local/gateways.yaml"   
            }
        }
    }
}