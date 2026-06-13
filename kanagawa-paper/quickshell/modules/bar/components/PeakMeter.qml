import QtQuick
import "../../../theme"

Item {
    id: root

    // ─── Публичные свойства ─────────────────────────────────────────────
    // value: текущий peak, 0..1. Значения >1 не ожидаются (PwNodePeakMonitor
    // клампится pipewire'ом), но на всякий случай зажимаем здесь.
    property real value: 0

    // active: выделять ли цветом accent (true для default-source). false —
    // обычный statusOk-зелёный. См. Theme.audioPeakMeterFg / FgActive.
    property bool active: false

    // ─── Геометрия ──────────────────────────────────────────────────────
    // Высота фиксированная (тонкая полоска). Ширина — от родителя.
    implicitHeight: Theme.audioPeakMeterHeight
    implicitWidth:  120

    // Кламп value в [0..1] для использования внутри биндингов.
    // Свойство приватное по соглашению (префикс _).
    readonly property real _v: Math.max(0, Math.min(1, value))

    // ─── Фон (незаполненная часть) ──────────────────────────────────────
    Rectangle {
        id: track
        anchors.fill: parent
        radius: Theme.audioPeakMeterRadius
        color: Theme.audioPeakMeterBg

        // ─── Заполнение ─────────────────────────────────────────────────
        // Ширина = _v * track.width. Behavior on width — это и есть наш
        // VU-сглаживатель: длительность анимации зависит от направления
        // изменения (рост быстрее, спад медленнее).
        Rectangle {
            id: fill
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            radius: parent.radius
            width: track.width * root._v

            color: root.active
                ? Theme.audioPeakMeterFgActive
                : Theme.audioPeakMeterFg

            // ─── Сглаживание: attack vs decay ────────────────────────────
            // Поведение анимации меняется в зависимости от того, растёт ли
            // ширина или падает. SmoothedAnimation подошёл бы по сути, но
            // у него нет различных attack/decay; SequentialAnimation —
            // оверкилл. Простой NumberAnimation + переключение duration
            // через onTargetChanged-логику — самое прямое.
            //
            // Реализация: держим "цель" в _target и применяем NumberAnimation
            // нужной длительности через смену duration в момент изменения.
            // Это стандартный QML-приём для условного Behavior.
            Behavior on width {
                NumberAnimation {
                    id: peakAnim
                    // Эта функция вычисляется ПЕРЕД стартом каждой анимации.
                    // newValue (целевое width) уже выставлено биндингом
                    // выше; from возьмётся автоматически из текущего width.
                    duration: fill.width <= fill._lastWidth
                        ? Theme.audioPeakMeterDecayMs
                        : Theme.audioPeakMeterAttackMs
                    easing.type: Easing.OutQuad
                }
            }

            // Запоминаем предыдущую ширину, чтобы понять направление
            // изменения. onWidthChanged срабатывает ПОСЛЕ старта анимации,
            // но это норм: мы используем _lastWidth для следующего тика.
            //
            // Приватное свойство (префикс _) — конвенция для "не для UI".
            property real _lastWidth: 0
            onWidthChanged: _lastWidth = width

            // Цвет тоже плавно — на случай переключения active state
            // (когда default-source меняется через чек-кнопку).
            Behavior on color {
                ColorAnimation { duration: Theme.animFast }
            }
        }
    }
}
