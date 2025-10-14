#!/bin/sh

# --- DETEKSI OTOMATIS FILE KONFIGURASI ---
SCRIPT_NAME=$(basename "$0" .sh)
CONFIG_FILE="$(dirname "$0")/${SCRIPT_NAME}.txt"

# --- MEMUAT KONFIGURASI ---
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: File konfigurasi '${CONFIG_FILE}' tidak ditemukan!"
    exit 1
fi

echo "Debug: Memuat konfigurasi dari: $CONFIG_FILE"
. "$CONFIG_FILE"

# --- PENYESUAIAN VOLUME BERDASARKAN WAKTU ---
CURRENT_HOUR=$(date +%H)
CURRENT_MINUTE=$(date +%M)

if [ "$CURRENT_HOUR" -ge 17 ] || [ "$CURRENT_HOUR" -lt 6 ]; then
    VOLUME="$NIGHT_VOLUME"
    echo "Debug: Waktu malam/pagi ($CURRENT_HOUR:00), volume diatur ke $VOLUME."
else
    VOLUME="$DEFAULT_VOLUME"
    echo "Debug: Waktu siang ($CURRENT_HOUR:00), volume diatur ke $VOLUME."
fi

# --- FUNGSI UNTUK MENGUBAH ANGKA MENJADI FILE AUDIO ---
number_to_audio_files() {
    local num_str="$1"
    local audio_list=""
    local part_int=""
    local part_dec=""
    if echo "$num_str" | grep -q '\.'; then
        part_int=$(echo "$num_str" | cut -d'.' -f1)
        part_dec=$(echo "$num_str" | cut -d'.' -f2)
    else
        part_int="$num_str"
        part_dec=""
    fi
    process_two_digits() {
        local val="$1"
        local current_audio_segment=""
        if [ "$val" -ge 10 ] && [ "$val" -le 19 ]; then
            current_audio_segment="${current_audio_segment} ${AUDIO_ANGKA_DIR}/${val}.wav"
        elif [ "$val" -ge 20 ] && [ "$val" -le 99 ]; then
            local tens_val=$(expr "$val" / 10 \* 10)
            local units_val=$(expr "$val" % 10)
            if [ "$tens_val" -gt 0 ]; then
                current_audio_segment="${current_audio_segment} ${AUDIO_ANGKA_DIR}/${tens_val}.wav"
            fi
            if [ "$units_val" -gt 0 ]; then
                current_audio_segment="${current_audio_segment} ${AUDIO_ANGKA_DIR}/${units_val}.wav"
            fi
        elif [ "$val" -ge 0 ] && [ "$val" -le 9 ]; then
            current_audio_segment="${current_audio_segment} ${AUDIO_ANGKA_DIR}/${val}.wav"
        fi
        echo "$current_audio_segment"
    }
    if [ -n "$part_int" ]; then
        local len_int=$(echo -n "$part_int" | wc -c)
        if [ "$len_int" -eq 1 ]; then
            audio_list="${audio_list} $(process_two_digits "$part_int")"
        elif [ "$len_int" -eq 2 ]; then
            audio_list="${audio_list} $(process_two_digits "$part_int")"
        elif [ "$len_int" -eq 3 ]; then
            local hundreds_val=$(expr "$part_int" / 100)
            local remainder_val=$(expr "$part_int" % 100)
            if [ "$hundreds_val" -gt 0 ]; then
                audio_list="${audio_list} ${AUDIO_ANGKA_DIR}/${hundreds_val}00.wav"
            fi
            if [ "$remainder_val" -gt 0 ]; then
                audio_list="${audio_list} $(process_two_digits "$remainder_val")"
            fi
        elif [ "$len_int" -eq 4 ]; then
            local thousands_val=$(expr "$part_int" / 1000)
            local remainder_val=$(expr "$part_int" % 1000)
            if [ "$thousands_val" -gt 0 ]; then
                audio_list="${audio_list} ${AUDIO_ANGKA_DIR}/${thousands_val}000.wav"
            fi
            if [ "$remainder_val" -gt 0 ]; then
                local remainder_audio=$(number_to_audio_files "$remainder_val")
                audio_list="${audio_list} ${remainder_audio}"
            fi
        fi
    fi
    if [ -n "$part_dec" ]; then
        audio_list="${audio_list} ${AUDIO_ANGKA_DIR}/koma.wav"
        part_dec=$(echo "$part_dec" | sed 's/^0*//')
        if [ -z "$part_dec" ]; then
            part_dec="0"
        fi
        local dec_len=$(echo -n "$part_dec" | wc -c)
        if [ "$dec_len" -eq 1 ]; then
            audio_list="${audio_list} ${AUDIO_ANGKA_DIR}/${part_dec}.wav"
        elif [ "$dec_len" -ge 2 ]; then
            local two_digits_dec=$(echo "$part_dec" | cut -c 1-2)
            if [ "$two_digits_dec" -ge 0 ] && [ "$two_digits_dec" -le 9 ]; then
                local single_digit_after_zero=$(echo "$two_digits_dec" | sed 's/^0*//' | sed 's/^$/0/')
                audio_list="${audio_list} ${AUDIO_ANGKA_DIR}/${single_digit_after_zero}.wav"
            else
                audio_list="${audio_list} $(process_two_digits "$two_digits_dec")"
            fi
        fi
    fi
    echo "$audio_list"
}

