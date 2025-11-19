#!/bin/sh

# --- Konfigurasi ---
AUDIO_DIR="/www/audio/al-quran"
PAGES_PER_TRACK_FILE="/www/audio/al-quran/pages_per_track.json"
LOG_FILE="/var/log/audio-adzan.log" # File log untuk output script ini

# Pastikan log file ada
touch "$LOG_FILE"

# Fungsi untuk mencatat dan menampilkan pesan
log_message() {
    local type="$1" # e.g., INFO, WARN, ERROR, DEBUG
    local message="$2"
    echo "$(date): [${type}] ${message}" | tee -a "$LOG_FILE"
}

log_message "INFO" "Memulai generate_quran_durations.sh"

# Periksa apakah sox terinstal
if ! command -v sox &> /dev/null; then
    log_message "ERROR" "'sox' tidak ditemukan. Harap instal 'sox' (misalnya, 'opkg install sox') untuk menghitung durasi audio."
    exit 1
fi

# Inisialisasi JSON
echo "{" > "$PAGES_PER_TRACK_FILE.tmp" # Tulis ke file sementara
first_entry=1

# Fungsi untuk mengonversi durasi HH:MM:SS.ms ke total detik (integer)
# Menggunakan awk untuk parsing yang lebih robust
duration_to_seconds() {
    local duration_str="$1"
    # Mengurai H:M:S.ms dan menghitung total detik
    echo "$duration_str" | awk -F'[:.]' '{
        h = $1; m = $2; s = $3; ms = $4;
        if (ms == "") ms = 0;
        if (ms ~ /[^0-9]/ || ms == "") ms = 0;
        ms_decimal = ms / 100.0; 
        total_seconds = (h * 3600) + (m * 60) + s + ms_decimal;
        printf "%.0f\n", total_seconds
    }'
}

# Loop melalui setiap file WAV di direktori Al-Qur'an
for audio_file in "$AUDIO_DIR"/Page*.wav; do
    if [ -f "$audio_file" ]; then
        filename=$(basename "$audio_file")
        page_number=$(echo "$filename" | sed -E 's/Page0*([0-9]+)\.wav/\1/') 

        if [ -z "$page_number" ]; then
            log_message "WARN" "Gagal mengekstrak nomor halaman dari ${audio_file}. Melewatkan file ini."
            continue
        fi

        duration_hhmmss=$(sox --info "$audio_file" 2>&1 | grep 'Duration' | awk '{print $3}')
        log_message "DEBUG" "Output sox mentah untuk ${filename}: '${duration_hhmmss}'"

        duration_int=$(duration_to_seconds "$duration_hhmmss")
        log_message "DEBUG" "Durasi integer untuk ${filename}: '${duration_int}'"

        if [ -z "$duration_int" ] || [ "$duration_int" -lt 0 ]; then
            log_message "WARN" "Gagal mendapatkan atau mengonversi durasi untuk ${audio_file}. Mengatur durasi ke 0."
            duration_int=0
        fi

        # Tambahkan ke JSON
        if [ "$first_entry" -eq 1 ]; then
            echo "  \"$page_number\": $duration_int" >> "$PAGES_PER_TRACK_FILE.tmp"
            first_entry=0
        else
            echo ", \"$page_number\": $duration_int" >> "$PAGES_PER_TRACK_FILE.tmp"
        fi
        log_message "INFO" "Memproses ${filename}: ${duration_int}s" # Pesan INFO ringkas untuk terminal
    fi
done

echo "}" >> "$PAGES_PER_TRACK_FILE.tmp"

# Pindahkan file sementara ke file asli
mv "$PAGES_PER_TRACK_FILE.tmp" "$PAGES_PER_TRACK_FILE"
log_message "INFO" "File durasi Al-Qur'an berhasil dibuat/diperbarui: ${PAGES_PER_TRACK_FILE}"
log_message "INFO" "generate_quran_durations.sh selesai"