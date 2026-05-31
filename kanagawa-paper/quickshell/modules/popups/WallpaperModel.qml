pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// WallpaperModel - реактивный список обоев из директории wallpaper/.
//
// API:
//   - items: readonly property list<string> - массив абсолютных путей к
//     изображениям в директории. Сортировка - результат find (имя файла).
//   - count: readonly property int - длина items.
//   - reload(): принудительно перечитать директорию (например, при
//     открытии WallpaperPicker - чтобы новые файлы появились без рестарта Quickshell).
//
// Паттерн по доке Quickshell v0.3.0 introduction:
//   Singleton -> Process с running:true в startup + reload() через ручной
//   запуск -> StdioCollector.onStreamFinished обновляет property items.
//
// Find ищет файлы по списку расширений (case-insensitive через -iname):
// jpg, jpeg, png, gif, webp, bmp - стандартный набор для обоев awww.
Singleton {
    id: root

    // Директория с обоями. Если когда-то понадобится сделать настраиваемой -
    // меняем здесь.
    readonly property string wallpaperDir: Quickshell.env("HOME") + "/.config/hypr/kanagawa-paper/wallpaper"

    // Реактивный список путей. Изначально пустой, заполнится после первого
    // запуска findProc (он стартует при загрузке этого Singleton'а).
    property var items: []
    readonly property int count: items.length

    // Извлечь имя файла (basename) из абсолютного пути.
    // Используется в WallpaperPicker для label под селектед-превью.
    function basename(path) {
        var i = path.lastIndexOf("/")
        return i >= 0 ? path.substring(i + 1) : path
    }

    // Принудительная перезагрузка списка. Вызывается из WallpaperPicker
    // при открытии попапа (на случай если добавили/удалили обои с тех пор
    // как стартовал Quickshell).
    function reload() {
        findProc.running = false  // если ещё бежит - перезапустим
        findProc.running = true
    }

    // Процесс find: ищет файлы 1-го уровня вложенности (maxdepth 1) с
    // поддержкой основных расширений изображений.
    // -type f - только файлы, не директории/симлинки.
    // -iname - case-insensitive (например, IMG.JPG найдётся как и .jpg).
    Process {
        id: findProc
        command: [
            "find", root.wallpaperDir,
            "-maxdepth", "1",
            "-type", "f",
            "(",
                "-iname", "*.jpg",
                "-o", "-iname", "*.jpeg",
                "-o", "-iname", "*.png",
                "-o", "-iname", "*.gif",
                "-o", "-iname", "*.webp",
                "-o", "-iname", "*.bmp",
            ")"
        ]
        running: true   // стартуем при загрузке Singleton'а

        stdout: StdioCollector {
            onStreamFinished: {
                // text - всё stdout одной строкой. Делим на строки,
                // фильтруем пустые (последняя строка от find пустая после \n).
                var lines = this.text.split("\n")
                var paths = []
                for (var i = 0; i < lines.length; i++) {
                    var p = lines[i].trim()
                    if (p.length > 0) paths.push(p)
                }
                paths.sort()  // сортировка по алфавиту имени файла
                root.items = paths
            }
        }
    }
}
