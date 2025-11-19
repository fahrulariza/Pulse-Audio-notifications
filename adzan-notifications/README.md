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

# Lokasi file audio adzan standar Anda
AUDIO_ADZAN_DEFAULT="/www/audio/adzan.wav"
# Lokasi file audio adzan khusus untuk Subuh
AUDIO_ADZAN_FAJR="/www/audio/adzan2.wav"
# Lokasi file audio doa setelah adzan
AUDIO_SETELAH_ADZAN="/www/audio/adzan-doa_sesudah_adzan.wav"

# Durasi file audio adzan dalam detik untuk penjadwalan doa
DURATION_ADZAN_DEFAULT_SECONDS=180 # Durasi adzan.wav (2 menit 13 detik)
DURATION_ADZAN_FAJR_SECONDS=247 # Durasi adzan2.wav (3 menit 07 detik)

AUDIO_ADZAN_JUMAT="/www/audio/adzan/adzan_jumat.wav"

# --- PENTING: Variabel path untuk Al-Qur'an dan state file ---
# Lokasi direktori tempat menyimpan file audio Al-Qur'an (misal: Page001.wav, Page002.wav, dst.)
AUDIO_DIR_QURAN="/www/audio/al-quran"
# Lokasi file untuk menyimpan halaman terakhir Al-Qur'an yang diputar
QURAN_STATE_FILE="/www/assisten/laporan/quran_state.txt" # Disarankan menggunakan nama file yang unik
# Lokasi file JSON yang berisi durasi setiap halaman Al-Qur'an
PAGES_PER_TRACK_FILE="/www/audio/al-quran/pages_per_track.json"

# --- Pengaturan Volume Audio ---
# Volume untuk pemutaran audio Adzan (nilai antara 0 dan 65536, 65536 adalah 100%)
# Ini adalah variabel 'AUDIO_VOLUME' yang Anda definisikan di bawah.
# Saya mengubahnya menjadi VOLUME_ADZAN agar konsisten dengan nama variabel di skrip adzan.
VOLUME_ADZAN=65536

# Volume untuk pemutaran audio Al-Qur'an (bisa lebih tinggi dari 65536 jika PulseAudio diizinkan)
VOLUME_QURAN=50536

# Volume untuk audio lain-lain (doa, imsak, iqamah)
VOLUME_AUDIO_LAIN=55536 # Contoh nilai, sesuaikan jika perlu

# --- Konfigurasi Iqamah ---
ADZAN_IQAMAH_ENABLED="ya"
# Jeda waktu antara adzan dan iqamah (dalam detik)
# ADZAN_IQAMAH=13 # Ini dalam menit, skrip expecting detik. Saya ubah menjadi ADZAN_IQAMAH_DELAY_SECONDS
ADZAN_IQAMAH_DELAY_SECONDS=780 # 13 menit * 60 detik/menit
# Lokasi file audio Iqamah
AUDIO_IQAMAH="/www/audio/adzan-iqamah.wav" # Perbaiki nama variabelnya menjadi AUDIO_IQAMAH (sebelumnya AUDIO_ADZAN_IQAMAH)
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
AUDIO_IMSAK="/www/audio/imsak.wav"
# Volume untuk pemutaran audio Imsak (nilai antara 0 dan 65536, 65536 adalah 100%)
IMSAK_VOLUME=65536

# --- Lokasi File Log ---
LOG_FILE="/var/log/audio-adzan.log"
```

### 3.2 Penjelasan Konfigurasi API dan Lokasi

| No | Parameter | Penjelasan |
|----|-----------|------------|
| 1 | **API** | Dapatkan dari [Tomorrow.io](https://aladhan.com/prayer-times-api) |
| 2 | **CITY** | Kota lokasi Anda |
| 3 | **COUNTRY** | Negara |
| 4 | **METHOD** | Sesuaikan volume sesuai kebutuhan (0-65536) |

| No | Parameter | Penjelasan |
|----|-----------|------------|
| 1 | **AUDIO_al-quran** | Lokasi Utama Audio al-quran [`Cuaca`](https://github.com/fahrulariza/Pulse-Audio-notifications/tree/master/www/audio/al-quran) |
| 2 | **AUDIO_adzan-sound** | FILE Audio untuk intro adzan [`lapor_berita_cuaca.wav`](https://github.com/fahrulariza/Pulse-Audio-notifications/blob/master/www/audio/adzan-sound) |

## 🎵 Langkah 4: File Audio yang Diperlukan

### 4.1 File Audio Utama

Letakkan file berikut di [`/www/audio/cuaca/`](https://github.com/fahrulariza/Pulse-Audio-notifications/tree/master/www/audio/cuaca):

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
- untuk file bisa jadi Referensi di ambil [disini](https://github.com/fahrulariza/Pulse-Audio-notifications/tree/master/www) merupakan hasil dari suara AI

## 🎵 Langkah 5: Script Utama

### 5.1 Buat File Script (`audio_berita-cuaca.sh`)
Simpan script utama yang telah di unduh di `/www/assisten/laporan/Pulse-Audio-weather-notifications.sh`

### 5.2 Berikan Hak Akses Eksekusi
```
dos2unix /www/assisten/laporan/Pulse-Audio-weather-notifications.sh
dos2unix /www/assisten/laporan/Pulse-Audio-weather-notifications.txt
chmod +x /www/assisten/laporan/Pulse-Audio-weather-notifications.sh
```

## 🔧 Langkah 6: Testing

### 6.1 Test Manual
Jalankan script secara manual untuk testing:
```
cd /www/assisten/laporan/
./Pulse-Audio-weather-notifications.sh
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
