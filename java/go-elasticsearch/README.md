
# Elasticsearch setup with Nomad and Consul

Default credentials for elastic search

+ username: elastic
+ password: changeme

Run Consul, Nomad, Hashi-UI; in different tmux screens
```bash
$ consul agent -dev
$ nomad agent -dev
$ hashi-ui-darwin-amd64 --consul-enable --nomad-enable
```

Startup simple webserver to serve the Elasticsearch binary artifact
```
$ http-server  ~/NOMAD/ELASTICSEARCH/ARTIFACT
Starting up http-server, serving /Users/leow/NOMAD/ELASTICSEARCH/ARTIFACT
Available on:
  http:127.0.0.1:8080
  http:192.168.1.11:8080
Hit CTRL-C to stop the server
```

View the Consul UI at http://127.0.0.1:8500