# --- FUNGSI play_sound dengan deteksi audio aktif ---
play_sound_with_check() {
    local SOUND_FILE="$1"
    local VOLUME_PARAM="$2"
    if [ ! -f "$SOUND_FILE" ]; then
        echo "Error: File audio '${SOUND_FILE}' tidak ditemukan!"
        return 1
    fi
    while true; do
        echo "$(date): Memeriksa status audio stream..."
        AUDIO_STATUS_OUTPUT=$(sudo -u pulse pactl list sink-inputs 2>&1)
        if echo "$AUDIO_STATUS_OUTPUT" | grep -q "Connection refused"; then
            echo "$(date): ERROR: pactl tidak bisa terhubung ke PulseAudio. Pastikan PulseAudio berjalan dan user 'pulse' punya akses."
            echo "$(date): Mencoba memutar audio tanpa penundaan karena error PulseAudio."
            break
        fi
        if echo "$AUDIO_STATUS_OUTPUT" | awk '
            /Sink Input #/ { in_block=1; found_wav=0; found_not_corked=0 }
            in_block {
                if (/media.name = ".*\.wav"/) { found_wav=1 }
                if (/Corked: no/) { found_not_corked=1 }
                if (found_wav && found_not_corked) { print "FOUND_ACTIVE_WAV"; exit }
            }
            /^$/ { in_block=0 }
            END { if (found_wav && found_not_corked) { print "FOUND_ACTIVE_WAV" } }
        ' | grep -q "FOUND_ACTIVE_WAV"; then
            echo "$(date): DETEKSI: Audio stream .wav aktif ('media.name' .wav ditemukan dan 'Corked: no'). Menunda 5 detik..."
            sleep 5
        else
            echo "$(date): DETEKSI: Tidak ada audio stream .wav aktif atau semua stream .wav ditangguhkan. Memutar audio..."
            break
        fi
    done
    sudo -u pulse /usr/bin/paplay --volume="${VOLUME_PARAM}" "${SOUND_FILE}"
}

# --- FUNGSI UTAMA SKRIP ---
WEATHER_URL="https://api.tomorrow.io/v4/timelines?location=${LAT},${LON}&fields=temperature,weatherCode&units=metric&timesteps=current&apikey=${API_KEY}"
echo "Debug: Mencoba mengambil data dari Tomorrow.io: $WEATHER_URL"
WEATHER_DATA=$(curl -s "$WEATHER_URL")
if [ -z "$WEATHER_DATA" ]; then
    echo "Error: Tidak ada respons dari API Tomorrow.io. Periksa koneksi internet OpenWrt Anda."
    exit 1
elif echo "$WEATHER_DATA" | grep -q '"code":401'; then
    echo "Error: API Key Tomorrow.io tidak valid atau belum aktif. Silakan periksa kembali API_KEY Anda."
    exit 1
elif echo "$WEATHER_DATA" | grep -q '"code":400'; then
    echo "Error: Permintaan Tomorrow.io tidak valid. Pesan API: $(echo "$WEATHER_DATA" | jsonfilter -e '@.message' 2>/dev/null)"
    exit 1
fi
TEMP=$(echo "$WEATHER_DATA" | jsonfilter -e '@.data.timelines[0].intervals[0].values.temperature' 2>/dev/null)
WEATHER_CODE=$(echo "$WEATHER_DATA" | jsonfilter -e '@.data.timelines[0].intervals[0].values.weatherCode' 2>/dev/null)
echo "Debug: Suhu: $TEMP"
echo "Debug: Kode Cuaca: $WEATHER_CODE"
SHOULD_ALWAYS_PLAY="false"
case "$CURRENT_HOUR:$CURRENT_MINUTE" in
    "6:30"|"7:30"|"10:30"|"13:30"|"14:30"|"16:00"|"20:30"|"21:30")
        SHOULD_ALWAYS_PLAY="true"
        echo "Debug: Waktu saat ini ($CURRENT_HOUR:$CURRENT_MINUTE) adalah waktu wajib putar."
        ;;
    *)
        echo "Debug: Waktu saat ini ($CURRENT_HOUR:$CURRENT_MINUTE) bukan waktu wajib putar."
        ;;
