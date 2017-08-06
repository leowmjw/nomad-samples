# Running native golang in Nomad

## Pre-reqs
- OSX users need to enable raw_exec driver; parent README already shows how with config ..
- Binary needs to be serve (for example: use http-server for local folder); although for single machine can refer to command with "Absolute path " too ..
```
      artifact {
        source = "http://localhost:8080/simple-app"
      }

```

## Example
For a "service" type job; get the port to be binded to from the ENV

As per example in the "simple" Golang App example:
```
	// If the Nomad port for this port is defined, use it
	// else default to 8888 .. for testing purpose ..
	// label is NOMAD_PORT_http
	val, ok := os.LookupEnv("NOMAD_PORT_http")
	if ok {
		log.Fatal(http.ListenAndServe(":"+val, nil))
	} else {
		log.Fatal(http.ListenAndServe(":8888", nil))
	}

```