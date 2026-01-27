#!/bin/bash
if [[ -z "$1" ]]; then
    # Режим вывода списка опций
    echo -e " Выключить\n Перезагрузить\n⏾ Спящий режим\n Выйти"
else
    # Режим выполнения действия
    case "$1" in
        " Выключить")
            systemctl poweroff
            ;;
        " Перезагрузить")
            systemctl reboot
            ;;
        "⏾ Спящий режим")
            systemctl suspend
            ;;
        " Выйти")
            loginctl terminate-session ${XDG_SESSION_ID-}
            ;;
    esac
fi 