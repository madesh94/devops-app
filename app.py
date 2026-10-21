from http.server import HTTPServer, BaseHTTPRequestHandler
import os


class MyHandler(BaseHTTPRequestHandler):
    def do_GET(self):

        if os.environ.get("SIMULATE_FAILURE") == "true":
            self.send_response(500)
            self.end_headers()
            self.wfile.write(b"Version 3 - Simulated failure!")
            return

        self.send_response(200)
        self.end_headers()
        self.wfile.write(
            b"Hello from my DevOps Version 3 - Health check feature!"
        )


port = int(os.environ.get("PORT", "8080"))

server = HTTPServer(("0.0.0.0", port), MyHandler)

print(f"Application running on port {port}...")

server.serve_forever()
