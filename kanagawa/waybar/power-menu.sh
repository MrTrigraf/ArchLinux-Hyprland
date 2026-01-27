#!/bin/bash

choice=$(yad --center --title="Управление питанием" \
    --form \
    --field="Выключить!system-shutdown":BTN \
    --field="Перезагрузка!system-reboot":BTN \
    --field="Выход!system-log-out":BTN \
    --field="Блокировка!system-lock-screen":BTN \
    --field="Отмена!cancel":BTN \
    --width=1600 \
    --height=1050 \
    --buttons-layout=center ) 


case $? in
    0) systemctl poweroff ;;
    1) systemctl reboot ;;
    2) pkill -KILL -u $USER ;;
    3) hyprlock ;;
    4) exit ;;
esac