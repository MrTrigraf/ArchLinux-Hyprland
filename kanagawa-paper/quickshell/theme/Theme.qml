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
	readonly property color statusCaution: "#c4b28a"// приглушенный желтый
    readonly property color statusWarn:  "#b6927b"   // мягкое предупреждение
    readonly property color statusError: "#c4746e"   // отключено критично

    // ─── Шрифты ────────────────────────────────────────────────────────────
    readonly property string fontFamily:    "JetBrainsMono Nerd Font"
    readonly property string iconFamily:    "Material Symbols Rounded"
    readonly property int    iconSizeBar:   20        // размер иконок в баре
    readonly property int    fontSizeBar:   16        // размер текста (часы и т.п.)
    readonly property int    fontSizeSmall: 11        // вторичный текст (%, RU/EN)

    // ─── Геометрия бара ────────────────────────────────────────────────────
    readonly property real   barWidthRatio: 0.60      // 60% от Screen.width
    readonly property int    barHeight:     42
    readonly property int    barRadius:     0         // 0 = прилипает к низу без округлений снизу
                                                      // округление верхних углов делается отдельно
    readonly property int    barRadiusTop:  14        // округление верхних углов бара
    readonly property int    sectionGap:    14        // расстояние между секциями
    readonly property int    iconGap:       10        // расстояние между иконками внутри группы
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
	readonly property color sectionBg: Qt.rgba(0x36/255, 0x36/255, 0x46/255, 0.96)
	readonly property color bg: popupItemHoverFg
	readonly property int popupSideMargin: 8

	readonly property int sectionPillRadius: 10
	readonly property int sectionPillPaddingH: 8
	readonly property int sectionPillPaddingV: 5

	// ─── Wallpaper picker ───────────────────────────────────────────────
    readonly property int  wallpaperPreviewW:        170
    readonly property int  wallpaperPreviewH:        96   // 16:9 (170/16*9 ≈ 96)
    readonly property int  wallpaperPreviewGap:      10
    readonly property int  wallpaperPreviewRadius:   4

    // Рамка выделения selected-превью. accent (#b4a7b5) - тот же визуальный
    // язык, что и hover в PowerMenu и активная пилюля workspace.
    readonly property int   wallpaperSelectedBorderW: 2

    // Высоты строк попапа.
    readonly property int  wallpaperLabelHeight:     22
    readonly property int  wallpaperArrowSize:       28
    readonly property int  wallpaperRowGap:          4  // вертикальный gap между рядом превью/label/стрелки

	// ─── System Tray ───────────────────────────────────────────────────
    // Размеры и анимация для иконок системного трея (TraySection.qml).
    readonly property int  trayIconSize:        18   // размер одной tray-иконки
    readonly property int  trayIconGap:         10   // расстояние между иконками
    readonly property int  trayAppearDuration:  220  // длительность fade+scale при появлении
	readonly property real trayAppearScaleFrom: 0.8  // начальный scale (0..1)

	// ─── Keyboard layout indicator ─────────────────────────────────────
    // Индикатор раскладки EN/RU в RightSection. Двухбуквенный код в
    // моноширинном шрифте, ширина фиксирована — чтобы переключение
    // EN-RU не двигало соседние элементы.
    readonly property int  layoutIndicatorWidth:    22    // фиксированная ширина блока
    readonly property int  layoutIndicatorFontSize: 16    // размер шрифта кода
    readonly property color layoutIndicatorFg:      fg    // основной цвет
	readonly property color layoutIndicatorFgHover: accent // при hover

    // ─── Clock slot ─────────────────────────────────────────────────────
    // Фиксированная ширина слота часов в RightSection. JetBrains Mono
    // в pixelSize 16 даёт глиф ~10px; "HH:mm" = 5 символов ≈ 50px.
    // Берём 52 — с минимальным запасом, чтобы text не клипался.
    readonly property int clockSlotWidth: 52

    // ─── Calendar popup ─────────────────────────────────────────────────
    // Геометрия и стили попапа календаря (CalendarPopup.qml).
    readonly property int calCellSize:       30   // размер одной ячейки даты
    readonly property int calHeaderHeight:   32   // высота шапки с месяцем
    readonly property int calDowHeight:      22   // высота строки дней недели
    readonly property int calFontSize:       14   // размер шрифта дат
    readonly property int calHeaderFontSize: 18   // размер шрифта названия месяца
    readonly property int calNavIconSize:    18   // размер стрелок ‹ ›
    readonly property int calRowGap:         2    // вертикальный gap между шапкой/dow/датами

    // Цвета для календаря.
    readonly property color calHeaderFg:     fg          // название месяца
    readonly property color calDowFg:        fgSubtle    // дни недели (Пн Вт Ср ...)
    readonly property color calDayFg:        fg          // обычная дата текущего месяца
    readonly property color calDayOtherFg:   fgMuted     // дата соседнего месяца (приглушённая)
    readonly property color calTodayBg:      accent      // фон сегодняшнего дня
    readonly property color calTodayFg:      popupItemHoverFg  // текст сегодняшнего дня
    readonly property color calNavFg:        fg
    readonly property color calNavFgHover:   accent

	// ─── Volume indicator (RightSection) ────────────────────────────────
    // Размер совпадает с iconSizeBar (22) — основной "ритм" иконок бара.
    // Скролл-шаг в долях единицы (0.01 = 1%).
    readonly property int  volumeIconSize:   Theme.iconSizeBar  // 22
    readonly property real volumeScrollStep: 0.01               // ±1% за щелчок

    // ─── Volume slider (компонент VolumeSlider.qml) ─────────────────────
    // Горизонтальный слайдер с подписью сверху и значением справа.
    // Структура:
    //   ┌─────────────────────────────┐
    //   │ Подпись               42%   │  ← labelRow
    //   │ ━━━━━━━━━━●━━━━━━━━━━━━━━━━ │  ← track + handle
    //   └─────────────────────────────┘
    readonly property int volumeSliderTrackHeight: 4    // толщина "рельса"
    readonly property int volumeSliderHandleSize:  14   // диаметр кругляшка
    readonly property int volumeSliderLabelGap:    6    // gap между подписью и треком
    readonly property int volumeSliderRowGap:      12   // gap между слайдерами в попапе
    readonly property int volumeSliderLabelSize:   12   // размер шрифта подписи и %

    // Цвета слайдера.
    readonly property color volumeSliderLabelFg:  fg               // подпись
    readonly property color volumeSliderValueFg:  fgSubtle         // "42%"
    readonly property color volumeSliderTrackBg:  fgMuted          // незаполненная часть рельса
    readonly property color volumeSliderTrackFg:  accent           // заполненная часть рельса
    readonly property color volumeSliderHandleBg: accent           // кругляшек
    readonly property color volumeSliderHandleBgMuted: fgSubtle    // кругляшек при mute
    readonly property color volumeSliderTrackFgMuted:  fgMuted     // заполнение при mute

    // ─── Volume popup ───────────────────────────────────────────────────
    // Ширина попапа. 260px достаточно для подписи приложения + значения
    // справа без обрезки на типичных именах ("Discord", "Mozilla Firefox",
    // "Spotify"). Если попадётся "Telegram Desktop — Saved Messages" —
    // обрежется через elide; терпимо.
    readonly property int volumePopupWidth:    260
    readonly property int volumePopupRowGap:   volumeSliderRowGap   // gap между слайдерами
    readonly property int volumePopupSeparator: 1                    // тонкая линия "Система | приложения"
	readonly property color volumePopupSeparatorColor: fgMuted

	// ─── Battery popup ───────────────────────────────────────────────────
	readonly property int batteryPopupWidth: 240
	readonly property int batteryPopupRowGap: 12
	readonly property int brightnessIconSize: 14
	readonly property int batteryIconSize: 20

	// ─── Network popup ───────────────────────────────────────────────────
	//   [1. Активный коннект]  ← Wi-Fi/Ethernet/нет-связи, цветная подсветка
	//   ──────────────────────
	//   [2. Список Wi-Fi сетей] ← только если есть WifiDevice; скролл при >max
	//   ──────────────────────
	//   [3. VPN-профили]       ← список с тогом, меню "три точки", кнопка "+"

	readonly property int networkPopupWidth:       300
	readonly property int networkPopupSectionGap:  10           // gap между блоками
	readonly property int networkSeparatorH:       1            // толщина разделителя
	readonly property color networkSeparatorColor: fgMuted

	// Блок 1: активный коннект. Левая полоска-индикатор + полупрозрачный фон
	// в тон полоске. statusOk — есть соединение, statusError — нет.
	readonly property int networkActiveBlockRadius:  8
	readonly property int networkActiveBlockBorderW: 3            // ширина левой полоски
	readonly property int networkActiveBlockPadH:    10
	readonly property int networkActiveBlockPadV:    8
	readonly property int networkActiveTitleSize:    13           // имя сети / "Нет подключения"
	readonly property int networkActiveSubtitleSize: 10           // мелкая строка статуса
	readonly property int networkActiveIconSize:     16           // wifi/ethernet/wifi_off
	readonly property color networkActiveBgOk:       Qt.rgba(0x8e/255, 0xa4/255, 0x9e/255, 0.16)
	readonly property color networkActiveBgError:    Qt.rgba(0xc4/255, 0x74/255, 0x6e/255, 0.16)
	readonly property color networkActiveBorderOk:    statusOk
	readonly property color networkActiveBorderError: statusError

	// Блоки 2-3: строки списков (Wi-Fi-сети и VPN-профили).
	readonly property int networkRowHeight:   28
	readonly property int networkRowPadH:     8
	readonly property int networkRowRadius:   6
	readonly property int networkRowIconSize: 14                  // wifi/lock/vpn-state в строке
	readonly property int networkRowFontSize: 12                  // SSID / имя VPN
	readonly property int networkRowMetaSize: 9                   // мета: тип VPN ("openvpn")
	readonly property color networkRowHoverBg:    Qt.rgba(0xDC/255, 0xD7/255, 0xBA/255, 0.06)
	readonly property color networkRowSelectedBg: Qt.rgba(0xb4/255, 0xa7/255, 0xb5/255, 0.12)

	// Подпись секции внутри попапа ("Доступные сети", "VPN").
	readonly property int networkSectionLabelSize: 10
	readonly property int networkSectionLabelPadH: 4
	readonly property int networkSectionLabelPadV: 4

	// Лимиты до появления вертикального скролла внутри списка.
	readonly property int networkMaxVisibleWifi: 4
	readonly property int networkMaxVisibleVpn:  4

	// Градация цвета иконки Wi-Fi в зависимости от уровня сигнала.
	// signalStrength ∈ [0..1]: >=0.75 — full, 0.50..0.74 — mid, <0.50 — low.
	readonly property color networkSignalFull: fg
	readonly property color networkSignalMid:  fgSubtle
	readonly property color networkSignalLow:  fgMuted

	// ─── Bluetooth (в network popup) ─────────────────────────────────────

	// Шапка-селектор: цвета для активной BT-строки (вариант 3 — параллель
	// с networkActiveBgOk/Error, но в лавандовом тоне акцента).
	readonly property color networkActiveBgBt:     Qt.rgba(0xb4/255, 0xa7/255, 0xb5/255, 0.16)
	readonly property color networkActiveBorderBt: accent

	// Opacity неактивной строки шапки-селектора (когда выбрана другая
	// вкладка). 0.55 — приглушение, читаемое, но явно «не выбрано».
	readonly property real networkSelectorDimOpacity: 0.55

	// Лимит видимых BT-устройств до появления скролла (как networkMaxVisibleWifi).
	readonly property int networkMaxVisibleBt: 4

	// Размер мини-индикатора батареи у BT-устройства (наушники сообщают %).
	readonly property int networkBatteryIconSize: networkRowIconSize

	// ─── Bluetooth-индикатор в баре (мини-глиф справа от network) ────────
	readonly property int barBtIndicatorSize: 14
	readonly property int barBtIndicatorGap:  2    // мини-зазор от network-глифа

	// ─── Notifications: попап центра уведомлений ─────────────────────────

	readonly property int  notifPopupWidth:           340
	readonly property int  notifPopupMaxVisibleRows:  5      // строк без скролла
	readonly property int  notifItemHeightCollapsed:  64     // строка в свёрнутом виде
	readonly property int  notifItemSpacing:          6      // gap между строками
	readonly property int  notifItemRadius:           8
	readonly property int  notifItemPadH:             10
	readonly property int  notifItemPadV:             8
	readonly property int  notifItemStripeW:          4      // полоска tier'а слева

	// Action-bar в шапке попапа — 3 иконки-кнопки (sound / DnD / clear).
	readonly property int  notifActionBarHeight:      40
	readonly property int  notifActionBtnSize:        32     // квадратная кнопка
	readonly property int  notifActionBtnRadius:      8
	readonly property int  notifActionBtnIconSize:    18
	readonly property int  notifActionBtnGap:         4

	// Высота "зоны списка". В неё же рендерится пустое состояние —
	// размер попапа от count=0 не зависит.
	readonly property int  notifPopupListHeight:
		notifPopupMaxVisibleRows * notifItemHeightCollapsed
		+ (notifPopupMaxVisibleRows - 1) * notifItemSpacing

	readonly property int  notifPopupSeparatorH:      1      // тонкая линия header | list

	// КОНСТАНТА — суммарная высота попапа.
	readonly property int  notifPopupContentHeight:
		notifActionBarHeight
		+ notifPopupSeparatorH
		+ notifPopupListHeight
		+ 2 * popupContentPadding

	// ─── Notifications: всплывающие toast'ы ──────────────────────────────
	readonly property int  notifToastWidth:           360
	readonly property int  notifToastSpacing:         8      // gap между toast'ами
	readonly property int  notifToastEdgeMargin:      12     // от правого края экрана
	readonly property int  notifToastTopMargin:       12     // от верха экрана
	readonly property int  notifToastMaxVisible:      3      // больше — в очередь до места
	readonly property int  notifToastRadius:          10
	readonly property int  notifToastPadH:            12
	readonly property int  notifToastPadV:            10
	readonly property int  notifToastStripeW:         4      // полоска класса слева
	readonly property int  notifToastStripeWNormal:   3      // у Normal — тоньше
	readonly property int  notifToastIconSize:        40     // appIcon / image слева

	// Длительность жизни (мс). 0 = висит до клика. Если клиент прислал
	// собственный expireTimeout > 0 — берём его (см. NotificationService).
	readonly property int  notifLifetimeNormalMs:     4000   // 3-5 c
	readonly property int  notifLifetimeSystemMs:     8000  // 10-15 c
	readonly property int  notifLifetimeCriticalMs:   0      // никогда

	// ─── Notifications: иконка-триггер в RightSection ────────────────────
	readonly property int  notifBarIconSize:          iconSizeBar  // 20, общий ритм
	readonly property int  notifBarBadgeSize:         14           // диаметр бейджа
	readonly property int  notifBarBadgeFontSize:     9
	readonly property int  notifBarBadgeOffsetX:      6            // смещение от центра иконки
	readonly property int  notifBarBadgeOffsetY:     -5

	// ─── Notifications: цвета классов ────────────────────────────────────
	// Полоска слева (одинаково в попапе и в toast'е):
	readonly property color notifStripeNormal:        accent            // лаванда
	readonly property color notifStripeSystem:        statusCaution     // приглушённый жёлтый
	readonly property color notifStripeCritical:      statusError       // мягкий красный

	// Фон карточки уведомления в попапе:
	readonly property color notifBgNormal:            inactiveAlt
	readonly property color notifBgSystem:            inactiveAlt
	readonly property color notifBgCritical:          Qt.rgba(0xc4/255, 0x74/255, 0x6e/255, 0.18)

	// Фон одного toast'а:
	readonly property color notifToastBgNormal:       background
	readonly property color notifToastBgSystem:       background
	readonly property color notifToastBgCritical:     Qt.rgba(0xc4/255, 0x74/255, 0x6e/255, 0.18)

	// ─── Notifications: текст в карточке и тосте ─────────────────────────
	readonly property int   notifAppNameSize:         12     // "Telegram · сейчас"
	readonly property int   notifSummarySize:         12     // bold заголовок
	readonly property int   notifBodySize:            11     // приглушённый body
	readonly property int   notifTimeAgoSize:         10     // "5 мин"

	readonly property color notifAppNameFg:           accent
	readonly property color notifSummaryFg:           fg
	readonly property color notifBodyFg:              fg
	readonly property color notifTimeAgoFg:           accent

	// Для critical-карточки текст имеет тёплый оттенок — на красноватом
	// фоне обычный fg ("#DCD7BA") смотрится холодно.
	readonly property color notifSummaryFgCritical:   accent
	readonly property color notifBodyFgCritical:      accent

	// ─── Notifications: action-bar в шапке попапа ────────────────────────
	// 3 иконки: sound / DnD / clear. Цвета по состоянию.
	readonly property color notifIconActive:          fg              // звук вкл, DnD выкл
	readonly property color notifIconMuted:           fgMuted         // звук выкл, DnD вкл
	readonly property color notifIconActiveHover:     accent

	// Корзина: зелёная при наличии уведомлений, красная при пустом списке.
	readonly property color notifTrashOk:             statusOk
	readonly property color notifTrashEmpty:          statusError

	// ─── Notifications: бейдж непрочитанного на колокольчике ─────────────
	readonly property color notifBadgeBg:             accent
	readonly property color notifBadgeFg:             popupItemHoverFg
}
