#!/usr/bin/env python3
"""
Simple HTTP Webcam Server untuk Godot
"""

import cv2
from http.server import HTTPServer, BaseHTTPRequestHandler

class WebcamHTTPHandler(BaseHTTPRequestHandler):
    camera = None
    
    def do_GET(self):
        if self.path == '/frame':
            if self.camera is None:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(b"Camera not initialized")
                return
                
            ret, frame = self.camera.read()
            if ret:
                # Resize dan encode JPEG
                frame = cv2.resize(frame, (640, 480))
                _, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 80])
                
                # Send raw JPEG data
                self.send_response(200)
                self.send_header('Content-Type', 'image/jpeg')
                self.send_header('Content-Length', str(len(buffer)))
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                
                self.wfile.write(buffer.tobytes())
            else:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(b"Failed to capture frame")
        else:
            self.send_response(404)
            self.end_headers()

class SimpleWebcamServer:
    def __init__(self, host='127.0.0.1', port=8081):
        self.host = host
        self.port = port
        self.camera = None
    
    def initialize_camera(self):
        print("🎥 Mencoba inisialisasi kamera...")
        self.camera = cv2.VideoCapture(0, cv2.CAP_DSHOW)
        
        if self.camera.isOpened():
            ret, frame = self.camera.read()
            if ret and frame is not None:
                print("✅ Kamera berhasil diinisialisasi")
                self.camera.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
                self.camera.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
                return True
        
        print("❌ Error: Tidak dapat mengakses kamera")
        return False
    
    def start_server(self):
        if not self.initialize_camera():
            return
        
        # Set kamera untuk handler
        WebcamHTTPHandler.camera = self.camera
        
        print(f"🚀 HTTP Server starting at http://{self.host}:{self.port}")
        server = HTTPServer((self.host, self.port), WebcamHTTPHandler)
        
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            print("\n🛑 Server stopped")
        finally:
            if self.camera:
                self.camera.release()

if __name__ == "__main__":
    print("=== HTTP Webcam Server ===")
    print("Tekan Ctrl+C untuk berhenti")
    
    server = SimpleWebcamServer()
    server.start_server()