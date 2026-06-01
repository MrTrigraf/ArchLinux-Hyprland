import QtQuick
import Quickshell
import "../bar/components"
import "../services"
import "../../theme"

PopupBase {
    id: root

    // ─── Размеры ────────────────────────────────────────────────────────
    contentWidth: Theme.volumePopupWidth

    // Высота = padding + systemSlider + (если есть приложения:
    //           gap + separator + gap + N * (slider + gap) - последний gap)
    //         + padding.
    contentHeight: {
        var base = systemSlider.implicitHeight + 2 * Theme.popupContentPadding
        if (VolumeModel.streams.length === 0) return base
        // Разделитель + промежутки + слайдеры приложений.
        var streamsPart = Theme.volumePopupRowGap          // gap до разделителя
                        + Theme.volumePopupSeparator
                        + Theme.volumePopupRowGap          // gap после разделителя
                        + VolumeModel.streams.length * systemSlider.implicitHeight
                        + (VolumeModel.streams.length - 1) * Theme.volumePopupRowGap
        return base + streamsPart
    }

    // ─── Содержимое попапа ──────────────────────────────────────────────
    Column {
        anchors.fill: parent
        spacing: Theme.volumePopupRowGap

        // ─── 1. Системный слайдер ───────────────────────────────────────
        VolumeSlider {
            id: systemSlider
            width: parent.width
            label: "Система"
            value: VolumeModel.volume
            muted: VolumeModel.muted

            // Перетаскивание → запись в Pipewire через VolumeModel.
            // Pipewire подтвердит — биндинг value: VolumeModel.volume
            // вернёт новое значение сюда. Однонаправленно.
            //
            // Если sink был mute, при изменении громкости снимаем mute
            // (обычный UX: двигаешь слайдер — хочешь слышать).
            onUserChanged: (newValue) => {
                if (VolumeModel.muted) VolumeModel.toggleMute()
                VolumeModel.setVolume(newValue)
            }
        }

        // ─── 2. Разделитель (только если есть приложения) ──────────────
        Rectangle {
            width: parent.width
            height: Theme.volumePopupSeparator
            color: Theme.volumePopupSeparatorColor
            visible: VolumeModel.streams.length > 0
        }

        // ─── 3. Слайдеры приложений ─────────────────────────────────────
        // ScriptModel оборачивает streams, чтобы при изменении состава
        // (запустилось/закрылось приложение) Repeater не пересоздавал
        // все делегаты, а только добавил/удалил нужные.
        Repeater {
            model: ScriptModel {
                values: VolumeModel.streams
            }

            VolumeSlider {
                id: streamSlider
                required property var modelData     // PwNode

                width: parent.width

                // application.name → node.name → fallback.
                // PwNode.properties — словарь свойств pipewire-ноды.
                label: {
                    var p = modelData.properties || {}
                    return p["application.name"]
                        || modelData.name
                        || "Без имени"
                }

                // .audio гарантированно не null — мы фильтровали по этому
                // в VolumeModel.streams. Но safety-чек через ?. на случай
                // короткой "переподписки" ноды.
                value: modelData.audio?.volume ?? 0
                muted: modelData.audio?.muted ?? false

                onUserChanged: (newValue) => {
                    if (!modelData.audio) return
                    if (modelData.audio.muted) modelData.audio.muted = false
                    modelData.audio.volume = Math.max(0, Math.min(1, newValue))
                }
            }
        }
    }
}
