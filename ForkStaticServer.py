#!/usr/bin/env python

import socket
import SocketServer
import sys
import os
from SimpleHTTPServer import SimpleHTTPRequestHandler

class ForkingHTTPServer(SocketServer.ForkingTCPServer):

   allow_reuse_address = 1

   def server_bind(self):
       """Override server_bind to store the server name."""
       SocketServer.TCPServer.server_bind(self)
       host, port = self.socket.getsockname()[:2]
       self.server_name = socket.getfqdn(host)
       self.server_port = port

def run(HandlerClass = SimpleHTTPRequestHandler,
         ServerClass = ForkingHTTPServer, protocol="HTTP/1.0"):

    host = ''
    port = 8001
    if len(sys.argv) > 1:
        arg = sys.argv[1]
        if ':' in arg:
            host, port = arg.split(':')
            port = int(port)
        else:
            try:
                port = int(sys.argv[1])
            except:
                host = sys.argv[1]

	dir = sys.argv[2]
	try:
		os.chdir(dir)
	except:
		print "The specified [ %s ] directory is invalid." %dir
		exit(1)

    server_address = (host, port)

    HandlerClass.protocol_version = protocol
    httpd = ServerClass(server_address, HandlerClass)

    sa = httpd.socket.getsockname()
    print "Serving HTTP on", sa[0], "port", sa[1], "..."
    httpd.serve_forever()


if __name__ == '__main__':
    run() 
