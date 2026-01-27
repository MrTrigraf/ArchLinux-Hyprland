#!/bin/bash

VPN_NAME="VPN"
ICON_CONNECTED="󱚿" 
ICON_DISCONNECTED="󱛀" 
COLOR_DISCONNECTED="#C34043"
COLOR_CONNECTED="#76946A"

# Функция для проверки статуса VPN
check_vpn_status() {
    local status=$(nmcli -g GENERAL.STATE con show "$VPN_NAME" 2>/dev/null)
    if echo "$status" | grep -q "activated"; then
        echo "connected"
    else
        echo "disconnected"
    fi
}

case $1 in
    status)
        vpn_status=$(check_vpn_status)
        if [ "$vpn_status" = "connected" ]; then
            echo "{\"text\": \"$ICON_CONNECTED\", \"alt\": \"connected\", \"class\": \"connected\"}"
        else
            echo "{\"text\": \"$ICON_DISCONNECTED\", \"alt\": \"disconnected\", \"class\": \"disconnected\"}"
        fi
        ;;
    toggle)
        vpn_status=$(check_vpn_status)
        if [ "$vpn_status" = "connected" ]; then
            nmcli connection down "$VPN_NAME"
            # Небольшая задержка для обновления статуса
            sleep 1
        else
            nmcli connection up "$VPN_NAME"
            sleep 1
        fi
        # Обновляем Waybar
        pkill -RTMIN+8 waybar
        ;;
    *)
        echo "Usage: $0 {status|toggle}"
        exit 1
        ;;
esac