#!/usr/bin/env python3

import sys
import socketserver

port=80

if len(sys.argv) > 1 and sys.argv[1].isnumeric():
    port=int(sys.argv[1])


class CmdHttpHandler(socketserver.BaseRequestHandler):
    def handle(self):
        try:
            self.data = self.request.recv(2**14).strip().decode("UTF-8")
            if len(self.data) == 0:
                return
            elif self.data.splitlines()[0].startswith("GET"):
                command = input("%s > " % self.client_address[0]).encode("UTF-8")
                response = (b"HTTP/1.1 200\ncontent-length: "
                            + str(len(command)).encode("UTF-8")
                            + b"\n\n"
                            + command)
                self.request.sendall(response)
            elif self.data.splitlines()[0].startswith("POST"):
                print(self.data)
                print()
                response = (b"HTTP/1.1 200\ncontent-length: 0\n\n")
                self.request.sendall(response)
                return
            else:
                print(self.data.decode("UTF-8"))
                response = (b"HTTP/1.1 300\ncontent-length: 0\n\n")
                self.request.sendall(response)
        except:
            print("Connection lost, please try again.")


def main():
    print("Listening on port: " + str(port))
    print("To close connection enter 'EXIT'")
    print()

    with socketserver.TCPServer(("0.0.0.0", port), CmdHttpHandler) as server:
        server.serve_forever()


if __name__ == "__main__":
    main()
