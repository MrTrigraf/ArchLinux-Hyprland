import QtQuick
import "../../theme"

// ─────────────────────────────────────────────────────────────────────────────
// CalendarPopup — попап календаря над часами в RightSection.
// ─────────────────────────────────────────────────────────────────────────────
PopupBase {
    id: root

    // ─── Размеры ──────────────────────────────────────────────────────────
    // Ширина: 7 ячеек + горизонтальный padding попапа.
    // Высота: header + dow + 6 строк дат + три gap'а + вертикальный padding.
    contentWidth:  7 * Theme.calCellSize + 2 * Theme.popupContentPadding
    contentHeight: Theme.calHeaderHeight
                 + Theme.calRowGap
                 + Theme.calDowHeight
                 + Theme.calRowGap
                 + 6 * Theme.calCellSize
                 + 2 * Theme.popupContentPadding

    // ─── Состояние отображаемого месяца ──────────────────────────────────
    // 0-индексированный month (как JavaScript Date.getMonth()).
    property int displayedYear:  new Date().getFullYear()
    property int displayedMonth: new Date().getMonth()

    // Сегодня — для подсветки. Не реактивно меняется в полночь, но это
    // не критично: попап закроется и при следующем открытии onIsOpenChanged
    // пересчитает.
    readonly property var today: new Date()

    // ─── Локаль ──────────────────────────────────────────────────────────
    // Qt.locale("ru_RU") — для названий месяцев и дней недели.
    readonly property var locale: Qt.locale("ru_RU")

    // ─── При открытии — сбросить на сегодняшний месяц ────────────────────
    Connections {
        target: root
        function onIsOpenChanged() {
            if (root.isOpen) {
                var now = new Date()
                root.displayedYear = now.getFullYear()
                root.displayedMonth = now.getMonth()
            }
        }
    }

    // ─── Навигация по месяцам ────────────────────────────────────────────
    function prevMonth() {
        if (displayedMonth === 0) {
            displayedMonth = 11
            displayedYear -= 1
        } else {
            displayedMonth -= 1
        }
    }
    function nextMonth() {
        if (displayedMonth === 11) {
            displayedMonth = 0
            displayedYear += 1
        } else {
            displayedMonth += 1
        }
    }

    // ─── Расчёт сетки 7×6 ────────────────────────────────────────────────
    // Возвращает массив из 42 объектов {year, month, day, isCurrentMonth}.
    // Начинается с понедельника недели, в которой лежит 1-е число
    // displayedMonth. Заканчивается через 42 дня (6 строк × 7 столбцов).
    //
    // Если 1-е число — понедельник, сетка начинается с него.
    // Если 1-е число — например, среда, сетка начинается с понедельника
    // прошлой недели (два дня предыдущего месяца).
    function buildGrid() {
        var first = new Date(displayedYear, displayedMonth, 1)
        // getDay(): 0=Вс, 1=Пн, ..., 6=Сб. Хотим: Пн=0, ..., Вс=6.
        var firstWeekday = (first.getDay() + 6) % 7
        // Дата начала сетки — first минус firstWeekday дней.
		var gridStart = new Date(displayedYear, displayedMonth, 1 - firstWeekday)

		var cells = []
        for (var i = 0; i < 42; i++) {
            var d = new Date(gridStart.getFullYear(),
                             gridStart.getMonth(),
                             gridStart.getDate() + i)
            cells.push({
                year:  d.getFullYear(),
                month: d.getMonth(),
                day:   d.getDate(),
                isCurrentMonth: d.getMonth() === displayedMonth
            })
        }
        return cells
    }

    // Реактивный список ячеек — пересчитывается при смене displayedYear/Month.
    readonly property var gridCells: buildGrid()

    // ─── Содержимое попапа ───────────────────────────────────────────────
    Column {
        anchors.fill: parent
        spacing: Theme.calRowGap

        // Дополнительно ловим стрелки ← → на уровне колонки.
        // focus получает от contentHolder (FocusScope в PopupBase).
        focus: true
        Keys.onLeftPressed:  root.prevMonth()
        Keys.onRightPressed: root.nextMonth()

        // ─── 1. Шапка: ‹  Май 2026  › ───────────────────────────────────
        Item {
            width: parent.width
            height: Theme.calHeaderHeight

            // Левая стрелка (chevron_right с rotation 180 — тот же приём,
            // что в WallpaperPicker).
            Item {
                id: prevBtn
                width: Theme.calNavIconSize + 8
                height: parent.height
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                readonly property bool isHovered: prevHover.hovered

                Text {
                    anchors.centerIn: parent
                    text: "chevron_right"
                    rotation: 180
                    font.family: Theme.iconFamily
                    font.pixelSize: Theme.calNavIconSize
                    color: prevBtn.isHovered ? Theme.calNavFgHover : Theme.calNavFg

                    Behavior on color {
                        ColorAnimation { duration: Theme.animFast }
                    }
                }

                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: root.prevMonth()
                }
                HoverHandler {
                    id: prevHover
                    cursorShape: Qt.PointingHandCursor
                }
            }

            // Название месяца по центру.
            // locale.standaloneMonthName даёт форму "Май" вместо "мая"
            // (родительный падеж используется в "1 мая").
            Text {
                anchors.centerIn: parent
                text: {
                    var monthName = root.locale.standaloneMonthName(
                        root.displayedMonth, Locale.LongFormat)
                    // Первая буква в верхний регистр (Qt в ru-локали
                    // возвращает "май", а не "Май").
                    var capitalized = monthName.charAt(0).toUpperCase()
                                    + monthName.slice(1)
                    return capitalized + " " + root.displayedYear
                }
                color: Theme.calHeaderFg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.calHeaderFontSize
            }

            // Правая стрелка.
            Item {
                id: nextBtn
                width: Theme.calNavIconSize + 8
                height: parent.height
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                readonly property bool isHovered: nextHover.hovered

                Text {
                    anchors.centerIn: parent
                    text: "chevron_right"
                    font.family: Theme.iconFamily
                    font.pixelSize: Theme.calNavIconSize
                    color: nextBtn.isHovered ? Theme.calNavFgHover : Theme.calNavFg

                    Behavior on color {
                        ColorAnimation { duration: Theme.animFast }
                    }
                }

				TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: root.nextMonth()
                }
                HoverHandler {
                    id: nextHover
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }

        // ─── 2. Строка дней недели: Пн Вт Ср Чт Пт Сб Вс ─────────────────
        Row {
            width: parent.width
            height: Theme.calDowHeight
            spacing: 0

            Repeater {
                // 7 ячеек: Пн=0..Вс=6 в нашей нумерации.
                // Qt: dayName(1) = Понедельник, dayName(0) = Воскресенье.
                // Поэтому индексы 1..6,0.
                model: [1, 2, 3, 4, 5, 6, 0]

                Item {
                    required property int modelData
                    width: Theme.calCellSize
                    height: parent.height

                    Text {
                        anchors.centerIn: parent
                        text: root.locale.dayName(
                            parent.modelData, Locale.ShortFormat)
                        color: Theme.calDowFg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.calFontSize
                    }
                }
            }
        }

        // ─── 3. Сетка дат 6×7 ────────────────────────────────────────────
        // Repeater + Grid. Grid с 7 columns даёт 6 строк автоматически
        // (42 cell / 7 = 6).
        Grid {
            columns: 7
            rowSpacing: 0
            columnSpacing: 0

            Repeater {
                model: root.gridCells

                Item {
                    id: dayCell
                    required property var modelData

                    width: Theme.calCellSize
                    height: Theme.calCellSize

                    // Сегодня — если совпадают year, month, day с root.today.
                    readonly property bool isToday:
                        modelData.year  === root.today.getFullYear()
                     && modelData.month === root.today.getMonth()
                     && modelData.day   === root.today.getDate()

                    // Фон-плашка today: круглая, чуть меньше cell, по центру.
                    Rectangle {
                        anchors.centerIn: parent
                        width:  Theme.calCellSize - 6
                        height: Theme.calCellSize - 6
                        radius: width / 2
                        visible: dayCell.isToday
                        color: Theme.calTodayBg
                    }

                    Text {
                        anchors.centerIn: parent
                        text: dayCell.modelData.day
                        color: dayCell.isToday
                            ? Theme.calTodayFg
                            : (dayCell.modelData.isCurrentMonth
                                ? Theme.calDayFg
                                : Theme.calDayOtherFg)
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.calFontSize
                    }
                }
            }
        }
    }
}
