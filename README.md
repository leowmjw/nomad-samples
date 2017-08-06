# nomad-samples
Hashicorp Nomad Samples and Examples worked through on request

## Commands to Run (in separate tmux screens)

```
# In this directory

# Start up Consul
$ ~/NOMAD/consul agent -bind 0.0.0.0 -dev -config-file=consul-conf.json -data-dir=/tmp/consul

# Start up Nomad
$ ~/NOMAD/nomad agent -dev -config=nomad.hcl -config=nomad-conf.json -data-dir=/tmp/nomad
```