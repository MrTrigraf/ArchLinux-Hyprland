import QtQuick
import Quickshell
import "../services"
import "../bar/components"
import "../../theme"

// ─────────────────────────────────────────────────────────────────────────
// AudioOutputTab.qml — содержимое вкладки "Вывод" в AudioPopup.
//
// Раскладка (закрытый селектор):
//   ┌──────────────────────────────────────────────────┐
//   │ [🔊  Donner Livejack USB                    ▾ ]  │  ← AudioDeviceSelector
//   │ [🔊]  Система     ━━━━━●━━━━━━━━━━  62%          │  ← системный слайдер
//   │ ──────────────────────────────────────           │  ← separator
//   │ [🔊]  Firefox     ━━━━●━━━━━━━━━━━  30%          │  ┐
//   │ [🔊]  Spotify     ━━━━━━━●━━━━━━━━  78%          │  ├ app-list (по ПРИЛОЖЕНИЮ,
//   │                                                  │  ┘  не по стриму)
//   └──────────────────────────────────────────────────┘
//
// Раскладка (открытый селектор):
//   ┌──────────────────────────────────────────────────┐
//   │ [🔊  Donner Livejack USB                    ▴ ]  │
//   │   ✓ Donner Livejack USB                          │
//   │     LG Ultragear HDMI                            │
//   │     Bose QC35                                    │
//   └──────────────────────────────────────────────────┘
//
// Источники: AudioOutputModel:
//   - .sink/.volume/.muted/.setVolume/.toggleMute — системный слайдер.
//   - .streamGroups — список групп { name, nodes[] }; одна группа = один
//     слайдер. Если у Firefox 3 вкладки → одна строка "Firefox", и
//     drag/mute применяются ко всем трём стримам одновременно.
//   - .groupVolume / .groupMuted / .setGroupVolume / .toggleGroupMute —
//     group-методы, оперируют массивом nodes из группы.
// ─────────────────────────────────────────────────────────────────────────

Item {
    id: root

    // ─── Геометрия ──────────────────────────────────────────────────────
    // Tab растягивается родителем (AudioPopup задаёт width/height явно).
    readonly property bool selectorExpanded: selector.expanded

    // ─── 1. Селектор устройства вывода ─────────────────────────────────
    AudioDeviceSelector {
        id: selector
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
    }

    // ─── 2. Body: системный слайдер + сепаратор + список приложений ────
    Column {
        id: body
        anchors.top: selector.bottom
        anchors.topMargin: Theme.audioOutputRowGap
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Theme.audioOutputRowGap

        visible: !root.selectorExpanded
        opacity: visible ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Theme.animFast }
        }

        // ── 2a. Системный слайдер (default-sink) ──────────────────────
        VolumeSlider {
            id: systemSlider
            width: parent.width
            label: "Система"
            value: AudioOutputModel.volume
            muted: AudioOutputModel.muted
            muteIcon: true

            onUserChanged: (newValue) => {
                if (AudioOutputModel.muted) AudioOutputModel.toggleMute()
                AudioOutputModel.setVolume(newValue)
            }
            onMuteToggled: AudioOutputModel.toggleMute()
        }

        // ── 2b. Сепаратор: визуально отделяет "Система" от приложений.
        Rectangle {
            width: parent.width
            height: Theme.audioSeparatorHeight
            color: Theme.audioSeparatorColor
        }

        // ── 2c. Список приложений (СГРУППИРОВАННЫЙ) ───────────────────
        // Фикс. высота: audioMaxVisibleApps слотов всегда — попап не
        // прыгает при появлении/исчезновении приложений. При N групп
        // больше лимита включается встроенный ListView-скролл.
        //
        // ScriptModel оборачивает streamGroups: при добавлении новой
        // вкладки в существующее приложение группа просто обновляется
        // изнутри (nodes.push), сама группа в массиве остаётся той же —
        // делегат не пересоздаётся, слайдер не моргает.
        //
        // ВАЖНО: streamGroups — массив plain-object'ов {name, nodes},
        // не массив PwNode. Делегат получает modelData как объект группы
        // и обращается к modelData.name / modelData.nodes.
        ListView {
            id: appsList
            width: parent.width

            readonly property int _itemHeight:
                Theme.volumeSliderLabelSize
                + Theme.volumeSliderLabelGap
                + Theme.volumeSliderHandleSize
                + 4

            height: Theme.audioMaxVisibleApps * _itemHeight
            clip: true
            spacing: 0
            boundsBehavior: Flickable.StopAtBounds

            model: ScriptModel {
                values: AudioOutputModel.streamGroups
            }

            delegate: VolumeSlider {
                id: groupSlider
                required property var modelData      // { name, nodes[] }

                width: ListView.view.width
                height: appsList._itemHeight

                // Имя группы = application.name (или fallback из модели).
                // _groupName в модели уже сделал всю работу, тут просто
                // читаем готовое поле.
                label: modelData.name || "Без имени"

                // Громкость группы = громкость первого узла. Если в группе
                // разные volume у нод — слайдер показывает первое значение,
                // остальные "подравниваются" при первом drag (см. модель).
                value: AudioOutputModel.groupVolume(modelData.nodes)

                // Mute группы = true, если хоть один узел muted.
                // toggleGroupMute приведёт всех к единому состоянию.
                muted: AudioOutputModel.groupMuted(modelData.nodes)

                muteIcon: true

                onUserChanged: (newValue) => {
                    if (!modelData.nodes || modelData.nodes.length === 0) return
                    // Drag = "хочу слышать" → авто-снятие mute у группы.
                    if (AudioOutputModel.groupMuted(modelData.nodes)) {
                        AudioOutputModel.toggleGroupMute(modelData.nodes)
                    }
                    AudioOutputModel.setGroupVolume(modelData.nodes, newValue)
                }

                onMuteToggled: {
                    AudioOutputModel.toggleGroupMute(modelData.nodes)
                }
            }
        }
    }
}