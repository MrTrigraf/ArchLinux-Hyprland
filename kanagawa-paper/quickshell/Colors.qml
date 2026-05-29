pragma Singleton
import QtQuick

QtObject {
    // === Фоны ===
    readonly property color bg: "#1F1F28"
    readonly property color bgLight: "#2A2A37"
    readonly property color bgSurface: "#363646"
    readonly property color bgMuted: "#393836"

    // === Текст ===
    readonly property color text: "#DCD7BA"
    readonly property color textMuted: "#9e9b93"
    readonly property color textOld: "#C8C093"
    readonly property color textBright: "#d5cd9d"

    // === Нормальные цвета (color0–color7) ===
    readonly property color red: "#c4746e"
    readonly property color green: "#699469"
    readonly property color yellow: "#c4b28a"
    readonly property color blue: "#435965"
    readonly property color magenta: "#a292a3"
    readonly property color cyan: "#8ea49e"

    // === Яркие цвета (color8–color15) ===
    readonly property color brightRed: "#cc928e"
    readonly property color brightGreen: "#72a072"
    readonly property color brightYellow: "#d4c196"
    readonly property color brightBlue: "#698a9b"
    readonly property color brightMagenta: "#b4a7b5"
    readonly property color brightCyan: "#96ada7"

    // === Специальные ===
    readonly property color cursor: "#c4b28a"
    readonly property color url: "#938AA9"
    readonly property color orange: "#b6927b"

    // === Семантические (для удобства в виджетах) ===
    readonly property color accent: "#698a9b"
    readonly property color indicator: "#c4b28a"
    readonly property color border: "#698a9b"
    readonly property color error: "#c4746e"
    readonly property color success: "#699469"
    readonly property color warning: "#b6927b"
}
