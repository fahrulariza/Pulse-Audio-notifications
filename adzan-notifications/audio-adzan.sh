#!/bin/sh

# --- Lokasi File Konfigurasi ---
CONFIG_FILE="/www/assisten/laporan/audio-adzan.config"

# Periksa apakah file konfigurasi ada
if [ ! -f "$CONFIG_FILE" ]; then
    echo "$(date): ERROR: File konfigurasi tidak ditemukan: $CONFIG_FILE"
    echo "Harap buat file konfigurasi dengan variabel CITY, COUNTRY, METHOD, AUDIO_ADZAN_DEFAULT, AUDIO_ADZAN_FAJR, AUDIO_SETELAH_ADZAN, DURATION_ADZAN_DEFAULT_SECONDS, DURATION_ADZAN_FAJR_SECONDS, ADZAN_IQAMAH, AUDIO_ADZAN_IQAMAH, VOLUME_ADZAN_IQAMAH, SCHEDULE_FILE, DAYS_AHEAD, TUNE_X, NOTIF_IMSAK, IMSAK_OFFSET_MINUTES, AUDIO_IMSAK, IMSAK_VOLUME, dan AUDIO_VOLUME."
    exit 1
fi

# Muat variabel dari file konfigurasi
. "$CONFIG_FILE"

# Buat string tune dari variabel konfigurasi
TUNE_PARAMS="${TUNE_IMSAK},${TUNE_FAJR},${TUNE_SUNRISE},${TUNE_DHUHR},${TUNE_ASR},${TUNE_MAGHRIB},${TUNE_SUNSET},${TUNE_ISHA},${TUNE_MIDNIGHT}"

echo "$(date): Memulai pembaruan jadwal adzan..."

# --- Fungsi untuk mengambil dan menyimpan data jadwal ---
fetch_and_save_schedule() {
    echo "$(date): Mencoba mengambil jadwal adzan per tanggal untuk $DAYS_AHEAD hari ke depan dari API..."
    
    local all_data_json="[]" # Inisialisasi array JSON kosong
    local success_count=0
    local current_timestamp=$(date +%s) # Dapatkan timestamp saat ini (detik sejak epoch)
    local one_day_in_seconds=86400 # 24 * 60 * 60

    for i in $(seq 0 $((DAYS_AHEAD-1))); do
        # Hitung timestamp untuk hari ini + i hari
        target_timestamp=$((current_timestamp + (i * one_day_in_seconds)))

        # Dapatkan tanggal dalam format DD-MM-YYYY dan 'DD Mon YYYY'
        # Menggunakan date -d @timestamp untuk BusyBox
        CURRENT_DATE=$(date -d "@$target_timestamp" +%d-%m-%Y)
        READABLE_DATE=$(date -d "@$target_timestamp" +'%d %b %Y') # Format untuk perbandingan di jq
        
        # URL API Aladhan untuk satu tanggal - MENGGUNAKAN timmingsByAddress dan parameter tune
        API_DAILY_URL="https://api.aladhan.com/v1/timingsByAddress/$CURRENT_DATE?address=${CITY},${COUNTRY}&method=${METHOD}&tune=${TUNE_PARAMS}"
        
        echo "$(date): Mengambil data untuk $READABLE_DATE dari API Aladhan (By Address with tune)..."
        TEMP_DAILY_JSON=$(wget -qO- --no-check-certificate "$API_DAILY_URL" 2>/dev/null)
        
        # Periksa apakah ada data JSON yang diterima
        if [ -z "$TEMP_DAILY_JSON" ]; then
            echo "$(date): Gagal mengambil data untuk $READABLE_DATE. Output wget kosong. Melewati hari ini."
            continue # Lanjutkan ke hari berikutnya
        fi

        # Periksa kode status API dari JSON yang diterima
        API_STATUS_CODE=$(echo "$TEMP_DAILY_JSON" | jq -r '.code')
        if [ "$API_STATUS_CODE" != "200" ]; then
            echo "$(date): API mengembalikan error untuk $READABLE_DATE: Code $API_STATUS_CODE. Melewati hari ini."
            continue # Lanjutkan ke hari berikutnya
        fi

        # Ekstrak bagian 'data' saja dari respons harian
        DAILY_DATA=$(echo "$TEMP_DAILY_JSON" | jq -c '.data')
        if [ -n "$DAILY_DATA" ]; then
            # Tambahkan data harian ke array JSON utama
            all_data_json=$(echo "$all_data_json" | jq --argjson new_data "$DAILY_DATA" '. + [$new_data]')
            success_count=$((success_count + 1))
        else
            echo "$(date): Tidak dapat mengekstrak data valid untuk $READABLE_DATE."
        fi
    done

    if [ "$success_count" -gt 0 ]; then
        # Jika setidaknya ada satu hari yang berhasil diambil, simpan ke file
        # Bungkus array data ke dalam objek JSON dengan key "data" agar sesuai format sebelumnya
        echo "{\"data\": $all_data_json}" > "$SCHEDULE_FILE"
        echo "$(date): Jadwal adzan untuk $success_count hari berhasil diperbarui dan disimpan ke $SCHEDULE_FILE."
        return 0 # Berhasil
    else
        echo "$(date): Gagal mengambil jadwal untuk hari apapun. Tidak ada file jadwal yang diperbarui."
        return 1 # Gagal total
    fi
}

