<div align="center">
<img src="https://upload.wikimedia.org/wikipedia/commons/9/92/Openwrt_Logo.svg" alt="OpenWrt - Bluetooth Audio di OpenWrt" width="200"/>
<br>
<img src="https://upload.wikimedia.org/wikipedia/commons/b/bf/Armbianlogo.png" alt="OpenWrt - Bluetooth Audio di Armbian" width="200"/>

![License](https://img.shields.io/github/license/fahrulariza/Pulse-Audio-notifications)
[![GitHub All Releases](https://img.shields.io/github/downloads/fahrulariza/Pulse-Audio-notifications/total)](https://github.com/fahrulariza/Pulse-Audio-notifications/releases)
![Total Commits](https://img.shields.io/github/commit-activity/t/fahrulariza/Pulse-Audio-notifications)
![Top Language](https://img.shields.io/github/languages/top/fahrulariza/Pulse-Audio-notifications)
[![Open Issues](https://img.shields.io/github/issues/fahrulariza/Pulse-Audio-notifications)](https://github.com/fahrulariza/Pulse-Audio-notifications/issues)

<h1>Notifikasi Cuaca menggunakan PulseAudio di Openwrt / Armbian</h1>
<p>Kelola router OpenWrt dan Armbian Anda dengan mudah dan kreatif!</p>
</div>

Instalasi dan Konfigurasi Notifikasi Cuaca menggunakan PulseAudio
Panduan ini menjelaskan langkah-langkah untuk menginstal dan mengkonfigurasi layanan audio di OpenWrt / Armbian.

<p>
  
## 📋 Persyaratan Sistem
  
<br>

1. Router dengan OpenWrt / Armbian
2. Koneksi internet aktif
4. Package curl
5. Package dos2unix
6. Pulseaudio terinstall dan berfungsi dengan baik. [Tutorial install dan konfigurasi Pulseaudio](https://github.com/fahrulariza/OpenWRT-Pulse-Audio)

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
### 3.1 Buat File Konfigurasi (Pulse-Audio-weather-notifications.txt)

**Simpan file berikut di /www/assisten/Pulse-Audio-weather-notifications.txt:**<br>

```
# Konfigurasi untuk Script Audio Berita Cuaca
# File: Pulse-Audio-weather-notifications.txt
# github: https://github.com/fahrulariza

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

| No | Parameter | Penjelasan |
|----|-----------|------------|
| 1 | **API_KEY** | Dapatkan dari [Tomorrow.io](https://www.tomorrow.io/) |
| 2 | **LAT/LON** | Koordinat latitude dan longitude lokasi Anda |
| 3 | **LOCATION_NAME** | Nama lokasi untuk laporan audio |
| 4 | **VOLUME** | Sesuaikan volume sesuai kebutuhan (0-65536) |

## 🎵 Langkah 4: File Audio yang Diperlukan

### 4.1 File Audio Utama
Letakkan file berikut di `/www/audio/cuaca/`:

| No | Nama File | Deskripsi |
|----|-----------|------------|
| 1 | **lapor_berita_cuaca.wav** | Intro pembuka laporan cuaca |

### 4.2 File Audio Kondisi Cuaca
Letakkan di `/www/audio/cuaca/kondisi/`:

| No | Nama File | Kode Cuaca | Deskripsi |
|----|-----------|------------|------------|
| 1 | **cerah.wav** | 1000 | Kondisi cerah |
| 2 | **berawan.wav** | 1001 | Kondisi berawan |
| 3 | **sebagian_besar_cerah.wav** | 1100 | Sebagian besar cerah |
| 4 | **sebagian_besar_berawan.wav** | 1101 | Sebagian besar berawan |
| 5 | **sebagian_berawan.wav** | 1102 | Sebagian berawan |
| 6 | **mendung.wav** | 2000 | Kondisi mendung |
| 7 | **mendung_sebagian.wav** | 2100 | Mendung sebagian |
| 8 | **gerimis.wav** | 4000 | Hujan gerimis |
| 9 | **hujan.wav** | 4001 | Hujan normal |
| 10 | **hujan_ringan.wav** | 4200 | Hujan ringan |
| 11 | **hujan_lebat.wav** | 4201 | Hujan lebat |
| 12 | **salju.wav** | 5000 | Salju |
| 13 | **salju_ringan.wav** | 5001 | Salju ringan |
| 14 | **salju_lebat.wav** | 5100 | Salju lebat |
| 15 | **hujan_es.wav** | 6000 | Hujan es |
| 16 | **hujan_es_ringan.wav** | 6001 | Hujan es ringan |
| 17 | **hujan_es_lebat.wav** | 6200 | Hujan es lebat |
| 18 | **kabut.wav** | 7000 | Kabut |
| 19 | **kabut_tipis.wav** | 7101 | Kabut tipis |
| 20 | **kabut_lebat.wav** | 7102 | Kabut lebat |
| 21 | **badai_petir.wav** | 8000 | Badai petir |
| 22 | **default_unknown.wav** | * | Kondisi tidak diketahui |

### 4.3 File Audio Tips
Letakkan di `/www/audio/cuaca/tips/`:

| No | Nama File | Kode Cuaca | Deskripsi |
|----|-----------|------------|------------|
| 1 | **tip_cerah.wav** | 1000 | Tips untuk cuaca cerah |
| 2 | **tip_berawan.wav** | 1001 | Tips untuk cuaca berawan |
| 3 | **tip_sebagian_besar_cerah.wav** | 1100 | Tips sebagian besar cerah |
| 4 | **tip_sebagian_besar_berawan.wav** | 1101 | Tips sebagian besar berawan |
| 5 | **tip_sebagian_berawan.wav** | 1102 | Tips sebagian berawan |
| 6 | **tip_mendung.wav** | 2000 | Tips untuk cuaca mendung |
| 7 | **tip_mendung_sebagian.wav** | 2100 | Tips mendung sebagian |
| 8 | **tip_gerimis.wav** | 4000 | Tips untuk gerimis |
| 9 | **tip_hujan.wav** | 4001 | Tips untuk hujan |
| 10 | **tip_hujan_ringan.wav** | 4200 | Tips hujan ringan |
| 11 | **tip_hujan_lebat.wav** | 4201 | Tips hujan lebat |
| 12 | **tip_salju.wav** | 5000 | Tips untuk salju |
| 13 | **tip_salju_ringan.wav** | 5001 | Tips salju ringan |
| 14 | **tip_salju_lebat.wav** | 5100 | Tips salju lebat |
| 15 | **tip_hujan_es.wav** | 6000 | Tips untuk hujan es |
| 16 | **tip_hujan_es_ringan.wav** | 6001 | Tips hujan es ringan |
| 17 | **tip_hujan_es_lebat.wav** | 6200 | Tips hujan es lebat |
| 18 | **tip_kabut.wav** | 7000 | Tips untuk kabut |
| 19 | **tip_kabut_tipis.wav** | 7101 | Tips kabut tipis |
| 20 | **tip_kabut_lebat.wav** | 7102 | Tips kabut lebat |
| 21 | **tip_badai_petir.wav** | 8000 | Tips untuk badai petir |
| 22 | **tip_default.wav** | * | Tips default |

### 4.4 File Audio Angka
Letakkan di `/www/audio/angka/`:

| No | Kategori | File yang Diperlukan | Deskripsi |
|----|-----------|------------|------------|
| 1 | **Angka Dasar** | 0.wav sampai 9.wav | Angka 0 hingga 9 |
| 2 | **Angka Belasan** | 10.wav sampai 19.wav | Angka 10 hingga 19 |
| 3 | **Puluhan** | 20.wav, 30.wav, ..., 90.wav | Kelipatan 10 (20, 30, ..., 90) |
| 4 | **Ratusan** | 100.wav, 200.wav, ..., 900.wav | Kelipatan 100 (100, 200, ..., 900) |
| 5 | **Ribuan** | 1000.wav, 2000.wav, ..., 9000.wav | Kelipatan 1000 (1000, 2000, ..., 9000) |
| 6 | **Kata Bantu** | koma.wav | Untuk bilangan desimal |
| 7 | **Intro Suhu** | introsuhu.wav | Pembaca suhu |
| 8 | **Satuan** | derajat_celsius.wav | Akhiran derajat celsius |

**Catatan:** 
- Semua file harus dalam format **WAV**
- Pastikan kualitas audio jelas dan tidak ada noise
- Durasi setiap file disarankan 1-3 detik untuk efisiensi
- File tips tidak akan diputar pada malam hari (setelah jam 17:00 sampai 06:00)

## 🎵 Langkah 5: Script Utama

### 5.1 Buat File Script (`audio_berita-cuaca.sh`)
Simpan script utama yang telah di unduh di `/www/assisten/Pulse-Audio-weather-notifications.sh`

### 5.2 Berikan Hak Akses Eksekusi
```
dos2unix /www/assisten/Pulse-Audio-weather-notifications.sh
dos2unix /www/assisten/Pulse-Audio-weather-notifications.txt
chmod +x /www/assisten/Pulse-Audio-weather-notifications.sh
```

## 🔧 Langkah 6: Testing

### 6.1 Test Manual
Jalankan script secara manual untuk testing:
```
cd /www/assisten/
./Pulse-Audio-weather-notifications.sh
```

### 6.2 Expected Output
Jika berhasil, Anda akan melihat output seperti:
```
Debug: Memuat konfigurasi dari: /www/assisten/Pulse-Audio-weather-notifications.txt
Debug: Waktu siang (14:00), volume diatur ke 62768.
Debug: Mencoba mengambil data dari Tomorrow.io: https://api.tomorrow.io/v4/timelines?...
Debug: Suhu: 28.5
Debug: Kode Cuaca: 1001
Info: weatherCode tidak berubah (1001) dan bukan waktu wajib putar. Tidak memutar notifikasi.
```

## ⏰ Langkah 7: Otomatisasi dengan Cron/scheduled Tasks

### 7.1 Edit Crontab
```
crontab -e
```

### 7.2 Tambahkan Jadwal
```
# notifikasi cuaca otomatis setiap 15 menit
*/15 * * * * /www/assisten/laporan/Pulse-Audio-weather-notifications.sh >/dev/null 2>&1
```

## 🐛 Langkah 8: Troubleshooting

### 8.1 Error Umum dan Solusi

Error: `"File konfigurasi tidak ditemukan"`
- Pastikan file konfigurasi ada di direktori yang sama dengan script
- Pastikan nama file sesuai (termasuk ekstensi .txt)

Error: `"Tidak ada respons dari API"`
- Periksa koneksi internet router
- Pastikan API key valid dari [Tomorrow.io](https://www.tomorrow.io/)

Error: `"File audio tidak ditemukan"`
- Periksa struktur direktori audio
- Pastikan semua file WAV sudah diupload

Error: `PulseAudio connection refused`
- Pastikan PulseAudio Terinstall dengan baik. Tutorial install [Pulseaudio](https://github.com/fahrulariza/OpenWRT-Pulse-Audio)
- Pastikan PulseAudio berjalan: `pulseaudio --start`
- Cek user permissions
