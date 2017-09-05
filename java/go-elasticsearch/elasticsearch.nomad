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
      attempts = 2
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    ephemeral_disk {
      migrate = true
      size = "5000"
      sticky = true
    }

    task "elasticsearch" {
      driver = "java"

      artifact {
        source = "http://127.0.0.1:8080/elasticsearch-5.5.2.zip"
        // source = "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.5.2.zip"
        destination = "local"
        options {
          checksum = "sha1:9d549e8f3d2bc5051fdf6973e2edd110f04c6dc3"
        }
      }

      config {
        class = "org.elasticsearch.bootstrap.Elasticsearch"
        class_path = "local/elasticsearch-5.5.2/lib/*"
        jvm_options = [
          "-Des.path.home=${ES_HOME}",
          "-Xmx512m",
          "-Xms512m",
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
        ES_HOME = "local/elasticsearch-5.5.2"
      }

      resources {
        # 150 MHz; burstable
        cpu = 150
        # 2GB; twice memory alloc
        disk = 2048
        # 1024 MB
        memory = 1024
        network {
          mbits = 100
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
          # Ref: https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-network.html#network-interface-values
          # network.host: [ "0.0.0.0", "_eth0_", "_site_", "_global_" ]
          # discovery.zen.ping.unicast.hosts: ["127.0.0.1", "[::1]"]
          # http.port: {{ env "NOMAD_HOST_PORT_eshttp" }}
          # transport.tcp.port: {{ env "NOMAD_HOST_PORT_estransport" }}
          # Below special cases needed to address proxy
          # network.bind_host (incoming), network.publish_host (node-to-node communications)
          # http.publish_port: {{ env "NOMAD_HOST_PORT_eshttp" }}
          # transport.publish_port: {{ env "NOMAD_HOST_PORT_estransport" }}
          # cluster.name: {{ env "ES_CLUSTER_NAME" }}
          # discovery.zen.minimum_master_nodes: 2
          # {{ if service "escluster-transport"}}discovery.zen.ping.unicast.hosts:{{ range service "escluster-transport" }}
          # - {{ .Address }}:{{ .Port }}{{ end }}{{ end }}
          # Specific port from example elasticsearch.yml (memory should be 1/2 of available memory)
          bootstrap.memory_lock: true
          # node.name: node-1
          # node.attr.rack: r1
          # path.data: /path/to/data,/another/path/to/data_for_perf_raid0
          # path.logs: /path/to/logs

          network.host: {{ env "attr.unique.network.ip-address" }}
          network.publish_host: {{ env "attr.unique.network.ip-address" }}
          http.port: {{ env "NOMAD_HOST_PORT_eshttp" }}
          transport.tcp.port: {{ env "NOMAD_HOST_PORT_estransport" }}

          # Below are tweaks which may only be suitable in dev environments
          cluster.routing.allocation.disk.threshold_enabled: false
      EOH
        destination = "local/elasticsearch-5.5.2/config/elasticsearch.yml"
        // change_mode = "noop"
        // change_mode = "signal"
        // change_signal = "SIGHUP"
      }
    }
  }
}
