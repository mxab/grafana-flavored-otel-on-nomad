job "java-demo" {

    type       = "service"
    datacenters = ["dc1"]

    group "java-demo" {

        network {
            port "http" {
                static = 8080
                to     = 8080
            }
        }

        task "inject-otel" {
            lifecycle {
                sidecar = false
                hook    = "prestart"
            }
            driver = "docker"
            config {
                image = "java-demo:0.0.1-SNAPSHOT"
                ports = ["http"]
            }

            resources {
                cpu = 500
                memory = 1024
            }
        }
        service {
            name = "java-demo"
            port = "http"
            check {
                type     = "http"
                path     = "/actuator/health"
                interval = "10s"
                timeout  = "2s"
            }
        }
}