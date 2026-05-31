pragma Singleton
import QtQuick

// ─────────────────────────────────────────────────────────────────────────────
// Theme.qml — палитра kanagawa-paper (ink) для всего Quickshell-шелла
// Singleton: импортируется как import "../theme" + Theme.fg, Theme.accent
// При смене темы правится ТОЛЬКО этот файл — биндинги перерисуют всё остальное.
// ─────────────────────────────────────────────────────────────────────────────
QtObject {
    // ─── Surface (поверхность бара и попапов) ──────────────────────────────
    readonly property color background:  Qt.rgba(0x2A/255, 0x2A/255, 0x37/255, 0.85)
    readonly property color edge:        Qt.rgba(0xDC/255, 0xD7/255, 0xBA/255, 0.30)
    readonly property color shadow:      Qt.rgba(0, 0, 0, 0.30)

    // ─── Text / icons ──────────────────────────────────────────────────────
    readonly property color fg:          "#DCD7BA"   // основной текст и иконки
    readonly property color fgSubtle:    "#aca9a4"   // вторичный (%, минуты)
    readonly property color fgMuted:     "#9e9b93"   // disabled / разделители

    // ─── Inactive (пустые элементы, фоны контейнеров) ──────────────────────
	readonly property color inactive:    "#4A4955"   // пустые ws-пилюли
	readonly property color occupied:    "#6E6E92"   // ws-пилюли с откртыми окнами
    readonly property color inactiveAlt: "#2A2A37"   // tray-подложка и т.п.

    // ─── Accent (приглушённая лаванда, color13 kanagawa-paper ink) ─────────
    readonly property color accent:      "#b4a7b5"   // активный ws, активные попапы
    readonly property color accentUnder: Qt.rgba(0xb4/255, 0xa7/255, 0xb5/255, 0.50)
                                                     // подчёркивания секций

    // ─── Status (для иконок-индикаторов: Wi-Fi, BT, ошибки) ────────────────
    readonly property color statusOk:    "#8ea49e"   // connected / healthy
    readonly property color statusWarn:  "#b6927b"   // мягкое предупреждение
    readonly property color statusError: "#c4746e"   // отключено критично

    // ─── Шрифты ────────────────────────────────────────────────────────────
    readonly property string fontFamily:    "JetBrainsMono Nerd Font"
    readonly property string iconFamily:    "Material Symbols Rounded"
    readonly property int    iconSizeBar:   22        // размер иконок в баре
    readonly property int    fontSizeBar:   16        // размер текста (часы и т.п.)
    readonly property int    fontSizeSmall: 11        // вторичный текст (%, RU/EN)

    // ─── Геометрия бара ────────────────────────────────────────────────────
    readonly property real   barWidthRatio: 0.60      // 52% от Screen.width
    readonly property int    barHeight:     42
    readonly property int    barRadius:     0         // 0 = прилипает к низу без округлений снизу
                                                      // округление верхних углов делается отдельно
    readonly property int    barRadiusTop:  14        // округление верхних углов бара
    readonly property int    sectionGap:    14        // расстояние между секциями
    readonly property int    iconGap:       14        // расстояние между иконками внутри группы
    readonly property int    sectionPaddingH: 0       // горизонтальный padding внутри группы
    readonly property int    underlineHeight: 2       // толщина подчёркивания
	readonly property int    sectionBottomMargin: 5   // отступ секции от низа бара

    // ─── Анимации ──────────────────────────────────────────────────────────
    readonly property int    animFast:      150       // hover / простые переходы
	readonly property int    animMed:       250       // открытие попапов

	// ─── Попапы ────────────────────────────────────────────────────────────
    // Геометрия и стили общие для всех попапов, выезжающих над баром.
    // Используется PopupBase.qml и его наследниками (PowerMenu, WallpaperPicker, ...).
    readonly property int    popupRadius:         14    // все 4 угла, = barRadiusTop
    readonly property int    popupContentPadding: 8     // внутренний отступ от рамки до пунктов
    readonly property int    popupItemHeight:     36    // высота одного пункта меню
    readonly property int    popupItemPaddingH:   14    // горизонтальный отступ внутри пункта
    readonly property int    popupItemRadius:     8     // закругление плашки hover/focus пункта
    readonly property int    popupIconGap:        12    // расстояние "иконка ↔️ лейбл" в пункте
    readonly property int    iconSizePopupItem:   18    // размер иконки в пункте меню
    readonly property int    fontSizePopupItem:   13    // размер шрифта лейбла пункта
    readonly property int    popupSlideOffset:    12    // сдвиг по Y для slide-up анимации

    // Цвет текста на accent-фоне (hover/focus пункта). Тёмный тон kanagawa-paper,
    // читаемо на лавандовом #b4a7b5. Если в будущем accent сменится — поправить здесь.
	readonly property color  popupItemHoverFg:    "#1F1F28"
	readonly property color sectionBg: Qt.alpha("#363646", 0.96)

	readonly property int sectionPillRadius: 10
	readonly property int sectionPillPaddingH: 8
	readonly property int sectionPillPaddingV: 5

	// ─── Wallpaper picker ───────────────────────────────────────────────
    readonly property int  wallpaperPreviewW:        170
    readonly property int  wallpaperPreviewH:        96   // 16:9 (170/16*9 ≈ 96)
    readonly property int  wallpaperPreviewGap:      10
    readonly property int  wallpaperPreviewRadius:   8

    // Рамка выделения selected-превью. accent (#b4a7b5) - тот же визуальный
    // язык, что и hover в PowerMenu и активная пилюля workspace.
    readonly property int   wallpaperSelectedBorderW: 2

    // Высоты строк попапа.
    readonly property int  wallpaperLabelHeight:     22
    readonly property int  wallpaperArrowSize:       28
    readonly property int  wallpaperRowGap:          12  // вертикальный gap между рядом превью/label/стрелки
}
