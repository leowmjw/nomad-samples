job "data" {

  datacenters = ["dc1"]
  type = "service"

  constraint {
    attribute = "${attr.kernel.name}"
    value = "linux"
  }

  update {
    stagger = "2s"
    max_parallel = 1
  }
  
  group "data" {

    constraint {
      attribute = "${attr.unique.hostname}"
      value = "acme-nomad-dev-worker-node-1"
    }

    count = 1
    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    ephemeral_disk {
      migrate = "true"
      size = 2500
      sticky = "true"
    }

    task "mysql" {
      driver = "docker"
      config {
        image = "mysql"
        port_map {
          mysql = "3306"
        }
      }

      env {
        MYSQL_DATABASE = "laravel"
        MYSQL_USER = "laravel"
        MYSQL_PASSWORD = "passw0rd"
        MYSQL_PORT = "3306"
        MYSQL_ROOT_PASSWORD = "root"
      }

      resources {
        memory = 1500
        network {
          port "mysql" {
            static = "3307"
          }
        }
      }

      service {
        name = "data-mysql"
        tags = ["master"]
        port = "mysql"
      }
    }

    task "mysql-paid" {
      driver = "docker"
      config {
        image = "mysql"
        port_map {
          mysql = "3306"
        }
      }

      env {
        MYSQL_DATABASE = "laravel"
        MYSQL_USER = "laravel"
        MYSQL_PASSWORD = "passw0rd"
        MYSQL_PORT = "3306"
        MYSQL_ROOT_PASSWORD = "root"
      }

      resources {
        memory = 1500
        network {
          port "mysql" {
            static = "3308"
          }
        }
      }

      service {
        name = "data-mysql-paid"
        tags = ["master"]
        port = "mysql"
      }
    }

  }


}
