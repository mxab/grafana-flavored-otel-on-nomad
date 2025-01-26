job "nodejs-demo" {
    datacenters = ["dc1"]
    type = "service"
    group "nodejs-demo" {
        
        network {
            port "http" {
                static = 3333
                to = 3000
                
            }
        }
        task "nodejs-demo" {
            driver = "docker"
            config {
                image = "nodejs-demo:1"
                ports = ["http"]
                
            }
            
            service {
                provider = "nomad"
                name = "nodejs-demo"
                port = "http"
                check {
                    type     = "tcp"
                    interval = "10s"
                    timeout  = "2s"
                }
            }
        }
    }
}