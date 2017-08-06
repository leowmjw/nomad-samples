package main

import (
	"fmt"
	"html"
	"log"
	"net/http"
	"os"
)

// Simple HTTP server here ...
func main() {
	http.Handle("/", http.FileServer(http.Dir("/tmp")))

	http.HandleFunc("/bar", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello, %q", html.EscapeString(r.URL.Path))
	})

	// If the Nomad port for this port is defined, use it
	// else default to 8888 .. for testing purpose ..
	// label is NOMAD_PORT_http
	val, ok := os.LookupEnv("NOMAD_PORT_http")
	if ok {
		log.Fatal(http.ListenAndServe(":"+val, nil))
	} else {
		log.Fatal(http.ListenAndServe(":8888", nil))
	}
}
