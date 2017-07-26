job "search" {
  datacenters = [
    "dc1"
  ]
  type = "service"

  update {
    stagger = "10s"
    max_parallel = 1
  }

  group "simple" {
    count = 1
    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    ephemeral_disk {
      migrate = true
      size = "500"
      sticky = true
    }

    task "elasticsearch" {
      driver = "java"

      artifact {
        source = "http://localhost:8080/elasticsearch-5.5.0.zip"
        // source = "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.5.0.zip"
        destination = "local"
        options {
          checksum = "sha1:b5835f207cec4ed73758f5f1640ede59851f873f"
        }
      }

      config {
        class = "org.elasticsearch.bootstrap.Elasticsearch"
        class_path = "local/elasticsearch-5.5.0/lib/*"
        jvm_options = [
          "-Des.path.home=${ES_HOME}",
          "-Xmx768m",
          "-Xms768m",
          "-XX:+UseConcMarkSweepGC",
          "-XX:CMSInitiatingOccupancyFraction=75",
          "-XX:+UseCMSInitiatingOccupancyOnly",
          "-XX:+DisableExplicitGC",
          "-XX:+AlwaysPreTouch",
          "-server",
          "-Xss1m",
          "-Djava.awt.headless=true",
          "-Dfile.encoding=UTF-8",
          "-Djna.nosys=true",
          "-Djdk.io.permissionsUseCanonicalPath=true",
          "-Dio.netty.noUnsafe=true",
          "-Dio.netty.noKeySetOptimization=true",
          "-Dio.netty.recycler.maxCapacityPerThread=0",
          "-Dlog4j.shutdownHookEnabled=false",
          "-Dlog4j2.disable.jmx=true",
          "-Dlog4j.skipJansi=true",
          "-XX:+HeapDumpOnOutOfMemoryError"
        ]
      }

      env {
        ES_CLUSTER_NAME = "docker-cluster"
        ES_HOME = "local/elasticsearch-5.5.0"
      }

      resources {
        # 1000 MHz
        cpu = 1000
        # 512 MB
        disk = 512
        # 1024 MB
        memory = 1024
        network {
          mbits = 10
          port "eshttp" {}
          port "estransport" {}
        }
      }

      service {
        // name = "elasticsearch"
        tags = [
          "lolcats",
          "search"
        ]
        port = "eshttp"
        check {
          name = "alive"
          type = "tcp"
          interval = "10s"
          timeout = "2s"
        }
      }

      template {
        data = <<EOH
          cluster.name: {{ env "ES_CLUSTER_NAME" }}
          network.host: {{ env "attr.unique.network.ip-address" }}
          bootstrap.memory_lock: true
          # discovery.zen.minimum_master_nodes: 2
          network.publish_host: {{ env "attr.unique.network.ip-address" }}
          # {{ if service "escluster-transport"}}discovery.zen.ping.unicast.hosts:{{ range service "escluster-transport" }}
          # - {{ .Address }}:{{ .Port }}{{ end }}{{ end }}
          http.port: {{ env "NOMAD_HOST_PORT_eshttp" }}
          http.publish_port: {{ env "NOMAD_HOST_PORT_eshttp" }}
          transport.tcp.port: {{ env "NOMAD_HOST_PORT_estransport" }}
          transport.publish_port: {{ env "NOMAD_HOST_PORT_estransport" }}
      EOH
        destination = "local/elasticsearch-5.5.0/config/elasticsearch.yml"
        change_mode = "signal"
        change_signal = "SIGHUP"
      }

    }
  }
}
