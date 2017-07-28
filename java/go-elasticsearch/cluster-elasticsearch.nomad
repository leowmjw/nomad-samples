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

    task "elasticsearch" {
      driver = "java"

      artifact {
        source = "http://localhost:8080/elasticsearch-5.5.0.zip"
        // source = "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.5.0.zip"
        destination = "/local"
        options {
          checksum = "sha1:b5835f207cec4ed73758f5f1640ede59851f873f"
        }
      }

      config {
        class = "org.elasticsearch.bootstrap.Elasticsearch"
        class_path = "/local/elasticsearch-5.5.0/lib/*"
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
        ES_HOME = "/local/elasticsearch-5.5.0"
      }

      resources {
        # 100 MHz; burstable
        cpu = 100
        disk = 500
        # 768 MB
        memory = 768
        network {
          mbits = 10
          port "eshttp" {}
          port "estransport" {}
        }
      }

      service {
        tags = [
          "simple",
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

          network.host: {{ env "attr.unique.network.ip-address" }}
          http.port: {{ env "NOMAD_HOST_PORT_eshttp" }}
          transport.tcp.port: {{ env "NOMAD_HOST_PORT_estransport" }}

          # Specific port from example elasticsearch.yml (memory should be 1/2 of available memory)
          bootstrap.memory_lock: true
          # node.name: node-1
          # node.attr.rack: r1
          # path.data: /path/to/data,/another/path/to/data_for_perf_raid0
          # path.logs: /path/to/logs

          # Below are tweaks which may only be suitable in dev environments
          cluster.routing.allocation.disk.threshold_enabled: false
      EOH
        destination = "/local/elasticsearch-5.5.0/config/elasticsearch.yml"
        change_mode = "noop"
      }

    }
  }

  group "complex" {
    count = 3
    restart {
      attempts = 3
      interval = "1m"
      delay = "10s"
      mode = "delay"
    }

    ephemeral_disk {
      migrate = true
      size = "1500"
      sticky = true
    }

    // Main leader job in pod; the ElasticSearch Cluster
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
        ES_CLUSTER_NAME = "escluster"
        ES_HOME = "local/elasticsearch-5.5.0"
      }

      resources {
        # 150 MHz; burstable
        cpu = 150
        # 500 MB
        disk = 500
        # 1024 MB
        memory = 1024
        network {
          mbits = 100
          port "eshttp" {}
          port "estransport" {}
        }
      }

      service {
        name = "escluster-transport"
        port = "estransport"
      }

      service {
        name = "escluster"
        tags = [
          "lolcats",
          "cluster"
        ]
        port = "eshttp"
        check {
          name = "available"
          type = "tcp"
          interval = "10s"
          timeout = "2s"
        }
        check {
          name = "ready"
          type = "http"
          port = "eshttp"
          path = "/_cluster/health?wait_for_status=yellow"
          interval = "30s"
          timeout = "10s"
        }
      }

      # Great refrenece from:
      # https://groups.google.com/forum/#!searchin/nomad-tool/elasticsearch%7Csort:relevance/nomad-tool/0qtyyor1ORs/uN9uIyN7BAAJ
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

          cluster.name: {{ env "ES_CLUSTER_NAME" }}
          network.host: {{ env "attr.unique.network.ip-address" }}
          discovery.zen.minimum_master_nodes: 2
          # network.publish_host: {{ env "attr.unique.network.ip-address" }}
          {{ if service "escluster-transport"}}discovery.zen.ping.unicast.hosts:{{ range service "escluster-transport" }}
            - {{ if eq .Address "::1" }}localhost{{ else }}{{ .Address }}{{ end }}:{{ .Port }}{{ end }}{{ end }}
          http.port: {{ env "NOMAD_HOST_PORT_eshttp" }}
          transport.tcp.port: {{ env "NOMAD_HOST_PORT_estransport" }}

          # Specific port from example elasticsearch.yml (memory should be 1/2 of available memory)
          bootstrap.memory_lock: true
          # node.name: node-1
          # node.attr.rack: r1
          # path.data: /path/to/data,/another/path/to/data_for_perf_raid0
          # path.logs: /path/to/logs

          # Below are tweaks which may only be suitable in dev environments
          cluster.routing.allocation.disk.threshold_enabled: false
      EOH
        destination = "local/elasticsearch-5.5.0/config/elasticsearch.yml"
        // change_mode = "restart"
        change_mode = "noop"
        // change_mode = "signal"
        // change_signal = "SIGHUP"
      }

    }

    // Sidecar for monitoring/admin etc..
    // task "cerebro" {}
  }
}
