package main

import (
	"fmt"
	"html/template"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"sync"
	"time"
)

var (
	filePath    = os.Getenv("SECRET_PATH")
	fileContent string
	mu          sync.Mutex
	tmpl        = template.Must(template.New("index").Parse(`
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Vault Secret Sync Demo</title>
            <link rel="stylesheet" type="text/css" href="/static/styles.css">
            <script src="https://cdn.jsdelivr.net/npm/canvas-confetti@1.5.1/dist/confetti.browser.min.js"></script>
            <script>
                let previousContent = "";

                async function fetchContent() {
                    const response = await fetch('/content');
                    const text = await response.text();
                    if (text !== previousContent) {
                        previousContent = text;
                        document.getElementById('content').innerText = text;
                        triggerConfetti();
                    }
                }

                function triggerConfetti() {
                    confetti({
                        particleCount: 100,
                        spread: 70,
                        origin: { y: 0.6 }
                    });
                }

                setInterval(fetchContent, 1000); // Refresh content every 1 second
            </script>
        </head>
        <body onload="fetchContent()">
            <div class="container">
                <h1>Vault Secret Sync Demo</h1>
                <img src="/static/splash1.png" alt="Vault Secret Sync Demo">
                <div id="content" class="content"></div>
            </div>
        </body>
        </html>
    `))
)

func main() {

	updateFileContent()

	go pollFileChanges()

	http.Handle("/static/", http.StripPrefix("/static/", http.FileServer(http.Dir("."))))

	http.HandleFunc("/", serveTemplate)
	http.HandleFunc("/content", serveContent)
	log.Println("Starting server on :18200")
	log.Fatal(http.ListenAndServe(":18200", nil))
}

func serveTemplate(w http.ResponseWriter, r *http.Request) {
	tmpl.Execute(w, nil)
}

func serveContent(w http.ResponseWriter, r *http.Request) {
	mu.Lock()
	defer mu.Unlock()
	fmt.Fprint(w, fileContent)
}

func updateFileContent() {
	mu.Lock()
	defer mu.Unlock()
	data, err := ioutil.ReadFile(filePath)
	if err != nil {
		log.Println("Error reading file:", err)
		fileContent = "Error reading file"
		return
	}
	fileContent = string(data)
}

func pollFileChanges() {
	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()
	for range ticker.C {
		updateFileContent()
	}
}
