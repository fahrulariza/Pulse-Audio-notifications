<div align="center">
<img src="https://upload.wikimedia.org/wikipedia/commons/9/92/Openwrt_Logo.svg" alt="OpenWrt - Bluetooth Audio di OpenWrt" width="200"/>
<br>
<img src="https://upload.wikimedia.org/wikipedia/commons/b/bf/Armbianlogo.png" alt="OpenWrt - Bluetooth Audio di Armbian" width="200"/>

![License](https://img.shields.io/github/license/fahrulariza/OpenWRT-Pulse-Audio)
[![GitHub All Releases](https://img.shields.io/github/downloads/fahrulariza/OpenWRT-Pulse-Audio/total)](https://github.com/fahrulariza/OpenWRT-Pulse-Audio/releases)
![Total Commits](https://img.shields.io/github/commit-activity/t/fahrulariza/OpenWRT-Pulse-Audio)
![Top Language](https://img.shields.io/github/languages/top/fahrulariza/OpenWRT-Pulse-Audio)
[![Open Issues](https://img.shields.io/github/issues/fahrulariza/OpenWRT-Pulse-Audio)](https://github.com/fahrulariza/OpenWRT-Pulse-Audio/issues)

<h1>Notifikasi Cuaca menggunakan PulseAudio di Openwrt / Armbian</h1>
<p>Kelola router OpenWrt dan Armbian Anda dengan mudah dan kreatif!</p>
</div>

Instalasi dan Konfigurasi Notifikasi Cuaca menggunakan PulseAudio
Panduan ini menjelaskan langkah-langkah untuk menginstal dan mengkonfigurasi layanan audio di OpenWrt / Armbian.

<p>
  
## 📋 Persyaratan Sistem
  
<br>
1. Router dengan OpenWrt / Armbian<br>
2. Koneksi internet aktif<br>
3. Package curl<br>
4. Pulseaudio terinstall dan berfungsi dengan baik. tutorialnya disini [here](https://github.com/fahrulariza/OpenWRT-Pulse-Audio/blob/master/README.md)
<br>

## 📁 Langkah 2: Struktur Direktori

Buat struktur direktori berikut di router OS OpenWrt / Armbian kamu seperti ini:<br>

```
/www/
├── audio/
│   ├── cuaca/
│   │   ├── kondisi/
│   │   └── tips/
│   └── angka/
└── assisten/
    └── laporan/
```
<br>
Perintah untuk Membuat Direktori:
```
mkdir -p /www/audio/cuaca/kondisi
mkdir -p /www/audio/cuaca/tips
mkdir -p /www/audio/angka
mkdir -p /www/assisten/laporan
```
<br>

## 📄 Langkah 3: File Konfigurasi

<br>
### 3.1 Buat File Konfigurasi (audio_berita-cuaca.txt)<br>
Simpan file berikut di /www/assisten/audio_berita-cuaca.txt:<br>

```
# Konfigurasi untuk Script Audio Berita Cuaca
# File: audio_berita-cuaca.txt

# --- KONFIGURASI API DAN LOKASI ---
API_KEY="dJHoRVjW6vyAbgmIkPLlevA1Q"
LAT="-1.923906"
LON="112.117940"
LOCATION_NAME="Rantau Pulut"
LAST_WEATHER_FILE="/www/assisten/laporan/last_weather_code.txt"
DEFAULT_VOLUME="62768"
NIGHT_VOLUME="32768"

# --- LOKASI FILE AUDIO ---
AUDIO_DIR="/www/audio/cuaca"
AUDIO_INTRO="${AUDIO_DIR}/lapor_berita_cuaca.wav"
AUDIO_KONDISI_DIR="${AUDIO_DIR}/kondisi"
AUDIO_TIPS_DIR="${AUDIO_DIR}/tips"
AUDIO_ANGKA_DIR="/www/audio/angka"
AUDIO_INTRO_SUHU="${AUDIO_ANGKA_DIR}/introsuhu.wav"
AUDIO_DERAJAT_CELSIUS="${AUDIO_ANGKA_DIR}/derajat_celsius.wav"
```

### 3.2 Penjelasan Konfigurasi
<br>
3.2.1 <b>API_KEY</b>: Dapatkan dari Tomorrow.io<br>
3.2.2 <b>LAT/LON</b>: Koordinat latitude dan longitude lokasi Anda<br>
3.2.3 <b>LOCATION_NAME</b>: Nama lokasi untuk laporan audio<br>
3.2.4 <b>VOLUME</b>: Sesuaikan volume sesuai kebutuhan (0-65536)<br>
