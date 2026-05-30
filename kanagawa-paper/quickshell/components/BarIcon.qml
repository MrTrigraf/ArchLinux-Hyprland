import QtQuick
import "../theme"

// ─────────────────────────────────────────────────────────────────────────────
// BarIcon — иконка из Material Symbols Rounded с variable axis.
// Использование:
//   BarIcon { name: "power_settings_new" }
//   BarIcon { name: "wifi"; iconColor: Theme.statusOk; filled: true }
//   BarIcon { name: "folder"; size: 24 }
// ─────────────────────────────────────────────────────────────────────────────
Text {
    id: root

    // имя глифа Material Symbols (например, "power_settings_new", "wifi")
    property string name: ""

    // заливка: false = outline, true = filled. Variable axis FILL: 0..1.
    property bool filled: false

    // переопределимые параметры (с дефолтами из Theme)
    property real size: Theme.iconSizeBar
    property color iconColor: Theme.fg

    text: name
    color: iconColor

    font.family: Theme.iconFamily
    font.pixelSize: size

    // variable axes: FILL плавно перетекает 0 → 1 при изменении filled.
    // wght=400 — обычная толщина, opsz=24 — оптический размер 24px (стандарт).
    font.variableAxes: ({
        "FILL": filled ? 1 : 0,
        "wght": 400,
        "GRAD": 0,
        "opsz": 24
    })

    // плавная анимация цвета при смене состояния (например, статус Wi-Fi)
    Behavior on color {
        ColorAnimation { duration: Theme.animFast }
    }
}
