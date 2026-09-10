from http.server import HTTPServer, BaseHTTPRequestHandler
import os


class MyHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"Hello from my DevOps application - Health check feature!")

port = int(os.environ.get("PORT", "8080"))
server = HTTPServer(("0.0.0.0", port), MyHandler)

print(f"Application running on port {port}...")

server.serve_forever()