esac
LAST_WEATHER_CODE=""
if [ -f "$LAST_WEATHER_FILE" ]; then
    LAST_WEATHER_CODE=$(cat "$LAST_WEATHER_FILE")
fi
echo "Debug: Kode Cuaca Terakhir Tersimpan: '$LAST_WEATHER_CODE'"
echo "Debug: Kode Cuaca Saat Ini: '$WEATHER_CODE'"
if [ "$LAST_WEATHER_CODE" = "$WEATHER_CODE" ] && [ "$SHOULD_ALWAYS_PLAY" = "false" ] && [ -n "$WEATHER_CODE" ]; then
    echo "Info: weatherCode tidak berubah ($WEATHER_CODE) dan bukan waktu wajib putar. Tidak memutar notifikasi."
    exit 0
fi
if [ -n "$WEATHER_CODE" ]; then
    echo "$WEATHER_CODE" > "$LAST_WEATHER_FILE"
    echo "Info: weatherCode baru ($WEATHER_CODE) disimpan ke $LAST_WEATHER_FILE."
fi
DESCRIPTION=""
KONDISI_AUDIO_FILE=""
TIPS_AUDIO_FILE=""
case "$WEATHER_CODE" in
    1000) DESCRIPTION="cerah"; KONDISI_AUDIO_FILE="${AUDIO_KONDISI_DIR}/cerah.wav"; TIPS_AUDIO_FILE="${AUDIO_TIPS_DIR}/tip_cerah.wav";;
    1001) DESCRIPTION="berawan"; KONDISI_AUDIO_FILE="${AUDIO_KONDISI_DIR}/berawan.wav"; TIPS_AUDIO_FILE="${AUDIO_TIPS_DIR}/tip_berawan.wav";;
    1100) DESCRIPTION="sebagian besar cerah"; KONDISI_AUDIO_FILE="${AUDIO_KONDISI_DIR}/sebagian_besar_cerah.wav"; TIPS_AUDIO_FILE="${AUDIO_TIPS_DIR}/tip_sebagian_besar_cerah.wav";;
    1101) DESCRIPTION="sebagian besar berawan"; KONDISI_AUDIO_FILE="${AUDIO_KONDISI_DIR}/sebagian_besar_berawan.wav"; TIPS_AUDIO_FILE="${AUDIO_TIPS_DIR}/tip_sebagian_besar_berawan.wav";;
    1102) DESCRIPTION="sebagian berawan"; KONDISI_AUDIO_FILE="${AUDIO_KONDISI_DIR}/sebagian_berawan.wav"; TIPS_AUDIO_FILE="${AUDIO_TIPS_DIR}/tip_sebagian_berawan.wav";;
    2000) DESCRIPTION="mendung"; KONDISI_AUDIO_FILE="${AUDIO_KONDISI_DIR}/mendung.wav"; TIPS_AUDIO_FILE="${AUDIO_TIPS_DIR}/tip_mendung.wav";;
    2100) DESCRIPTION="mendung sebagian"; KONDISI_AUDIO_FILE="${AUDIO_KONDISI_DIR}/mendung_sebagian.wav"; TIPS_AUDIO_FILE="${AUDIO_TIPS_DIR}/tip_mendung_sebagian.wav";;
    4000) DESCRIPTION="gerimis"; KONDISI_AUDIO_FILE="${AUDIO_KONDISI_DIR}/gerimis.wav"; TIPS_AUDIO_FILE="${AUDIO_TIPS_DIR}/tip_gerimis.wav";;
    4001) DESCRIPTION="hujan"; KONDISI_AUDIO_FILE="${AUDIO_KONDISI_DIR}/hujan.wav"; TIPS_AUDIO_FILE="${AUDIO_TIPS_DIR}/tip_hujan.wav";;
    4200) DESCRIPTION="hujan ringan"; KONDISI_AUDIO_FILE="${AUDIO_KONDISI_DIR}/hujan_ringan.wav"; TIPS_AUDIO_FILE="${AUDIO_TIPS_DIR}/tip_hujan_ringan.wav";;
    4201) DESCRIPTION="hujan lebat"; KONDISI_AUDIO_FILE="${AUDIO_KONDISI_DIR}/hujan_lebat.wav"; TIPS_AUDIO_FILE="${AUDIO_TIPS_DIR}/tip_hujan_lebat.wav";;
    5000) DESCRIPTION="salju"; KONDISI_AUDIO_FILE="${AUDIO_KONDISI_DIR}/salju.wav"; TIPS_AUDIO_FILE="${AUDIO_TIPS_DIR}/tip_salju.wav";;
    5001) DESCRIPTION="salju ringan"; KONDISI_AUDIO_FILE="${AUDIO_KONDISI_DIR}/salju_ringan.wav"; TIPS_AUDIO_FILE="${AUDIO_TIPS_DIR}/tip_salju_ringan.wav";;
    5100) DESCRIPTION="salju lebat"; KONDISI_AUDIO_FILE="${AUDIO_KONDISI_DIR}/salju_lebat.wav"; TIPS_AUDIO_FILE="${AUDIO_TIPS_DIR}/tip_salju_lebat.wav";;
    6000) DESCRIPTION="hujan es"; KONDISI_AUDIO_FILE="${AUDIO_KONDISI_DIR}/hujan_es.wav"; TIPS_AUDIO_FILE="${AUDIO_TIPS_DIR}/tip_hujan_es.wav";;
    6001) DESCRIPTION="hujan es ringan"; KONDISI_AUDIO_FILE="${AUDIO_KONDISI_DIR}/hujan_es_ringan.wav"; TIPS_AUDIO_FILE="${AUDIO_TIPS_DIR}/tip_hujan_es_ringan.wav";;
    6200) DESCRIPTION="hujan es lebat"; KONDISI_AUDIO_FILE="${AUDIO_KONDISI_DIR}/hujan_es_lebat.wav"; TIPS_AUDIO_FILE="${AUDIO_TIPS_DIR}/tip_hujan_es_lebat.wav";;
    7000) DESCRIPTION="kabut"; KONDISI_AUDIO_FILE="${AUDIO_KONDISI_DIR}/kabut.wav"; TIPS_AUDIO_FILE="${AUDIO_TIPS_DIR}/tip_kabut.wav";;
    7101) DESCRIPTION="kabut tipis"; KONDISI_AUDIO_FILE="${AUDIO_KONDISI_DIR}/kabut_tipis.wav"; TIPS_AUDIO_FILE="${AUDIO_TIPS_DIR}/tip_kabut_tipis.wav";;
    7102) DESCRIPTION="kabut lebat"; KONDISI_AUDIO_FILE="${AUDIO_KONDISI_DIR}/kabut_lebat.wav"; TIPS_AUDIO_FILE="${AUDIO_TIPS_DIR}/tip_kabut_lebat.wav";;
    8000) DESCRIPTION="badai petir"; KONDISI_AUDIO_FILE="${AUDIO_KONDISI_DIR}/badai_petir.wav"; TIPS_AUDIO_FILE="${AUDIO_TIPS_DIR}/tip_badai_petir.wav";;
    *) DESCRIPTION="kondisi tidak diketahui"; KONDISI_AUDIO_FILE="${AUDIO_KONDISI_DIR}/default_unknown.wav"; TIPS_AUDIO_FILE="${AUDIO_TIPS_DIR}/tip_default.wav";;
