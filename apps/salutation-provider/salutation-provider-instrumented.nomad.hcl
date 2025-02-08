job "salutation-provider" {

  type        = "service"
  datacenters = ["dc1"]

  
  group "salutation-provider" {

    network {
      port "http" {
        to     = 8080
      }
    }


    task "salutation-provider" {

      driver = "docker"

      config {
        image = "salutation-provider:1.0.0"
        ports = ["http"]
      }
      artifact {
        source      = "https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v2.12.0/opentelemetry-javaagent.jar"
        destination = "local/"
        options {
          archive = false
        }
      }
      template {
        env = true

        data        = <<-EOF
            JAVA_TOOL_OPTIONS="-javaagent:/local/opentelemetry-javaagent.jar"
            OTEL_TRACES_EXPORTER=otlp
            OTEL_EXPORTER_OTLP_PROTOCOL="http/protobuf"
            OTEL_EXPORTER_OTLP_ENDPOINT=http://{{ env "attr.unique.network.ip-address" }}:4318

            OTEL_RESOURCE_ATTRIBUTES=service.name={{ env "NOMAD_TASK_NAME"}},service.instance.id={{ env "NOMAD_SHORT_ALLOC_ID"}}



            # OTEL_SERVICE_NAME={{ env "NOMAD_TASK_NAME"}} # would work only for service.name
            OTEL_INSTRUMENTATION_LOGBACK_APPENDER_EXPERIMENTAL_CAPTURE_CODE_ATTRIBUTES=true
            OTEL_INSTRUMENTATION_LOGBACK_APPENDER_EXPERIMENTAL_CAPTURE_KEY_VALUE_PAIR_ATTRIBUTES=true
            OTEL_INSTRUMENTATION_LOGBACK_APPENDER_EXPERIMENTAL_CAPTURE_MDC_ATTRIBUTES="*"

        EOF
        destination = "local/otel.env"
      }
      resources {
        cpu    = 500
        memory = 1024
      }
    }
    service {
      name     = "salutation-provider"
      port     = "http"
      provider = "nomad"
      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }
  }
  reschedule {
    unlimited = true
    delay_function = "constant"
    delay = "10s"
  }
}