#!/usr/bin/env python3
"""
Webcam Server untuk Godot Game
Mengirim frame webcam melalui TCP socket ke Godot client
"""

import cv2
import socket
import threading
import time
import numpy as np
import psutil  # Tambahkan ini

class WebcamServer:
    def __init__(self, host='127.0.0.1', port=8081):
        self.host = host
        self.port = port
        self.camera = None
        self.running = False
        self.clients = []
    
    def check_camera_usage(self):
        """Check aplikasi apa yang sedang menggunakan kamera"""
        print("Mengecek penggunaan kamera...")
        
        camera_processes = []
        for proc in psutil.process_iter(['pid', 'name']):
            try:
                process_name = proc.info['name'].lower()
                # Daftar aplikasi yang biasa pakai kamera
                camera_apps = ['zoom', 'teams', 'skype', 'discord', 'obs', 'chrome', 'firefox', 'edge']
                
                if any(app in process_name for app in camera_apps):
                    camera_processes.append(f"- {proc.info['name']} (PID: {proc.info['pid']})")
                    
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                continue
                
        if camera_processes:
            print("Aplikasi yang mungkin menggunakan kamera:")
            for proc in camera_processes:
                print(proc)
            print("\nTutup aplikasi tersebut lalu coba lagi.")
        else:
            print("Tidak ada aplikasi yang terdeteksi menggunakan kamera.")
        
    def initialize_camera(self):
        """Initialize camera dengan multiple fallbacks"""
        print("Mencoba inisialisasi kamera...")
        
        # Cek penggunaan kamera dulu
        self.check_camera_usage()
        
        # Coba berbagai index kamera
        for camera_index in [0, 1, 2]:
            print(f"Mencoba kamera index {camera_index}...")
            self.camera = cv2.VideoCapture(camera_index, cv2.CAP_DSHOW)
            
            if self.camera.isOpened():
                ret, frame = self.camera.read()
                if ret and frame is not None:
                    print(f"✅ Kamera berhasil diinisialisasi dengan index {camera_index}")
                    
                    # Set resolusi
                    self.camera.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
                    self.camera.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
                    self.camera.set(cv2.CAP_PROP_FPS, 30)
                    
                    return True
                else:
                    self.camera.release()
                    
        print("❌ Error: Tidak dapat mengakses kamera")
        print("Pastikan:")
        print("1. Kamera tidak digunakan aplikasi lain")
        print("2. Windows Camera permission sudah diaktifkan")
        print("3. Driver kamera sudah terinstall")
        return False
        
    def start_server(self):
        if not self.initialize_camera():
            return
            
        self.running = True
        server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        
        try:
            print(f"🔍 Attempting to bind to {self.host}:{self.port}")
            server_socket.bind((self.host, self.port))
            server_socket.listen(5)
            print(f"🚀 Server listening pada {self.host}:{self.port}")
            print("📡 Menunggu koneksi dari Godot client...")
            print("🔧 Debug: Server ready to accept connections")
            
            while self.running:
                try:
                    print("⏳ Waiting for client connection...")
                    client_socket, addr = server_socket.accept()
                    print(f"✅ Client terhubung dari {addr}")
                    
                    client_thread = threading.Thread(
                        target=self.handle_client, 
                        args=(client_socket,)
                    )
                    client_thread.daemon = True
                    client_thread.start()
                    
                except Exception as e:
                    if self.running:
                        print(f"Error menerima koneksi: {e}")
                        
        except Exception as e:
            print(f"Error server: {e}")
        finally:
            server_socket.close()
            if self.camera:
                self.camera.release()
                
    def handle_client(self, client_socket):
        try:
            while self.running:
                ret, frame = self.camera.read()
                if not ret or frame is None:
                    print("Error: Tidak dapat membaca frame")
                    break
                    
                # Resize untuk performa
                frame = cv2.resize(frame, (640, 480))
                
                # Encode ke JPEG
                _, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 80])
                frame_data = buffer.tobytes()
                
                # Kirim size dulu, lalu data
                size = len(frame_data)
                client_socket.sendall(size.to_bytes(4, 'big'))
                client_socket.sendall(frame_data)
                
                time.sleep(1/30)  # 30 FPS
                
        except Exception as e:
            print(f"Client disconnected: {e}")
        finally:
            client_socket.close()

if __name__ == "__main__":
    print("=== Webcam Server untuk Godot ===")
    print("Tekan Ctrl+C untuk berhenti")
    
    server = WebcamServer()
    try:
        server.start_server()
    except KeyboardInterrupt:
        print("\nServer dihentikan")
        server.running = False