esac
if [ "$CURRENT_HOUR" -ge 17 ] || [ "$CURRENT_HOUR" -lt 6 ]; then
    TIPS_AUDIO_FILE=""
    echo "Debug: Tips tidak akan diputar karena ini adalah waktu malam/pagi."
fi
if [ -z "$TEMP" ]; then TEMP="tidak diketahui"; fi
if [ -z "$DESCRIPTION" ]; then DESCRIPTION="kondisi tidak diketahui"; fi
NOTIFICATION_MESSAGE="Cuaca di $LOCATION_NAME saat ini ${DESCRIPTION}, dengan suhu ${TEMP} derajat Celsius."
echo "$NOTIFICATION_MESSAGE"
SUHU_AUDIO_FILES=""
if [ "$TEMP" != "tidak diketahui" ]; then
    SUHU_AUDIO_FILES=$(number_to_audio_files "$TEMP")
fi
echo "Debug: File audio suhu: ${SUHU_AUDIO_FILES}"
AUDIO_SEQUENCE="${AUDIO_INTRO} ${KONDISI_AUDIO_FILE} ${AUDIO_INTRO_SUHU} ${SUHU_AUDIO_FILES} ${AUDIO_DERAJAT_CELSIUS} ${TIPS_AUDIO_FILE}"
echo "Mencoba memutar urutan audio..."
echo "  Urutan file: ${AUDIO_SEQUENCE}"
for file in ${AUDIO_SEQUENCE}; do
    if [ ! -f "$file" ]; then
        echo "Error: File audio '${file}' tidak ditemukan! Pastikan semua file WAV sudah diunggah dan path-nya benar."
    fi
done
for file_to_play in ${AUDIO_SEQUENCE}; do
    echo "Memutar: ${file_to_play}"
    play_sound_with_check "${file_to_play}" "${VOLUME}"
done
echo "Skrip selesai dijalankan."