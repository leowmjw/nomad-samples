
# Elasticsearch setup with Nomad and Consul

## Details

Go + NodeJS code comes from: https://github.com/alextanhongpin/go-elasticsearch

Tweaks and faults are my own :P  

Default credentials for elastic search

+ username: elastic
+ password: changeme

## Setup

Run Consul, Nomad, Hashi-UI; in different tmux screens:
```bash
$ consul agent -dev
$ nomad agent -dev
$ hashi-ui-darwin-amd64 --consul-enable --nomad-enable
```

Startup simple webserver to serve the Elasticsearch binary artifact downloaded from the website:
```bash
$ http-server  ~/NOMAD/ELASTICSEARCH/ARTIFACT
Starting up http-server, serving /Users/leow/NOMAD/ELASTICSEARCH/ARTIFACT
Available on:
  http:127.0.0.1:8080
  http:192.168.1.11:8080
Hit CTRL-C to stop the server
```
Above is needed so that it does not take so logn to start up; otherwise each job allocation will need to redownload the binary from the net!


View the Consul UI at http://127.0.0.1:8500

View nicer Consul UI at: http://localhost:3000/consul/dc1

View nice Nomad UI at: http://localhost:3000/nomad/global

## Resources/Notes
- Great example of template that insipred final solution found [here](https://groups.google.com/forum/#!searchin/nomad-tool/elasticsearch%7Csort:relevance/nomad-tool/0qtyyor1ORs/uN9uIyN7BAAJ) 
- change_mode had to be set at noop otherwise for "restart" and "signal", the node keeps on restarting for unknown reason
- The additional service escluster-transport was needed to get
