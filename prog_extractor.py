#!/usr/bin/env python3

import http.server as s

class Postprinter(s.BaseHTTPRequestHandler):
    def do_POST(self):
        j = self.rfile.read(int(self.headers['Content-Length'])).decode()
        print(j)

    def do_GET(self):
        print(got)
        
s.HTTPServer(("0.0.0.0", 8080), Postprinter).serve_forever()
