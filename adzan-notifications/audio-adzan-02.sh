#!/bin/sh

# ==============================================================================
# Skrip: audio-adzan-02.sh
# Versi: 6.00
# Deskripsi: Mengatur pemutaran Al-Qur'an sebelum adzan Ashar/Jumat, adzan itu sendiri,
#            audio setelah adzan, jeda dengan Al-Qur'an sebelum iqamah, dan iqamah.
#            Menggunakan data durasi Al-Qur'an dari file JSON dan menyimpan state halaman terakhir.
# Tanggal Terakhir Diperbarui: 2025-07-25
# ==============================================================================

# --- Konfigurasi Umum ---
# Memuat konfigurasi dari file terpisah
. /www/assisten/laporan/audio-adzan.config

# Lokasi file log
LOG_FILE="/var/log/audio-adzan.log"

# Fungsi untuk mencatat dan menampilkan pesan
log_message() {
    local type="$1" # e.g., INFO, WARN, ERROR, DEBUG
    local message="$2"
    echo "$(date): [${type}] ${message}" | tee -a "$LOG_FILE" >&2
}

# --- Fungsi untuk Memutar Al-Qur'an dengan Batasan Waktu ---
# Parameter: $1 = DURATION_SECONDS (total durasi putar Quran dalam detik), $2 = MODE ("start", "continue", "end")
play_quran_timed() {
    local DURATION_SECONDS="$1"
    local MODE="$2"

    log_message "DEBUG" "Memulai play_quran_timed dengan durasi ${DURATION_SECONDS}s dan mode ${MODE}."

    if [ -z "$QURAN_STATE_FILE" ] || [ -z "$PAGES_PER_TRACK_FILE" ] || [ -z "$AUDIO_DIR_QURAN" ] || [ -z "$VOLUME_QURAN" ]; then
        log_message "ERROR" "Variabel konfigurasi Al-Qur'an (QURAN_STATE_FILE, PAGES_PER_TRACK_FILE, AUDIO_DIR_QURAN, VOLUME_QURAN) tidak lengkap. Pastikan didefinisikan di audio-adzan.config."
        return 1
    fi

    if [ ! -f "$QURAN_STATE_FILE" ]; then
        mkdir -p "$(dirname "$QURAN_STATE_FILE")"
        echo "1 0" > "$QURAN_STATE_FILE"
        log_message "INFO" "File state Al-Qur'an tidak ditemukan. Membuat ${QURAN_STATE_FILE} dengan halaman 1."
    fi

    local LAST_PLAYED_INFO=$(cat "$QURAN_STATE_FILE" 2>/dev/null)
    local LAST_PAGE_PLAYED=$(echo "$LAST_PLAYED_INFO" | awk '{print $1}')

    if [ -z "$LAST_PAGE_PLAYED" ] || ! expr "$LAST_PAGE_PLAYED" + 1 >/dev/null 2>&1; then
        LAST_PAGE_PLAYED=1
        log_message "WARN" "Nomor halaman terakhir tidak valid di state file. Memulai dari halaman 1."
    fi

    local current_page=$LAST_PAGE_PLAYED
    local start_time=$(date +%s)
    local total_end_time=$((start_time + DURATION_SECONDS))

    if [ "$MODE" = "end" ]; then
        total_end_time=$((start_time + 99999)) # Durasi sangat panjang untuk mode "selesai"
        log_message "INFO" "Mode 'end' diaktifkan. Al-Qur'an akan diputar hingga selesai halaman."
    fi

    log_message "INFO" "Melanjutkan pemutaran Al-Qur'an dari halaman: ${current_page}"

    while true; do
        local current_time=$(date +%s)

        if [ "$current_time" -ge "$total_end_time" ] && [ "$MODE" != "end" ]; then
            log_message "INFO" "Waktu total pemutaran Al-Qur'an telah habis. Menghentikan pemutaran."
            break
        fi

        local audio_file=$(printf "%s/Page%03d.wav" "$AUDIO_DIR_QURAN" "$current_page")

        if [ ! -f "$audio_file" ]; then
            log_message "ERROR" "File audio Al-Qur'an tidak ditemukan: ${audio_file}. Melanjutkan ke halaman berikutnya."
            current_page=$((current_page + 1))
            if [ "$current_page" -gt 604 ]; then
                current_page=1
            fi
            mkdir -p "$(dirname "$QURAN_STATE_FILE")"
            echo "${current_page} 0" > "$QURAN_STATE_FILE"
            sleep 1
            continue
        fi

        local page_duration=60

        if [ ! -f "$PAGES_PER_TRACK_FILE" ]; then
            log_message "ERROR" "File durasi Al-Qur'an tidak ditemukan: ${PAGES_PER_TRACK_FILE}. Menggunakan durasi default 60s."
        elif ! command -v jq &> /dev/null; then
            log_message "ERROR" "Perintah 'jq' tidak ditemukan. Pastikan 'jq' terinstal untuk membaca file durasi. Menggunakan durasi default 60s."
        else
            local page_duration_raw=$(jq -r --arg cp "$current_page" '.[$cp]' "$PAGES_PER_TRACK_FILE" 2>/dev/null)
            log_message "DEBUG" "Durasi mentah dari JSON untuk halaman ${current_page}: '${page_duration_raw}'"

            if [ -z "$page_duration_raw" ] || [ "$page_duration_raw" = "null" ]; then
                log_message "WARN" "Durasi halaman ${current_page} tidak ditemukan di JSON atau bernilai null. Menggunakan durasi default 60s."
            else
                page_duration=$page_duration_raw
            fi
        fi
        
        log_message "DEBUG" "Durasi halaman ${current_page} yang digunakan: ${page_duration}s."

        local remaining_total_time=$((total_end_time - current_time))
        local play_this_page_for=$page_duration

        if [ "$MODE" != "end" ] && [ "$remaining_total_time" -lt "$page_duration" ]; then
            play_this_page_for=$remaining_total_time
            log_message "INFO" "Sisa waktu (${remaining_total_time}s) kurang dari durasi halaman (${page_duration}s). Memutar halaman ${current_page} selama ${play_this_page_for}s."
            if [ "$play_this_page_for" -le 0 ]; then
                log_message "INFO" "Sisa waktu tidak cukup untuk memutar halaman. Menghentikan pemutaran Al-Qur'an."
                break
            fi
        else
            log_message "INFO" "Memutar halaman ${current_page} selama ${page_duration}s."
        fi

        sudo -u pulse /usr/bin/paplay --volume="$VOLUME_QURAN" "$audio_file" &
        local PLAY_PID=$!

        local loop_start_time=$(date +%s)
        local elapsed_loop_time=0

        while [ "$elapsed_loop_time" -lt "$play_this_page_for" ]; do
            local current_loop_time=$(date +%s)
            elapsed_loop_time=$((current_loop_time - loop_start_time))

            current_time=$(date +%s)
            if [ "$current_time" -ge "$total_end_time" ] && [ "$MODE" != "end" ]; then
                log_message "INFO" "Waktu total pemutaran Al-Qur'an telah habis saat halaman sedang diputar. Menghentikan proses paplay PID: ${PLAY_PID}."
                kill "$PLAY_PID" 2>/dev/null
                wait "$PLAY_PID" 2>/dev/null
                break 2
            fi
            sleep 1
        done

        if kill -0 "$PLAY_PID" 2>/dev/null; then
            log_message "DEBUG" "Halaman selesai diputar. Menghentikan proses paplay PID: ${PLAY_PID}."
            kill "$PLAY_PID" 2>/dev/null
            wait "$PLAY_PID" 2>/dev/null
        else
            log_message "DEBUG" "Proses paplay PID: ${PLAY_PID} sudah berhenti."
        fi

        current_page=$((current_page + 1))
        if [ "$current_page" -gt 604 ]; then
            current_page=1
            log_message "INFO" "Semua halaman Al-Qur'an selesai, kembali ke halaman 1."
        fi
        mkdir -p "$(dirname "$QURAN_STATE_FILE")"
        echo "${current_page} 0" > "$QURAN_STATE_FILE"

        if [ "$MODE" = "end" ]; then
            log_message "INFO" "Mode 'end' selesai setelah satu halaman. Menghentikan play_quran_timed."
            break
        fi

        sleep 1
    done
    log_message "DEBUG" "Fungsi play_quran_timed selesai."
}