# --- Coba ambil dan simpan jadwal. Jika gagal, gunakan file yang sudah ada ---
if fetch_and_save_schedule; then
    # Jika berhasil, baca jadwal hari ini dari file yang baru saja disimpan
    TODAY_READABLE_DATE=$(date +'%d %b %Y')
    PRAYER_TIMES_JSON=$(jq ".data[] | select(.date.readable == \"$TODAY_READABLE_DATE\")" "$SCHEDULE_FILE")
    
    if [ -z "$PRAYER_TIMES_JSON" ]; then
        echo "$(date): Gagal menemukan jadwal hari ini dari file yang baru diperbarui. Mencoba menggunakan jadwal cadangan yang mungkin ada."
        PRAYER_TIMES_JSON=""
    fi
else
    echo "$(date): Gagal memperbarui jadwal dari API. Menggunakan jadwal cadangan dari $SCHEDULE_FILE (jika ada)."
    # Baca data dari file yang sudah ada (jika ada)
    if [ -f "$SCHEDULE_FILE" ]; then
        TODAY_READABLE_DATE=$(date +'%d %b %Y')
        PRAYER_TIMES_JSON=$(jq ".data[] | select(.date.readable == \"$TODAY_READABLE_DATE\")" "$SCHEDULE_FILE")
    else
        echo "$(date): Tidak ada file jadwal cadangan ($SCHEDULE_FILE) yang ditemukan."
        PRAYER_TIMES_JSON="" # Setel kosong untuk memicu error exit di bawah
    fi
fi

# --- Periksa PRAYER_TIMES_JSON setelah semua upaya ---
if [ -z "$PRAYER_TIMES_JSON" ]; then
    echo "$(date): Tidak dapat memperoleh data waktu sholat yang valid dari API atau file cadangan. MEMPERTAHANKAN jadwal lama jika ada."
    exit 1
fi

# --- Jika data valid, baru hapus job 'at' yang lama dan jadwalkan yang baru ---
echo "$(date): Data waktu sholat berhasil diperoleh. Menghapus semua job 'at' yang ada..."
atq | awk '{print $1}' | xargs -r atrm &>/dev/null
echo "$(date): Job 'at' yang lama telah dihapus dan akan dijadwalkan ulang."

# Uraikan data JSON menggunakan jq
IMSAK=$(echo "$PRAYER_TIMES_JSON" | jq -r '.timings.Imsak')
FAJR=$(echo "$PRAYER_TIMES_JSON" | jq -r '.timings.Fajr')
SUNRISE=$(echo "$PRAYER_TIMES_JSON" | jq -r '.timings.Sunrise')
DHUHR=$(echo "$PRAYER_TIMES_JSON" | jq -r '.timings.Dhuhr')
ASR=$(echo "$PRAYER_TIMES_JSON" | jq -r '.timings.Asr')
MAGHRIB=$(echo "$PRAYER_TIMES_JSON" | jq -r '.timings.Maghrib')
SUNSET=$(echo "$PRAYER_TIMES_JSON" | jq -r '.timings.Sunset')
ISHA=$(echo "$PRAYER_TIMES_JSON" | jq -r '.timings.Isha')
MIDNIGHT=$(echo "$PRAYER_TIMES_JSON" | jq -r '.timings.Midnight')


