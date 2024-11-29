import socket

# Server configuration
HOST = "127.0.0.1"  # Localhost
PORT = 8080         # Port to listen on

def handle_request(data):
    """
    Handle incoming request and return a response.
    """
    if data.strip() == "GET /STATUS_LIGHT":
        return "ON"
    else:
        return "OFF"

def start_server():
    """
    Start a TCP server that listens for incoming connections
    and responds with ON or OFF.
    """
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server_socket:
        # Bind to the address and port
        server_socket.bind((HOST, PORT))
        server_socket.listen(5)  # Listen for up to 5 connections
        print(f"Server listening on {HOST}:{PORT}")
        
        while True:
            # Accept a client connection
            client_socket, client_address = server_socket.accept()
            print(f"Connection established with {client_address}")
            
            with client_socket:
                # Receive the data from the client
                data = client_socket.recv(1024).decode("utf-8")
                print(f"Received: {data}")
                
                # Process the request and generate a response
                response = handle_request(data)
                print(f"Responding with: {response}")
                
                # Send the response back to the client
                client_socket.sendall(response.encode("utf-8"))

if __name__ == "__main__":
    start_server()
