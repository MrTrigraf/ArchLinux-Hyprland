import QtQuick
import Quickshell
import "../services"
import "../../theme"

// ─────────────────────────────────────────────────────────────────────────
// AudioInputTab.qml — содержимое вкладки "Ввод" в AudioPopup.
//
// Список source-устройств (микрофонов). Каждая строка — AudioSourceRow.
// PwNodePeakMonitor'ы внутри строк включаются по visible — capture идёт
// только когда вкладка Input реально видна (см. AudioSourceRow.qml).
//
// ScriptModel оборачивает AudioInputModel.sources, чтобы при подключении
// или отключении USB-микрофона перестраивались только изменившиеся делегаты.
// ─────────────────────────────────────────────────────────────────────────

Item {
    id: root

    // ─── Список source-устройств ───────────────────────────────────────
    ListView {
        id: sourcesList
        anchors.fill: parent

        visible: AudioInputModel.sources.length > 0
        clip: true
        spacing: Theme.audioSourceRowGap

        model: ScriptModel {
            values: AudioInputModel.sources
        }

        // AudioSourceRow уже имеет required property var modelData,
        // QML привяжет его автоматически — без явного перепроброса.
        delegate: AudioSourceRow {}
    }

    // ─── Пустое состояние ──────────────────────────────────────────────
    // На VM или при потере связи с pipewire sources может быть пустым.
    // Без placeholder'а вкладка выглядела бы сломанной.
    Text {
        anchors.centerIn: parent
        visible: AudioInputModel.sources.length === 0
        text: "Устройства ввода не найдены"
        color: Theme.fgMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.audioSourceLabelFontSize
        horizontalAlignment: Text.AlignHCenter
    }
}