echo "--- Waktu Adzan Hari Ini ---"
echo "Imsak:   $IMSAK"
echo "Subuh:   $FAJR"
echo "Terbit:  $SUNRISE"
echo "Dzuhur:  $DHUHR"
echo "Ashar:   $ASR"
echo "Maghrib: $MAGHRIB"
echo "Sunset:  $SUNSET"
echo "Isya:    $ISHA"
echo "Tengah Malam: $MIDNIGHT"
echo "----------------------------"

# --- Fungsi untuk menjadwalkan eksekusi script audio spesifik ---
schedule_adzan() {
    PRAYER_NAME="$1"
    PRAYER_TIME="$2"
    SCRIPT_TO_RUN="$3" # Path ke script audio spesifik

    CURRENT_DATE_YMD=$(date +%Y-%m-%d) # Dapatkan tanggal hari ini dalam format YYYY-MM-DD
    PRAYER_TIMESTAMP=$(date -d "$CURRENT_DATE_YMD $PRAYER_TIME" +%s) # Konversi waktu sholat ke timestamp hari ini

    CURRENT_TIMESTAMP_NOW=$(date +%s) # Timestamp saat ini

    # Hanya jadwalkan jika waktu adzan belum lewat hari ini
    if [ "$PRAYER_TIMESTAMP" -gt "$CURRENT_TIMESTAMP_NOW" ]; then
        echo "$(date): Menjadwalkan $PRAYER_NAME via $SCRIPT_TO_RUN pada $PRAYER_TIME."
        # Perintah yang akan dijalankan oleh at untuk menjalankan script audio spesifik
        echo "$SCRIPT_TO_RUN &>/dev/null" | at "$PRAYER_TIME"
    else
        echo "$(date): Waktu adzan $PRAYER_NAME ($PRAYER_TIME) sudah lewat hari ini."
    fi
}

# --- Fungsi untuk menjadwalkan notifikasi Imsak ---
schedule_imsak_notification() {
    if [ "$NOTIF_IMSAK" = "ya" ]; then
        echo "$(date): Menghitung waktu notifikasi Imsak..."
        
        # Konversi waktu Subuh (Fajr) hari ini ke timestamp
        CURRENT_DATE_YMD=$(date +%Y-%m-%d)
        FAJR_TIMESTAMP=$(date -d "$CURRENT_DATE_YMD $FAJR" +%s)

        # Hitung timestamp Imsak (Subuh - offset menit)
        # IMSAK_OFFSET_MINUTES * 60 untuk mengubah menit ke detik
        IMSAK_NOTIF_TIMESTAMP=$((FAJR_TIMESTAMP - (IMSAK_OFFSET_MINUTES * 60)))

        # Konversi timestamp Imsak kembali ke format HH:MM
        IMSAK_NOTIF_TIME=$(date -d "@$IMSAK_NOTIF_TIMESTAMP" +%H:%M)

        CURRENT_TIMESTAMP_NOW=$(date +%s) # Timestamp saat ini

        # Hanya jadwalkan jika waktu Imsak belum lewat hari ini
        if [ "$IMSAK_NOTIF_TIMESTAMP" -gt "$CURRENT_TIMESTAMP_NOW" ]; then
            echo "$(date): Menjadwalkan notifikasi Imsak ($AUDIO_IMSAK) pada $IMSAK_NOTIF_TIME."
            # Perintah yang akan dijalankan oleh at, menggunakan IMSAK_VOLUME
            echo "sudo -u pulse /usr/bin/paplay --volume=$IMSAK_VOLUME $AUDIO_IMSAK &>/dev/null" | at "$IMSAK_NOTIF_TIME"
        else
            echo "$(date): Waktu notifikasi Imsak ($IMSAK_NOTIF_TIME) sudah lewat hari ini."
        fi
    else
        echo "$(date): Notifikasi Imsak tidak diaktifkan."
    fi
}

