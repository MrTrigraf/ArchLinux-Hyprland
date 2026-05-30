import QtQuick
import "../../../theme"

// ─────────────────────────────────────────────────────────────────────────────
// SectionUnderline — лавандовая линия с округлёнными концами под группой
// иконок. Цвет приходит из Theme.accentUnder (lavender alpha 50%).
//
// Ширина задаётся снаружи через Layout.fillWidth или явный width.
// Высота берётся из Theme.underlineHeight; радиус = height/2 для круглых концов.
// ─────────────────────────────────────────────────────────────────────────────
Rectangle {
    height: Theme.underlineHeight
    radius: height / 2
    color: Theme.accentUnder
}
