#!/bin/bash
INTERFACE="eno1"
TMPFILE="/tmp/waybar_net_data.json"
PREV_FILE="/tmp/waybar_net_prev"

# Ensure previous data exists
if [ ! -f "$PREV_FILE" ]; then
    RX_INIT=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
    TX_INIT=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)
    TIME_INIT=$(date +%s)
    echo "$RX_INIT $TX_INIT $TIME_INIT" > "$PREV_FILE"
    echo '{"text": "Loading network status..."}' > "$TMPFILE"
    sleep 1
fi

while true; do
    sleep 1

    IP=$(ip -4 addr show dev $INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
    PING=$(ping -c 1 -W 1 8.8.8.8 | grep 'time=' | awk -F'time=' '{print $2}' | cut -d' ' -f1)

    RX1=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
    TX1=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)
    TIME1=$(date +%s)

    read RX0 TX0 TIME0 < "$PREV_FILE"
    DIFF_TIME=$((TIME1 - TIME0))

    if (( DIFF_TIME > 0 )); then
        DIFF_RX=$((RX1 - RX0))
        DIFF_TX=$((TX1 - TX0))
        RX_RATE_FLOAT=$(echo "scale=4; $DIFF_RX / $DIFF_TIME" | bc -l)
        TX_RATE_FLOAT=$(echo "scale=4; $DIFF_TX / $DIFF_TIME" | bc -l)
    else
        RX_RATE_FLOAT=0.00
        TX_RATE_FLOAT=0.00
    fi

    echo "$RX1 $TX1 $TIME1" > "$PREV_FILE"

    human_speed() {
        local bytes_per_sec_float=$1
        local bits_per_sec=$(awk "BEGIN {val=$bytes_per_sec_float * 8; printf \"%.0f\", (val < 0 ? 0 : val)}")
        if (( bits_per_sec >= 1000000000 )); then
            awk "BEGIN {printf \"%.2fGbps\", $bits_per_sec/1000000000}"
        elif (( bits_per_sec >= 1000000 )); then
            awk "BEGIN {printf \"%.2fMbps\", $bits_per_sec/1000000}"
        elif (( bits_per_sec >= 1000 )); then
            awk "BEGIN {printf \"%.2fKbps\", $bits_per_sec/1000}"
        else
            echo "${bits_per_sec}bps"
        fi
    }

    RX_HUMAN=$(human_speed $RX_RATE_FLOAT)
    TX_HUMAN=$(human_speed $TX_RATE_FLOAT)

    echo "{\"text\": \"$IP | Ping: ${PING}ms | ↓${RX_HUMAN} ↑${TX_HUMAN}\"}" > "$TMPFILE"
done
