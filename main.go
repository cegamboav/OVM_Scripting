package main

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/gorilla/mux"
	//"github.com/gorilla/mux"
)

func handleIndex(w http.ResponseWriter, r *http.Request) {
	json.NewEncoder(w).Encode("{\"message\": \"Hello World\"}")
}

func main() {
	r := mux.NewRouter()
	r.HandleFunc("/", handleIndex).Methods(http.MethodGet)

	srv := http.Server{
		Addr:    ":8081",
		Handler: r,
	}

	log.Println("Listening...")
	srv.ListenAndServe()
}
