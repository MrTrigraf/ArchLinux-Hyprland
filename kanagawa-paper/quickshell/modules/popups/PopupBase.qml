import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../theme"


PopupWindow {
    id: root

    // ─── Публичный API ──────────────────────────────────────────────────
    // Бар, к которому привязывается попап. Выставляется из shell.qml
    // перед toggle(). Без него попап не появится (PopupAnchor требует window).
    property var parentBar: null

    // X-координата левого края попапа в координатах parentBar.
    // 0 = левый край бара. Для кнопки питания = 22 (padding бара).
    property int anchorX: 0

    // Размеры внутреннего содержимого.
    property int contentWidth:  220
    property int contentHeight: 200

    // Содержимое попапа задаётся наследником.
    default property alias contentData: contentHolder.data

    // Состояние попапа (логическое). Управляет анимациями и visible.
    property bool isOpen: false

    // ─── Якорь PopupWindow ──────────────────────────────────────────────
    // anchor.window  - окно-родитель (бар).
    // anchor.rect    - прямоугольник внутри окна-родителя, от которого
    //                  попап позиционируется.
    // anchor.edges   - в каком направлении попап растёт от якоря.
    //                  Edges.Top | Edges.Right = вверх и вправо от точки якоря,
    //                  что даёт: левый край попапа = anchor.rect.x,
    //                  нижний край попапа = anchor.rect.y (= 0 = верх бара).
    anchor.window: parentBar
    anchor.rect.x: anchorX
    anchor.rect.y: -contentHeight - 1
    anchor.rect.width: 1
	anchor.rect.height: 1

    // ─── Размер окна попапа ─────────────────────────────────────────────
    // width/height в PopupWindow deprecated - используется implicit*.
    implicitWidth:  contentWidth
    implicitHeight: contentHeight

    // ─── Прозрачный фон окна, чтобы Hyprland blur видел alpha ───────────
    color: "transparent"

    // ─── Видимость ──────────────────────────────────────────────────────
    // Окно появляется, когда isOpen=true. Анимация закрытия задерживает
    // фактическое скрытие: visible остаётся true пока closeAnim бежит.
    visible: isOpen || bg.opacity > 0

    // ─── HyprlandFocusGrab: click-outside + keyboard focus ──────────────
    // active=true пока попап видим. windows=[root] - фокус удерживается
    // на нашем окне, клик ВНЕ него очищает grab (сигнал onCleared) и
    // закрывает попап.
	HyprlandFocusGrab {
        id: grab
        windows: [ root ]
        active: root.isOpen
        onCleared: root.close()
    }
	// ─── Фон попапа ─────────────────────────────────────────────────────
    Rectangle {
        id: bg
        anchors.fill: parent
        color: Theme.background
        radius: Theme.popupRadius
        border.width: 1.2
        border.color: Theme.edge

        // Внутренний padding до содержимого.
        FocusScope {
            id: contentHolder
            anchors.fill: parent
            anchors.margins: Theme.popupContentPadding
            // ESC закрывает попап. focus получается автоматически через
            // HyprlandFocusGrab.windows = [root].
            focus: true
            Keys.onEscapePressed: root.close()
        }

        // ─── Анимация opacity + Y-сдвиг ─────────────────────────────────
        opacity: 0

		Behavior on opacity {
			id: opacityBehavior
            NumberAnimation {
                duration: Theme.animMed
                easing.type: Easing.OutCubic
            }
        }
    }

    // ─── Реакция на смену isOpen ────────────────────────────────────────
    onIsOpenChanged: {
        if (isOpen) {
            bg.opacity = 1
            Qt.callLater(function() {
                root.requestActivate()
                contentHolder.forceActiveFocus()
            })
        } else {
            bg.opacity = 0
            PopupManager.notifyClosed(root)
        }
    }

    // ─── Публичные методы ───────────────────────────────────────────────
    function open()   { isOpen = true  }
    function close()  { if (isOpen) { isOpen = false } }
    function toggle() { isOpen = !isOpen }
	function closeImmediate() {
        if (!isOpen) return
        opacityBehavior.enabled = false
		bg.opacity = 0                            // мгновенно прозрачный
		opacityBehavior.enabled = true
		isOpen = false
		PopupManager.notifyClosed(root)
    }
}
