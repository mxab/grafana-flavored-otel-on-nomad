job "hello-world" {

  type        = "service"
  datacenters = ["dc1"]


  group "hello-world" {

    network {
      port "http" {
        to     = 8080
        static = 8080
      }
    }


    task "hello-world" {

      driver = "docker"

      config {
        image = "hello-world:1.0.0"
        ports = ["http"]
      }
      
      template {
        env         = true
        data        = <<-EOF
        {{ range nomadService "salutation-provider" }} 
        SALUTATIONPROVIDER_URL=http://{{ .Address }}:{{ .Port }}
        {{ end }}
        EOF
        destination = "local/app.env"
      }

      resources {
        cpu    = 500
        memory = 1024
      }
    }
    service {
      name     = "hello-world"
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