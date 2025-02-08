job "salutation-provider" {

  type        = "service"
  datacenters = ["dc1"]


  group "salutation-provider" {

    network {
      port "http" {
        to = 8080
      }
    }


    task "salutation-provider" {

      driver = "docker"

      config {
        image = "salutation-provider:1.0.0"
        ports = ["http"]
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
    unlimited      = true
    delay_function = "constant"
    delay          = "10s"
  }
}