# --- Skrip Utama ---

log_message "INFO" "Memulai audio-adzan-02.sh (Dzuhur/Ashar) Versi 6.00"

# Tentukan waktu adzan dan durasi Al-Qur'an berdasarkan waktu sholat
ADZAN_TYPE="Ashar" # Default
QURAN_PLAYBACK_DURATION_PRE_ADZAN=600 # 10 menit (default untuk Dzuhur/Ashar normal)

# Deteksi Hari Jumat dan sesuaikan konfigurasi
DAY_OF_WEEK=$(date +%a) # e.g., Fri, Mon, etc.

if [ "$DAY_OF_WEEK" = "Fri" ]; then
    # Jika dipanggil sebelum 14:00 (sebagai indikasi mungkin Dzuhur Jumat)
    # Ini adalah deteksi kasar; skrip induk harusnya lebih akurat dalam penjadwalan.
    # Namun, untuk jaga-jaga jika skrip ini dipicu secara langsung untuk Dzuhur Jumat:
    CURRENT_HOUR=$(date +%H)
    if [ "$CURRENT_HOUR" -lt 14 ]; then # Asumsi adzan Dzuhur Jumat sebelum jam 2 siang
        ADZAN_TO_PLAY="$AUDIO_ADZAN_JUMAT"
        QURAN_PLAYBACK_DURATION_PRE_ADZAN=2400 # 40 menit untuk Jumat
        ADZAN_TYPE="Dzuhur Jumat"
        log_message "INFO" "Terdeteksi hari Jumat dan waktu sebelum 14:00. Menggunakan adzan Jumat dan durasi Al-Qur'an 40 menit sebelum adzan."
    else
        ADZAN_TO_PLAY="$AUDIO_ADZAN_DEFAULT"
        QURAN_PLAYBACK_DURATION_PRE_ADZAN=600 # 10 menit untuk Ashar
        log_message "INFO" "Terdeteksi hari Jumat tapi setelah jam 14:00 (mungkin Ashar Jumat). Menggunakan adzan default dan durasi Al-Qur'an 10 menit sebelum adzan."
    fi
