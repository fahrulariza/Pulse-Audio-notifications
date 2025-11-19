<div align="center">
<img src="https://upload.wikimedia.org/wikipedia/commons/9/92/Openwrt_Logo.svg" alt="OpenWrt - Bluetooth Audio di OpenWrt" width="200"/>
<br>
<img src="https://upload.wikimedia.org/wikipedia/commons/b/bf/Armbianlogo.png" alt="OpenWrt - Bluetooth Audio di Armbian" width="200"/>

![License](https://img.shields.io/github/license/fahrulariza/Pulse-Audio-notifications)
[![GitHub All Releases](https://img.shields.io/github/downloads/fahrulariza/Pulse-Audio-notifications/total)](https://github.com/fahrulariza/Pulse-Audio-notifications/releases)
![Total Commits](https://img.shields.io/github/commit-activity/t/fahrulariza/Pulse-Audio-notifications)
![Top Language](https://img.shields.io/github/languages/top/fahrulariza/Pulse-Audio-notifications)
[![Open Issues](https://img.shields.io/github/issues/fahrulariza/Pulse-Audio-notifications)](https://github.com/fahrulariza/Pulse-Audio-notifications/issues)

<h1>Notifikasi adzan by aladhan.com menggunakan PulseAudio di Openwrt / Armbian</h1>
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

### 5.1 Penjelasan File Script utama

| No | Nama File | Deskripsi |
|----|-----------|------------|
| 1 | audio-adzan.sh |------------|
| 2 | audio-adzan-01.sh | Subuh |
| 3 | audio-adzan-02.sh | Dzuhur/Ashar |
| 4 | audio-adzan-03.sh | Maghrib |
| 5 | audio-adzan-04.sh | Isya |
| 6 | audio-adzan.config | konfigurasi |
| 7 | generate_quran_durations.sh | Generated time Al-Quran |

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

## 🔧 Langkah 6: Percobaan

### 6.1.a Generate waktu dan nama setiap file wav di folder `/www/audio/al-quran/`
```
cd /www/adzan-script/
./generate_quran_durations.sh
```

### 6.1.b Expected Output
script ini dijalanakan cukup 1 kali jika tidak ada penambahan atau perubahan file di dalam folder al-quran
Jika berhasil, Anda akan melihat output sampai selesai seperti:
```
Wed Nov 19 23:47:55 WIB 2025: [INFO] Memulai generate_quran_durations.sh
Wed Nov 19 23:47:55 WIB 2025: [DEBUG] Output sox mentah untuk Page001.wav: '00:00:28.08'
Wed Nov 19 23:47:55 WIB 2025: [DEBUG] Durasi integer untuk Page001.wav: '28'
Wed Nov 19 23:47:55 WIB 2025: [INFO] Memproses Page001.wav: 28s
Wed Nov 19 23:47:55 WIB 2025: [DEBUG] Output sox mentah untuk Page002.wav: '00:01:36.02'
Wed Nov 19 23:47:55 WIB 2025: [DEBUG] Durasi integer untuk Page002.wav: '96'
Wed Nov 19 23:47:55 WIB 2025: [INFO] Memproses Page002.wav: 96s
Wed Nov 19 23:47:55 WIB 2025: [DEBUG] Output sox mentah untuk Page003.wav: '00:02:41.46'
Wed Nov 19 23:47:55 WIB 2025: [DEBUG] Durasi integer untuk Page003.wav: '161'
Wed Nov 19 23:47:55 WIB 2025: [INFO] Memproses Page003.wav: 161s
Wed Nov 19 23:47:55 WIB 2025: [DEBUG] Output sox mentah untuk Page004.wav: '00:03:42.78'
Wed Nov 19 23:47:55 WIB 2025: [DEBUG] Durasi integer untuk Page004.wav: '223'
Wed Nov 19 23:47:55 WIB 2025: [INFO] Memproses Page004.wav: 223s
Wed Nov 19 23:47:55 WIB 2025: [DEBUG] Output sox mentah untuk Page005.wav: '00:04:36.56'
Wed Nov 19 23:47:55 WIB 2025: [DEBUG] Durasi integer untuk Page005.wav: '277'
Wed Nov 19 23:47:55 WIB 2025: [INFO] Memproses Page005.wav: 277s
Wed Nov 19 23:47:55 WIB 2025: [DEBUG] Output sox mentah untuk Page006.wav: '00:02:01.15'
Wed Nov 19 23:47:55 WIB 2025: [DEBUG] Durasi integer untuk Page006.wav: '121'
Wed Nov 19 23:47:55 WIB 2025: [INFO] Memproses Page006.wav: 121s
Wed Nov 19 23:48:17 WIB 2025: [DEBUG] Output sox mentah untuk Page601.wav: '00:00:55.55'
Wed Nov 19 23:48:17 WIB 2025: [DEBUG] Durasi integer untuk Page601.wav: '56'
Wed Nov 19 23:48:17 WIB 2025: [INFO] Memproses Page601.wav: 56s
Wed Nov 19 23:48:17 WIB 2025: [DEBUG] Output sox mentah untuk Page602.wav: '00:01:16.26'
Wed Nov 19 23:48:17 WIB 2025: [DEBUG] Durasi integer untuk Page602.wav: '76'
Wed Nov 19 23:48:17 WIB 2025: [INFO] Memproses Page602.wav: 76s
Wed Nov 19 23:48:17 WIB 2025: [DEBUG] Output sox mentah untuk Page603.wav: '00:00:22.75'
Wed Nov 19 23:48:17 WIB 2025: [DEBUG] Durasi integer untuk Page603.wav: '23'
Wed Nov 19 23:48:17 WIB 2025: [INFO] Memproses Page603.wav: 23s
Wed Nov 19 23:48:17 WIB 2025: [DEBUG] Output sox mentah untuk Page604.wav: '00:00:47.12'
Wed Nov 19 23:48:17 WIB 2025: [DEBUG] Durasi integer untuk Page604.wav: '47'
Wed Nov 19 23:48:17 WIB 2025: [INFO] Memproses Page604.wav: 47s
Wed Nov 19 23:48:17 WIB 2025: [INFO] File durasi Al-Qur'an berhasil dibuat/diperbarui: /www/audio/al-quran/pages_per_track.json
Wed Nov 19 23:48:17 WIB 2025: [INFO] generate_quran_durations.sh selesai
```

### 6.2.a Test Manual
Jalankan script secara manual untuk testing pengambilan jadwal:
```
cd /www/adzan-script/
./audio-adzan.sh
```

### 6.2.b Expected Output
Jika berhasil, Anda akan melihat output seperti:
```
root@open-wrt:/# /www/adzan-script/audio-adzan.sh
Wed Nov 19 23:21:49 WIB 2025: Memulai pembaruan jadwal adzan...
Wed Nov 19 23:21:49 WIB 2025: Mencoba mengambil jadwal adzan per tanggal untuk 20 hari ke depan dari API...
Wed Nov 19 23:21:49 WIB 2025: Mengambil data untuk 19 Nov 2025 dari API Aladhan (By Address with tune)...
Wed Nov 19 23:21:50 WIB 2025: Mengambil data untuk 20 Nov 2025 dari API Aladhan (By Address with tune)...
Wed Nov 19 23:21:51 WIB 2025: Mengambil data untuk 21 Nov 2025 dari API Aladhan (By Address with tune)...
Wed Nov 19 23:21:52 WIB 2025: Mengambil data untuk 22 Nov 2025 dari API Aladhan (By Address with tune)...
Wed Nov 19 23:21:53 WIB 2025: Mengambil data untuk 23 Nov 2025 dari API Aladhan (By Address with tune)...
Wed Nov 19 23:21:53 WIB 2025: Mengambil data untuk 24 Nov 2025 dari API Aladhan (By Address with tune)...
Wed Nov 19 23:21:54 WIB 2025: Mengambil data untuk 25 Nov 2025 dari API Aladhan (By Address with tune)...
Wed Nov 19 23:21:55 WIB 2025: Mengambil data untuk 26 Nov 2025 dari API Aladhan (By Address with tune)...
Wed Nov 19 23:21:56 WIB 2025: Mengambil data untuk 27 Nov 2025 dari API Aladhan (By Address with tune)...
Wed Nov 19 23:21:57 WIB 2025: Mengambil data untuk 28 Nov 2025 dari API Aladhan (By Address with tune)...
Wed Nov 19 23:21:58 WIB 2025: Mengambil data untuk 29 Nov 2025 dari API Aladhan (By Address with tune)...
Wed Nov 19 23:21:59 WIB 2025: Mengambil data untuk 30 Nov 2025 dari API Aladhan (By Address with tune)...
Wed Nov 19 23:22:00 WIB 2025: Mengambil data untuk 01 Dec 2025 dari API Aladhan (By Address with tune)...
Wed Nov 19 23:22:01 WIB 2025: Mengambil data untuk 02 Dec 2025 dari API Aladhan (By Address with tune)...
Wed Nov 19 23:22:02 WIB 2025: Mengambil data untuk 03 Dec 2025 dari API Aladhan (By Address with tune)...
Wed Nov 19 23:22:03 WIB 2025: Mengambil data untuk 04 Dec 2025 dari API Aladhan (By Address with tune)...
Wed Nov 19 23:22:04 WIB 2025: Mengambil data untuk 05 Dec 2025 dari API Aladhan (By Address with tune)...
Wed Nov 19 23:22:05 WIB 2025: Mengambil data untuk 06 Dec 2025 dari API Aladhan (By Address with tune)...
Wed Nov 19 23:22:05 WIB 2025: Mengambil data untuk 07 Dec 2025 dari API Aladhan (By Address with tune)...
Wed Nov 19 23:22:06 WIB 2025: Mengambil data untuk 08 Dec 2025 dari API Aladhan (By Address with tune)...
Wed Nov 19 23:22:07 WIB 2025: Jadwal adzan untuk 20 hari berhasil diperbarui dan disimpan ke /www/prayer_schedule.json.
Wed Nov 19 23:22:07 WIB 2025: Data waktu sholat berhasil diperoleh. Menghapus semua job 'at' yang ada...
Wed Nov 19 23:22:07 WIB 2025: Job 'at' yang lama telah dihapus dan akan dijadwalkan ulang.
--- Waktu Adzan Hari Ini ---
Imsak:   03:38
Subuh:   03:48
Terbit:  05:05
Dzuhur:  11:21
Ashar:   14:42
Maghrib: 17:31
Sunset:  17:28
Isya:    18:44
Tengah Malam: 22:40
----------------------------
Wed Nov 19 23:22:08 WIB 2025: Notifikasi Imsak tidak diaktifkan.
Wed Nov 19 23:22:08 WIB 2025: Waktu adzan Subuh (03:38) sudah lewat hari ini.
Wed Nov 19 23:22:08 WIB 2025: [DEBUG - audio-adzan.sh] Hari ini bukan Jumat. Menjadwalkan Dzuhur 10 menit lebih awal.
Wed Nov 19 23:22:08 WIB 2025: Waktu adzan Dzuhur (11:11) sudah lewat hari ini.
Wed Nov 19 23:22:08 WIB 2025: Waktu adzan Ashar (14:32) sudah lewat hari ini.
Wed Nov 19 23:22:08 WIB 2025: Waktu adzan Maghrib (17:01) sudah lewat hari ini.
Wed Nov 19 23:22:08 WIB 2025: Waktu adzan Isya (18:34) sudah lewat hari ini.
root@open-wrt:/# 
```

## ⏰ Langkah 7: Otomatisasi dengan Cron/scheduled Tasks

### 7.1 Edit Crontab
```
crontab -e
```

### 7.2 Tambahkan UPDATE JADWAL ADZAN SHOLAT
```
# ======= UPDATE JADWAL ADZAN SHOLAT =========
56 1,2,16,23 * * * rm -f /tmp/audio-adzan.log # hapus log audio-adzan.log
56 1,2,16,23 * * * rm -f /var/log/audio-adzan.log # hapus log audio-adzan.log
57 1,2,16,23 * * * /www/adzan-script/audio-adzan.sh >> /tmp/audio-adzan.log 2>&1
#=============================================
```

## 🐛 Langkah 8: Troubleshooting

### 8.1 Error Umum dan Solusi

Error: `"File konfigurasi tidak ditemukan"`
- Pastikan file konfigurasi ada di direktori yang sama dengan script
- Pastikan nama file sesuai (termasuk ekstensi .txt)

Error: `"Tidak ada respons dari API"`
- Periksa koneksi internet router
- Pastikan API valid dari [aladhan.com](https://aladhan.com/)

Error: `"File audio tidak ditemukan"`
- Periksa struktur direktori audio
- Pastikan semua file WAV sudah diupload

Error: `PulseAudio connection refused`
- Pastikan PulseAudio Terinstall dengan baik. Tutorial install [Pulseaudio](https://github.com/fahrulariza/OpenWRT-Pulse-Audio)
- Pastikan PulseAudio berjalan: `pulseaudio --start`
- Cek user permissions
