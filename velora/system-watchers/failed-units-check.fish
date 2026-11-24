#!/usr/bin/env fish

# ════════════════════════════════════════════════════════════════════
#  failed-units-check.fish — детектор упавших systemd-юнитов.
#
#  Запускается user-таймером раз в 5 минут (failed-units-check.timer).
#  Сравнивает текущий список failed с предыдущим (хранится в
#  ~/.cache/quickshell/failed-units-state); для новых юнитов шлёт
#  уведомление через notify-send с urgency=critical → попадает в
#  Critical-tier нашего NotificationServer.
#
#  Покрывает оба scope: system (общесистемные сервисы) и user
#  (Quickshell, hypridle, awww-daemon и т.д.).
#
#  При первом запуске (state-файла нет) записывает baseline без
#  уведомлений — это нужно потому что часть юнитов в Arch штатно
#  показывается как failed (например systemd-modules-load.service при
#  отсутствии модулей). Спамить ими каждые 5 минут не надо. Если
#  такой юнит вылечишь — baseline обновится автоматически.
#
#  Сброс: rm ~/.cache/quickshell/failed-units-state — следующий запуск
#  пересоберёт baseline.
# ════════════════════════════════════════════════════════════════════

set state_file "$HOME/.cache/quickshell/failed-units-state"
mkdir -p (dirname $state_file)

# Собираем текущий список failed-юнитов: system + user.
# Формат строки в state-файле: "<scope>:<name>", по одной на строку.
set -l current

for line in (systemctl --failed --no-legend --plain 2>/dev/null | awk '{print $1}')
    if test -n "$line"
        set -a current "system:$line"
    end
end

for line in (systemctl --user --failed --no-legend --plain 2>/dev/null | awk '{print $1}')
    if test -n "$line"
        set -a current "user:$line"
    end
end

# Первый запуск — записываем baseline и выходим без уведомлений.
if not test -f $state_file
    printf "%s\n" $current > $state_file
    exit 0
end

# Читаем предыдущее состояние.
set -l previous (cat $state_file)

# Шлём уведомление про каждый юнит, которого не было в previous.
for unit in $current
    if not contains -- $unit $previous
        set -l scope (string split -m 1 ":" $unit)[1]
        set -l name  (string split -m 1 ":" $unit)[2]
        notify-send \
            -a "systemd" \
            -u critical \
            -i dialog-error \
            -h "string:category:device.error" \
            "Упал юнит: $scope/$name"
    end
end

# Сохраняем текущее состояние как новый baseline.
printf "%s\n" $current > $state_file
