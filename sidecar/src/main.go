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

	"github.com/fsnotify/fsnotify"
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
                <h1>Vault Agent Secret Fetch Demo</h1>
                <img src="/static/fetch-overview.png" alt="Vault Agent on GCP Demo">
                <div id="content" class="content"></div>
            </div>
        </body>
        </html>
    `))
)

func main() {
	// Initial content load
	go retryUpdateFileContent()

	// Start watching for file changes
	go watchFileChanges()

	// Start polling for file changes
	go pollFileChanges()

	// Serve static files and HTTP handlers
	http.Handle("/static/", http.StripPrefix("/static/", http.FileServer(http.Dir("."))))
	http.HandleFunc("/", serveTemplate)
	http.HandleFunc("/content", serveContent)

	log.Println("Starting server on :18201")
	log.Fatal(http.ListenAndServe(":18201", nil))
}

func serveTemplate(w http.ResponseWriter, r *http.Request) {
	tmpl.Execute(w, nil)
}

func serveContent(w http.ResponseWriter, r *http.Request) {
	mu.Lock()
	defer mu.Unlock()
	fmt.Fprint(w, fileContent)
}

// retryUpdateFileContent keeps retrying until the file is successfully read
func retryUpdateFileContent() {
	for {
		err := updateFileContent()
		if err == nil {
			log.Println("File content loaded successfully")
			return
		}
		log.Println("File not found, retrying in 5 seconds...")
		time.Sleep(5 * time.Second)
	}
}

// updateFileContent reads the file content and updates the in-memory content
func updateFileContent() error {
	mu.Lock()
	defer mu.Unlock()

	data, err := ioutil.ReadFile(filePath)
	if err != nil {
		log.Println("Error reading file:", err)
		fileContent = "Error reading file"
		return err
	}

	// Only update content if the file content has changed
	newContent := string(data)
	if newContent != fileContent {
		fileContent = newContent
		log.Println("File content updated:", fileContent)
	}

	return nil
}

// watchFileChanges sets up a file watcher to detect changes in the secret file
func watchFileChanges() {
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		log.Fatal("Failed to create watcher:", err)
	}
	defer watcher.Close()

	// Keep retrying to add the file to the watcher until it exists
	for {
		err := watcher.Add(filePath)
		if err != nil {
			log.Println("Error adding file to watcher, retrying in 5 seconds:", err)
			time.Sleep(5 * time.Second)
		} else {
			log.Println("File watcher set up successfully.")
			break
		}
	}

	// Buffered event handling with debouncing
	for {
		select {
		case event, ok := <-watcher.Events:
			if !ok {
				return
			}
			// Watch for writes or changes to the file
			if event.Op&fsnotify.Write == fsnotify.Write || event.Op&fsnotify.Chmod == fsnotify.Chmod {
				log.Println("File changed:", event.Name)
				updateFileContent()
			}
		case err, ok := <-watcher.Errors:
			if !ok {
				return
			}
			log.Println("File watcher error:", err)
		}
	}
}

// pollFileChanges polls the file periodically to ensure changes are detected
func pollFileChanges() {
	for {
		time.Sleep(3 * time.Second) // Poll every 3 seconds
		log.Println("Polling for file changes...")
		err := updateFileContent()
		if err != nil {
			log.Println("Error during file polling:", err)
		}
	}
}