else
    ADZAN_TO_PLAY="$AUDIO_ADZAN_DEFAULT"
    QURAN_PLAYBACK_DURATION_PRE_ADZAN=600 # 10 menit untuk Ashar
    log_message "INFO" "Hari biasa. Menggunakan adzan default dan durasi Al-Qur'an 10 menit sebelum adzan."
fi

log_message "INFO" "Memulai proses adzan untuk: ${ADZAN_TYPE}"
log_message "INFO" "Durasi pemutaran Al-Qur'an pra-adzan: ${QURAN_PLAYBACK_DURATION_PRE_ADZAN} detik."

log_message "INFO" "Memastikan tidak ada proses paplay yang macet dari sesi sebelumnya."
killall paplay 2>/dev/null
sleep 1

# 1. Putar Al-Qur'an sebelum adzan
play_quran_timed "$QURAN_PLAYBACK_DURATION_PRE_ADZAN" "start"

# 2. Pastikan semua proses paplay berhenti sebelum adzan diputar
log_message "INFO" "Memastikan semua pemutar audio Al-Qur'an dihentikan sebelum adzan."
killall paplay 2>/dev/null
sleep 2

# 3. Putar adzan
log_message "INFO" "Memutar adzan: ${ADZAN_TO_PLAY}"
sudo -u pulse /usr/bin/paplay --volume="$VOLUME_ADZAN" "$ADZAN_TO_PLAY"
sleep 1 # Jeda singkat setelah adzan

# 4. Logika setelah adzan: doa adzan, jeda 9 menit (8 menit quran, 1 menit hening)
if [ -n "$AUDIO_SETELAH_ADZAN" ] && [ -f "$AUDIO_SETELAH_ADZAN" ]; then
    log_message "INFO" "Memutar audio setelah adzan: ${AUDIO_SETELAH_ADZAN}"
    sudo -u pulse /usr/bin/paplay --volume="$VOLUME_AUDIO_LAIN" "$AUDIO_SETELAH_ADZAN"
    sleep 1
fi

if [ "$ADZAN_IQAMAH_ENABLED" = "ya" ]; then
    log_message "INFO" "Memulai jeda 9 menit sebelum Iqamah (8 menit Al-Qur'an, 1 menit hening)."
    
    # Putar Al-Qur'an selama 8 menit
    play_quran_timed 480 "start" # 8 menit = 480 detik
    
    # Hentikan semua paplay (dari Quran)
    log_message "INFO" "Menghentikan pemutaran Al-Qur'an sebelum Iqamah."
    killall paplay 2>/dev/null
    sleep 1 # Jeda singkat

    # Sisa 1 menit hening
    log_message "INFO" "Jeda hening 1 menit sebelum Iqamah."
    sleep 60 # 1 menit = 60 detik

    if [ -f "$AUDIO_IQAMAH" ]; then
        log_message "INFO" "Memutar Iqamah: ${AUDIO_IQAMAH}"
        sudo -u pulse /usr/bin/paplay --volume="$VOLUME_IQAMAH" "$AUDIO_IQAMAH"
    else
        log_message "WARN" "File audio Iqamah tidak ditemukan: ${AUDIO_IQAMAH}"
    fi
else
    log_message "INFO" "Iqamah tidak diaktifkan."
fi

log_message "INFO" "Proses skrip audio-adzan-02.sh selesai."

exit 0