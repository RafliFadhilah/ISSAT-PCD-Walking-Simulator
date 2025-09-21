# ISSAT PCD - Walking Simulator with Real-time Ethnicity Detection

## 📋 **Status Project**

### ✅ **Yang Sudah Berhasil:**
- ✅ Python webcam server dapat menangkap video dari kamera
- ✅ TCP socket server berjalan dan dapat menerima koneksi dari Godot
- ✅ Godot dapat terhubung ke Python server
- ✅ Protocol komunikasi TCP sudah benar (4-byte header + JPEG data)
- ✅ Server dapat mengirim frame JPEG (~30KB per frame)

### ❌ **Masalah yang Masih Terjadi:**

#### **1. StreamPeerTCP Data Reading Issue**
**Lokasi**: `Walking Simulator/Scenes/EthnicityDetection/WebcamClient/WebcamManager.gd`
**Masalah**: 
- Godot `StreamPeerTCP.get_partial_data()` gagal membaca data TCP
- Buffer TCP menunjukkan 65536 bytes tersedia, tapi semua byte terbaca sebagai `[0, 0, 0, 0...]`
- Kemungkinan bug di Godot 4.x StreamPeerTCP implementation

**Error yang muncul:**
```
WinError 10053: An established connection was aborted by the software in your host machine
```

#### **2. Connection Timeout dan Disconnection**
**Masalah**:
- Koneksi berhasil established tapi Godot memutus koneksi setelah beberapa detik
- Python server menerima koneksi tapi data tidak sampai ke Godot dengan benar
- Status connection stuck di `STATUS_CONNECTING` meskipun server sudah accept connection

## 🔍 **Analisis Teknis Masalah**

### **Protokol Komunikasi**
```
Python Server → TCP Socket → Godot Client
[4-byte header: frame_size] + [JPEG_data: frame_size bytes]
```

### **Flow yang Diharapkan vs Realita**

| Step | Expected | Current Reality |
|------|----------|-----------------|
| 1. Connection | ✅ Python accepts connection | ✅ Working |
| 2. Data Send | ✅ Python sends JPEG frames | ✅ Working |
| 3. Data Receive | ✅ Godot reads TCP buffer | ❌ **Buffer corruption** |
| 4. Frame Process | ✅ Display webcam feed | ❌ **No frames received** |

### **Debugging Results**
```bash
# Python Server Log (Working)
✅ Client terhubung dari ('127.0.0.1', 57331)
📤 Sent 15 frames (size: 31397 bytes)

# Godot Client Log (Failing)  
🔬 First 20 bytes from TCP: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...]
📦 Available data: 65536 bytes
❌ All bytes read as zero despite server sending valid data
```

## 🛠️ **Solusi yang Sudah Dicoba**

### **1. TCP Approach Variations**
- ✅ Blocking `get_data()` - menyebabkan Godot freeze
- ✅ Non-blocking `get_partial_data()` - buffer corruption issue
- ✅ Byte-by-byte `get_u8()` - sama, data terbaca sebagai zero
- ✅ Different chunk sizes (512B, 1KB, 4KB) - tidak berpengaruh

### **2. HTTP Approach (Alternative)**
- ✅ Python HTTP server dengan base64 encoding
- ✅ Godot HTTPRequest client
- ❌ Performance issue untuk real-time streaming
- ❌ Latency terlalu tinggi untuk aplikasi real-time

### **3. Buffer Management**
- ✅ Progressive buffer accumulation
- ✅ Header validation dan frame parsing
- ✅ Connection state handling
- ❌ Masalah tetap di level TCP data reading

## 🎯 **Root Cause Analysis**

### **Kemungkinan Penyebab:**

1. **Godot 4.x StreamPeerTCP Bug**
   - Compatibility issue dengan Windows TCP stack
   - Buffer management internal yang corrupt
   - Regression dari Godot 3.x ke 4.x

2. **Threading Issue**
   - Python menggunakan multi-threading untuk client handling
   - Godot single-thread `_process()` tidak sync dengan TCP buffer

3. **Protocol Mismatch**
   - Endianness issue (big-endian vs little-endian)
   - TCP packet fragmentation tidak di-handle dengan benar

4. **System-Level Issues**
   - Windows firewall atau antivirus interference
   - TCP buffer size limitation di OS level

## 📊 **Performance Metrics**

| Metric | Target | Current |
|--------|--------|---------|
| Connection Time | < 1s | ✅ ~0.5s |
| Frame Rate | 15-30 FPS | ❌ 0 FPS |
| Latency | < 100ms | ❌ N/A (no frames) |
| Data Throughput | ~500KB/s | ❌ 0 KB/s effective |

## 🔄 **Workaround Options**

### **Option 1: UDP Socket**
**Pros**: No connection state, simpler protocol
**Cons**: No delivery guarantee, packet loss possible

### **Option 2: Named Pipes**
**Pros**: OS-level IPC, reliable on Windows
**Cons**: Platform-specific, complex implementation

### **Option 3: File-based Sharing**
**Pros**: Simple, no network issues
**Cons**: Disk I/O overhead, not real-time

### **Option 4: WebRTC**
**Pros**: Designed for real-time video streaming
**Cons**: Complex setup, requires WebRTC plugin

## 📝 **Rekomendasi untuk Development**

### **Immediate Steps:**
1. **Test di Godot 3.x** - untuk isolasi apakah ini bug Godot 4.x
2. **Test di Linux/Mac** - untuk isolasi apakah ini Windows-specific issue
3. **Implement UDP fallback** - sebagai alternative protocol
4. **Profiling TCP traffic** - menggunakan Wireshark untuk analisa packet-level

### **Long-term Solutions:**
1. **Plugin Development** - native plugin untuk video streaming
2. **Alternative Engine** - consider Unity atau Unreal untuk comparison
3. **Hybrid Approach** - Python OpenCV + web interface untuk rapid prototyping

