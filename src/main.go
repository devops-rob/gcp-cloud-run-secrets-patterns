package main

import (
	"fmt"
	"github.com/fsnotify/fsnotify"
	"html/template"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"sync"
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
            <title>File Content</title>
            <script>
                async function fetchContent() {
                    const response = await fetch('/content');
                    const text = await response.text();
                    document.getElementById('content').innerText = text;
                }
                setInterval(fetchContent, 1000); // Refresh content every 1 second
            </script>
        </head>
        <body onload="fetchContent()">
            <h1>File Content</h1>
            <pre id="content"></pre>
        </body>
        </html>
    `))
)

func main() {
	// Initialize file content
	updateFileContent()

	// Watch for file changes
	go watchFileChanges()

	// Serve HTTP
	http.HandleFunc("/", serveTemplate)
	http.HandleFunc("/content", serveContent)
	log.Println("Starting server on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
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

func watchFileChanges() {
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		log.Fatal(err)
	}
	defer watcher.Close()

	done := make(chan bool)
	go func() {
		for {
			select {
			case event, ok := <-watcher.Events:
				if !ok {
					return
				}
				if event.Op&fsnotify.Write == fsnotify.Write {
					log.Println("File modified:", event.Name)
					updateFileContent()
				}
			case err, ok := <-watcher.Errors:
				if !ok {
					return
				}
				log.Println("Error:", err)
			}
		}
	}()

	err = watcher.Add(filePath)
	if err != nil {
		log.Fatal(err)
	}
	<-done
}
