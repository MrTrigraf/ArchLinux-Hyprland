function delayed_shot --description 'Скрин экрана через N секунд (чистый grim)'
    set -l delay $argv[1]
    set -l filename $argv[2]
    begin
        sleep $delay
        grim ~/Изображения/$filename
    end &
end
