<div align="center">
<img src="https://upload.wikimedia.org/wikipedia/commons/9/92/Openwrt_Logo.svg" alt="OpenWrt - Bluetooth Audio di OpenWrt" width="200"/>
<br>
<img src="https://upload.wikimedia.org/wikipedia/commons/b/bf/Armbianlogo.png" alt="OpenWrt - Bluetooth Audio di Armbian" width="200"/>

![License](https://img.shields.io/github/license/fahrulariza/Pulse-Audio-notifications)
[![GitHub All Releases](https://img.shields.io/github/downloads/fahrulariza/Pulse-Audio-notifications/total)](https://github.com/fahrulariza/Pulse-Audio-notifications/releases)
![Total Commits](https://img.shields.io/github/commit-activity/t/fahrulariza/Pulse-Audio-notifications)
![Top Language](https://img.shields.io/github/languages/top/fahrulariza/Pulse-Audio-notifications)
[![Open Issues](https://img.shields.io/github/issues/fahrulariza/Pulse-Audio-notifications)](https://github.com/fahrulariza/Pulse-Audio-notifications/issues)

<h1>Notifikasi ADZAN by aladhan.com menggunakan PulseAudio di Openwrt / Armbian</h1>
<p>Kelola router OpenWrt dan Armbian Anda dengan mudah dan kreatif!</p>
</div>

Instalasi dan Konfigurasi Notifikasi suara Adzan dari aladhan.com menggunakan PulseAudio
Panduan ini menjelaskan langkah-langkah untuk menginstal dan mengkonfigurasi layanan audio di OpenWrt / Armbian.

<p>
  
## 📋 Persyaratan Sistem
  
<br>

1. Router dengan OpenWrt / Armbian
2. Koneksi internet aktif
4. Package curl
5. Package atq
6. Package dos2unix
7. Pulseaudio terinstall dan berfungsi dengan baik. [Tutorial install dan konfigurasi Pulseaudio](https://github.com/fahrulariza/OpenWRT-Pulse-Audio)

## 📁 Langkah 2: Struktur Direktori

Buat struktur direktori berikut di router OS OpenWrt / Armbian kamu seperti ini:<br>

```
/www/
├── adzan-script/
│   ├── audio-adzan.sh/
│   ├── audio-adzan-01.sh
│   ├── audio-adzan-02.sh
│   ├── audio-adzan-03.sh
│   ├── audio-adzan-04.sh
│   ├── audio-adzan.config
│   └── generate_quran_durations.sh
|
├── audio/
│   ├── al-quran/
│   │   ├── Page001.wav/
│   │   ├── Page002.wav/
│   │   ├── Page003.wav/
│   │   ├── etc../
│   │   └── pages_per_track.json/
|   |
│   └── adzan-sound/
│   │   ├── adzan.wav/
│   │   ├── adzan2.wav/
│   │   ├── adzan_jumat.wav/
│   │   ├── adzan-iqamah.wav/
│   │   ├── adzan-iqamah02.wav/
│   │   ├── imsak.wav/
│   │   └── adzan-doa_sesudah_adzan.wav/
```

<br>
Perintah untuk Membuat Direktori:

```
mkdir -p /www/adzan-script
mkdir -p /www/audio/al-quran
mkdir -p /www/audio/adzan-sound
```
<br>

## 📄 Langkah 3: File Konfigurasi

<br>

### 3.1 Buat File Konfigurasi (audio-adzan.config)

**Simpan file berikut di /www/adzan-script/audio-adzan.config:**<br>

```
# --- Konfigurasi Lokasi dan Metode Adzan ---
CITY="Seruyan"
COUNTRY="Indonesia"
METHOD="20" # KEMENAG - Kementerian Agama Republik Indonesia

# Lokasi file audio adzan standar
AUDIO_ADZAN_DEFAULT="/www/audio/adzan-sound/adzan.wav"
# Lokasi file audio adzan khusus untuk Subuh
AUDIO_ADZAN_FAJR="/www/audio/adzan-sound/adzan2.wav"
# Lokasi file audio doa setelah adzan
AUDIO_SETELAH_ADZAN="/www/audio/adzan-sound/adzan-doa_sesudah_adzan.wav"

# Durasi file audio adzan dalam detik untuk penjadwalan doa
DURATION_ADZAN_DEFAULT_SECONDS=180 # Durasi adzan.wav (2 menit 13 detik)
DURATION_ADZAN_FAJR_SECONDS=247 # Durasi adzan2.wav (3 menit 07 detik)

AUDIO_ADZAN_JUMAT="/www/audio/adzan-sound/adzan_jumat.wav"

# --- PENTING: Variabel path untuk Al-Qur'an dan state file ---
# Lokasi direktori tempat menyimpan file audio Al-Qur'an (misal: Page001.wav, Page002.wav, dst.)
AUDIO_DIR_QURAN="/www/audio/al-quran"
# Lokasi file untuk menyimpan halaman terakhir Al-Qur'an yang diputar
QURAN_STATE_FILE="/www/adzan-script/quran_state.txt"
# Lokasi file JSON yang berisi durasi setiap halaman Al-Qur'an
PAGES_PER_TRACK_FILE="/www/audio/al-quran/pages_per_track.json"

# --- Pengaturan Volume Audio ---
# Volume untuk pemutaran audio Adzan (nilai antara 0 dan 65536, 65536 adalah 100%)
# Ini adalah variabel 'AUDIO_VOLUME' yang Anda definisikan di bawah.
# Saya mengubahnya menjadi VOLUME_ADZAN agar konsisten dengan nama variabel di skrip adzan.
VOLUME_ADZAN=65536

# Volume untuk pemutaran audio Al-Qur'an (maximal 65536)
VOLUME_QURAN=50536

# Volume untuk audio lain-lain (doa, imsak, iqamah)
VOLUME_AUDIO_LAIN=55536 # sesuaikan jika perlu

# --- Konfigurasi Iqamah ---
ADZAN_IQAMAH_ENABLED="ya"
# Jeda waktu antara adzan dan iqamah (dalam detik)
ADZAN_IQAMAH_DELAY_SECONDS=780 # 13 menit * 60 detik/menit
# Lokasi file audio Iqamah
AUDIO_IQAMAH="/www/audio/adzan-sound/adzan-iqamah.wav" # Perbaiki nama variabelnya menjadi AUDIO_IQAMAH (sebelumnya AUDIO_ADZAN_IQAMAH)
#Volume Suara Iqamah
VOLUME_IQAMAH=55536

# --- Konfigurasi Jadwal Sholat ---
# Lokasi file untuk menyimpan jadwal adzan 10 hari
SCHEDULE_FILE="/www/prayer_schedule.json" 
# Jumlah hari ke depan yang akan diambil jadwalnya
DAYS_AHEAD=20

# --- Selisih Waktu Adzan (dalam menit) ---
# Urutan: Imsak, Fajr, Sunrise, Dhuhr, Asr, Maghrib, Sunset, Isha, Midnight
TUNE_IMSAK=2
TUNE_FAJR=2
TUNE_SUNRISE=-3
TUNE_DHUHR=5
TUNE_ASR=2
TUNE_MAGHRIB=7
TUNE_SUNSET=4
TUNE_ISHA=7
TUNE_MIDNIGHT=-36

# --- Konfigurasi Notifikasi Imsak ---
# Aktifkan notifikasi Imsak (ya/tidak)
NOTIF_IMSAK="tidak"
# Waktu jeda notifikasi Imsak sebelum Adzan Subuh (dalam menit)
IMSAK_OFFSET_MINUTES=12
# Lokasi file audio Imsak
AUDIO_IMSAK="/www/audio/adzan-sound/imsak.wav"
# Volume untuk pemutaran audio Imsak (nilai antara 0 dan 65536, 65536 adalah 100%)
IMSAK_VOLUME=65536

# --- Lokasi File Log ---
LOG_FILE="/var/log/audio-adzan.log"
```

### 3.2 Penjelasan Konfigurasi API dan Lokasi

| No | Parameter | Penjelasan |
|----|-----------|------------|
| 1 | **API** | Dapatkan dari [aladhan.com](https://aladhan.com/) |
| 2 | **CITY** | Kota lokasi Anda |
| 3 | **COUNTRY** | Negara |
| 4 | **METHOD** | Sesuaikan volume sesuai kebutuhan (0-65536) |

| No | Parameter | Penjelasan |
|----|-----------|------------|
| 1 | **AUDIO_al-quran** | Lokasi Utama Audio al-quran [`al-quran`](https://github.com/fahrulariza/Pulse-Audio-notifications/tree/master/www/audio/al-quran) |
| 2 | **AUDIO_adzan-sound** | FILE Audio untuk intro adzan [`adzan`](https://github.com/fahrulariza/Pulse-Audio-notifications/blob/master/www/audio/adzan-sound) |

## 🎵 Langkah 4: File Audio yang Diperlukan

### 4.1 File Audio Utama adzan

Letakkan file adzan difolder adzan-sound berikut di [`/www/audio/adzan-sound/`](https://github.com/fahrulariza/Pulse-Audio-notifications/tree/master/www/audio/adzan-sound):

| No | Nama File | Deskripsi |
|----|-----------|------------|
| 1 | **adzan.wav** | audio adzan standar |
| 2 | **adzan2.wav** | audio adzan khusus untuk Subuh |
| 3 | **adzan-doa_sesudah_adzan.wav** | audio doa setelah adzan |

### 4.2 File Audio bacaan Al-Quran
Letakkan file al-quran difolder al-quran berikut di [`/www/audio/al-quran/`](https://github.com/fahrulariza/Pulse-Audio-notifications/tree/master/www/audio/al-quran):

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

**Catatan:** 
- Semua file harus dalam format **WAV**
- Pastikan kualitas audio jelas dan tidak ada noise
- untuk file bisa jadi Referensi di ambil [disini](https://github.com/fahrulariza/Pulse-Audio-notifications/tree/master/www)

## 🎵 Langkah 5: Script Utama

### 5.1 Penjelasan File Script

| No | Nama File | Deskripsi |
|----|-----------|------------|
| 1 | audio-adzan.sh |------------|
| 2 | audio-adzan-01.sh |------------|
| 3 | audio-adzan-02.sh |------------|
| 4 | audio-adzan-03.sh |------------|
| 5 | audio-adzan-04.sh |------------|
| 6 | audio-adzan.config |------------|
| 7 | generate_quran_durations.sh |------------|

Simpan semua script utama yang telah di unduh di `/www/adzan-script/`

### 5.2 Berikan Hak Akses Eksekusi
```
dos2unix /www/adzan-script/audio-adzan.sh
dos2unix /www/adzan-script/audio-adzan-01.sh
dos2unix /www/adzan-script/audio-adzan-02.sh
dos2unix /www/adzan-script/audio-adzan-03.sh
dos2unix /www/adzan-script/audio-adzan-04.sh
dos2unix /www/adzan-script/generate_quran_durations.sh
chmod +x /www/adzan-script/audio-adzan.sh
chmod +x /www/adzan-script/audio-adzan-01.sh
chmod +x /www/adzan-script/audio-adzan-02.sh
chmod +x /www/adzan-script/audio-adzan-03.sh
chmod +x /www/adzan-script/audio-adzan-04.sh
chmod +x /www/adzan-script/generate_quran_durations.sh

```

## 🔧 Langkah 6: Testing

### 6.1 Test Manual
Jalankan script secara manual untuk testing pengambilan jadwal:
```
cd /www/adzan-script/
./audio-adzan.sh
```

### 6.2 Expected Output
Jika berhasil, Anda akan melihat output seperti:
```
root@open-wrt:/# /www/assisten/laporan/audio_berita-cuaca.sh
Debug: Memuat konfigurasi dari: /www/assisten/laporan/audio_berita-cuaca.txt
Debug: Waktu saat ini (22:28) bukan waktu wajib putar.
Debug: Kode Cuaca Terakhir Tersimpan: ''
Debug: Kode Cuaca Saat Ini: '2100'
Info: weatherCode baru (2100) disimpan ke /www/assisten/laporan/last_weather_code.txt.
Debug: Tips tidak akan diputar karena ini adalah waktu malam/pagi.
Cuaca di Rantau Pulut saat ini mendung sebagian, dengan suhu 24.2 derajat Celsius.
Debug: File audio suhu:   /www/audio/angka/20.wav /www/audio/angka/4.wav /www/audio/angka/koma.wav /www/audio/angka/2.wav
Mencoba memutar urutan audio...
Urutan file: /www/audio/cuaca/lapor_berita_cuaca.wav /www/audio/cuaca/kondisi/mendung_sebagian.wav /www/audio/angka/introsuhu.wav   /www/audio/angka/20.wav /www/audio/angka/4.wav /www/audio/angka/koma.wav /www/audio/angka/2.wav /www/audio/angka/derajat_celsius.wav 
Memutar: /www/audio/cuaca/lapor_berita_cuaca.wav
Tue Oct 14 22:28:36 WIB 2025: Memeriksa status audio stream...
Tue Oct 14 22:28:36 WIB 2025: DETEKSI: Tidak ada audio stream .wav aktif atau semua stream .wav ditangguhkan. Memutar audio...
Memutar: /www/audio/cuaca/kondisi/mendung_sebagian.wav
Memutar: /www/audio/angka/introsuhu.wav
Memutar: /www/audio/angka/20.wav
Memutar: /www/audio/angka/4.wav
Memutar: /www/audio/angka/koma.wav
Memutar: /www/audio/angka/2.wav
Memutar: /www/audio/angka/derajat_celsius.wav
Skrip selesai dijalankan.
root@open-wrt:/# 
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
