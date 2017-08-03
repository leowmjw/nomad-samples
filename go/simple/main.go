package main

import (
	"fmt"
	"html"
	"log"
	"net/http"
)

// Simple HTTP server here ...
func main() {
	http.Handle("/", http.FileServer(http.Dir("/tmp")))

	http.HandleFunc("/bar", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello, %q", html.EscapeString(r.URL.Path))
	})

	log.Fatal(http.ListenAndServe(":8080", nil))
}