# Jadwalkan notifikasi Imsak (jika diaktifkan)
schedule_imsak_notification

# Jadwalkan setiap waktu adzan menggunakan script spesifik
# Hitung waktu Subuh dikurangi 10 menit
FAJR_TIMESTAMP=$(date -d "$(date +%Y-%m-%d) $FAJR" +%s)
FAJR_10_MIN_EARLIER=$((FAJR_TIMESTAMP - 600)) # Kurangi 10 menit = 10 * 60 = 600 detik
FAJR_SCHEDULE_TIME=$(date -d "@$FAJR_10_MIN_EARLIER" +%H:%M)
schedule_adzan "Subuh" "$FAJR_SCHEDULE_TIME" "/www/assisten/laporan/audio-adzan-01.sh"



# Hitung waktu Dzuhur dikurangi 40 menit jika Jumat, atau 10 menit jika bukan
DAY_OF_WEEK=$(date +%a) # Ambil hari dalam seminggu
DHUHR_TIMESTAMP=$(date -d "$(date +%Y-%m-%d) $DHUHR" +%s)
DHUHR_SCHEDULE_TIME=""

if [ "$DAY_OF_WEEK" = "Fri" ]; then
    echo "$(date): [DEBUG - audio-adzan.sh] Hari ini Jumat. Menjadwalkan Dzuhur 40 menit lebih awal."
    DHUHR_EARLIER_SECONDS=$((40 * 60)) # 40 menit
else
    echo "$(date): [DEBUG - audio-adzan.sh] Hari ini bukan Jumat. Menjadwalkan Dzuhur 10 menit lebih awal."
    DHUHR_EARLIER_SECONDS=$((10 * 60)) # 10 menit
fi

DHUHR_SCHEDULE_TIMESTAMP=$((DHUHR_TIMESTAMP - DHUHR_EARLIER_SECONDS))
DHUHR_SCHEDULE_TIME=$(date -d "@$DHUHR_SCHEDULE_TIMESTAMP" +%H:%M)

schedule_adzan "Dzuhur" "$DHUHR_SCHEDULE_TIME" "/www/assisten/laporan/audio-adzan-02.sh"


#schedule_adzan "Ashar" "$ASR" "/www/assisten/laporan/audio-adzan-02.sh" # Ashar tetap menggunakan 02.sh
# Hitung waktu Ashar dikurangi 10 menit
ASR_TIMESTAMP=$(date -d "$(date +%Y-%m-%d) $ASR" +%s)
ASR_10_MIN_EARLIER=$((ASR_TIMESTAMP - 600)) # Kurangi 10 menit = 10 * 60 = 600 detik
ASR_SCHEDULE_TIME=$(date -d "@$ASR_10_MIN_EARLIER" +%H:%M)
schedule_adzan "Ashar" "$ASR_SCHEDULE_TIME" "/www/assisten/laporan/audio-adzan-02.sh"


# Hitung waktu Maghrib dikurangi 30 menit
MAGHRIB_TIMESTAMP=$(date -d "$(date +%Y-%m-%d) $MAGHRIB" +%s)
MAGHRIB_15_MIN_EARLIER=$((MAGHRIB_TIMESTAMP - 1800)) # Kurangi 30 menit = 30 * 60 = 1800 detik
MAGHRIB_SCHEDULE_TIME=$(date -d "@$MAGHRIB_15_MIN_EARLIER" +%H:%M)
schedule_adzan "Maghrib" "$MAGHRIB_SCHEDULE_TIME" "/www/assisten/laporan/audio-adzan-03.sh"

# Hitung waktu Isya dikurangi 10 menit
ISHA_TIMESTAMP=$(date -d "$(date +%Y-%m-%d) $ISHA" +%s)
ISHA_15_MIN_EARLIER=$((ISHA_TIMESTAMP - 600)) # Kurangi 10 menit = 10 * 60 = 600 detik
ISHA_SCHEDULE_TIME=$(date -d "@$ISHA_15_MIN_EARLIER" +%H:%M)
schedule_adzan "Isya" "$ISHA_SCHEDULE_TIME" "/www/assisten/laporan/audio-adzan-04.sh"

exit 0