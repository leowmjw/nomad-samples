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
      driver = "docker"

      config {
        image = "docker.elastic.co/elasticsearch/elasticsearch:5.5.1"
        port_map {
          eshttp = 9200
          estransport = 9300
        }
        volumes = [
          "local/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml"
        ]
      }

      env {
        ES_JAVA_OPTS = "-Xmx500m -Xms500m"
      }

      resources {
        # 100 MHz; burstable
        cpu = 100
        disk = 500
        # 768 MB
        memory = 2048
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

          network.host: 0.0.0.0
          # network.publish_host: "{{ env "attr.unique.network.ip-address" }}"
          # network.bind_host: 0.0.0.0
          # http.port: "{{ env "NOMAD_HOST_PORT_eshttp" }}"
          # transport.tcp.port: "{{ env "NOMAD_HOST_PORT_estransport" }}"

          # Specific port from example elasticsearch.yml (memory should be 1/2 of available memory)
          # bootstrap.memory_lock: true
          # node.name: node-1
          # node.attr.rack: r1
          # path.data: /path/to/data,/another/path/to/data_for_perf_raid0
          # path.logs: /path/to/logs

          # Below are tweaks which may only be suitable in dev environments
          cluster.routing.allocation.disk.threshold_enabled: false
      EOH
        destination = "/local/elasticsearch.yml"
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

      driver = "docker"

      config {
        image = "docker.elastic.co/elasticsearch/elasticsearch:5.5.1"
        port_map {
          eshttp = 9200
          estransport = 9300
        }
        volumes = [
          "local/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml"
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
        memory = 3068
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
          cluster.name: {{ env "ES_CLUSTER_NAME" }}
          network.host: 0.0.0.0
          network.publish_host: 0.0.0.0
          network.bind_host: 0.0.0.0

          discovery.zen.minimum_master_nodes: 2
          {{ if service "escluster-transport"}}discovery.zen.ping.unicast.hosts:{{ range service "escluster-transport" }}
            - {{ if eq .Address "::1" }}localhost{{ else }}{{ .Address }}{{ end }}:{{ .Port }}{{ end }}{{ end }}

          # Below are tweaks which may only be suitable in dev environments
          cluster.routing.allocation.disk.threshold_enabled: false
      EOH
        destination = "local/elasticsearch.yml"
        change_mode = "noop"
      }

    }

    // Sidecar for monitoring/admin etc..
    // task "cerebro" {}
  }
}
