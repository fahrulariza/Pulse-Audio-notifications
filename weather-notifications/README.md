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
3. Package curl
4. Pulseaudio terinstall dan berfungsi dengan baik. tutorialnya disini [here](https://github.com/fahrulariza/OpenWRT-Pulse-Audio/blob/master/README.md)
<br>

## 📁 Struktur Direktori

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
