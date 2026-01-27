#!/bin/bash

VPN_NAME="VPN"  # Замените на имя вашего VPN-подключения
INTERVAL=5      # Интервал проверки в секундах

previous_status="disconnected"

while true; do
    # Проверяем, активно ли VPN-подключение
    if nmcli -g GENERAL.STATE con show "$VPN_NAME" 2>/dev/null | grep -q "activated"; then
        current_status="connected"
    else
        current_status="disconnected"
    fi

    # Если статус изменился, отправляем уведомление
    if [ "$current_status" != "$previous_status" ]; then
        if [ "$current_status" = "connected" ]; then
            notify-send -u normal "VPN подключен" -t 3000
        else
            notify-send -u normal "VPN отключен" -t 3000
        fi
        previous_status="$current_status"
    fi

    sleep $INTERVAL
done