import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


class Handler(BaseHTTPRequestHandler):
    def _send(self, code, headers, body: bytes):
        self.send_response(code)
        for k, v in headers.items():
            self.send_header(k, v)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _handle(self):
        path = self.path.split("?")[0]
        body_len = int(self.headers.get("Content-Length", 0) or 0)
        req_body = self.rfile.read(body_len) if body_len else b""

        if path == "/normal":
            body = b'<html><head><meta name="generator" content="WordPress 6.4"></head>' \
                   b'<body>wp-content/themes/test hello</body></html>'
            self._send(200, {"Server": "Apache/2.4.41 (Ubuntu)",
                              "Set-Cookie": "PHPSESSID=abc123; Path=/",
                              "Content-Type": "text/html"}, body)
        elif path == "/phperror":
            body = b"<html><body>Fatal error: Uncaught Error: Call to undefined function foo() " \
                   b"in /var/www/html/index.php:42 Stack trace: on line 42</body></html>"
            self._send(200, {"Server": "Apache/2.4.41", "Content-Type": "text/html"}, body)
        elif path == "/notfound":
            self._send(404, {"Content-Type": "text/plain"}, b"not found")
        elif path == "/servererror":
            self._send(500, {"Content-Type": "text/plain"}, b"Internal Server Error")
        elif path == "/redirect":
            self._send(302, {"Location": "/normal"}, b"")
        elif path == "/echo":
            resp = {
                "method": self.command,
                "headers": dict(self.headers.items()),
                "body": req_body.decode("utf-8", errors="replace"),
            }
            self._send(200, {"Content-Type": "application/json"}, json.dumps(resp).encode())
        else:
            self._send(404, {"Content-Type": "text/plain"}, b"unknown path")

    def do_GET(self):
        self._handle()

    def do_POST(self):
        self._handle()

    def do_PUT(self):
        self._handle()

    def log_message(self, fmt, *args):
        pass  # silence per-request logging


if __name__ == "__main__":
    import sys
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8765
    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    print(f"listening on 127.0.0.1:{port}")
    server.serve_forever()
