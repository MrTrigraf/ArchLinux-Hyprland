import QtQuick
import QtQuick.Controls
import "../services"
import "." as Popups
import "../../theme"

PopupBase {
	id: root

	contentWidth:  Theme.notifPopupWidth
	contentHeight: Theme.notifPopupContentHeight

	Item {
		anchors.fill: parent

		// ─── Action-bar в шапке ──────────────────────────────────────────
		Item {
			id: actionBar
			anchors.top: parent.top
			anchors.left: parent.left
			anchors.right: parent.right
			height: Theme.notifActionBarHeight

			Row {
				anchors.right: parent.right
				anchors.verticalCenter: parent.verticalCenter
				spacing: Theme.notifActionBtnGap

				// ── Mute звука ──────────────────────────────────────────
				Rectangle {
					id: btnMute
					width: Theme.notifActionBtnSize
					height: Theme.notifActionBtnSize
					radius: Theme.notifActionBtnRadius
					color: muteHover.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
					Behavior on color { ColorAnimation { duration: Theme.animFast } }

					readonly property bool muted: NotificationService.soundMuted

					Text {
						anchors.centerIn: parent
						text: btnMute.muted ? "volume_off" : "volume_up"
						font.family: Theme.iconFamily
						font.pixelSize: Theme.notifActionBtnIconSize
						color: btnMute.muted ? Theme.notifIconMuted : Theme.notifIconActive
						Behavior on color { ColorAnimation { duration: Theme.animFast } }
					}

					HoverHandler { id: muteHover; cursorShape: Qt.PointingHandCursor }
					TapHandler {
						acceptedButtons: Qt.LeftButton
						onTapped: NotificationService.toggleSound()
					}
				}

				// ── DnD-фильтр для Normal ───────────────────────────────
				Rectangle {
					id: btnDnd
					width: Theme.notifActionBtnSize
					height: Theme.notifActionBtnSize
					radius: Theme.notifActionBtnRadius
					color: dndHover.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
					Behavior on color { ColorAnimation { duration: Theme.animFast } }

					readonly property bool dndOn: NotificationService.dndEnabled

					Text {
						anchors.centerIn: parent
						text: btnDnd.dndOn ? "notifications_off" : "notifications"
						font.family: Theme.iconFamily
						font.pixelSize: Theme.notifActionBtnIconSize
						color: btnDnd.dndOn ? Theme.notifIconMuted : Theme.notifIconActive
						Behavior on color { ColorAnimation { duration: Theme.animFast } }
					}

					HoverHandler { id: dndHover; cursorShape: Qt.PointingHandCursor }
					TapHandler {
						acceptedButtons: Qt.LeftButton
						onTapped: NotificationService.toggleDnd()
					}
				}

				// ── Clear-all ───────────────────────────────────────────
				// Зелёный — есть что чистить, красный — пусто.
				Rectangle {
					id: btnClear
					width: Theme.notifActionBtnSize
					height: Theme.notifActionBtnSize
					radius: Theme.notifActionBtnRadius
					color: clearHover.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
					Behavior on color { ColorAnimation { duration: Theme.animFast } }

					readonly property bool hasItems: NotificationService.unreadCount > 0

					Text {
						anchors.centerIn: parent
						text: "delete"
						font.family: Theme.iconFamily
						font.pixelSize: Theme.notifActionBtnIconSize
						color: btnClear.hasItems ? Theme.notifTrashOk : Theme.notifTrashEmpty
						Behavior on color { ColorAnimation { duration: Theme.animFast } }
					}

					HoverHandler { id: clearHover; cursorShape: Qt.PointingHandCursor }
					TapHandler {
						acceptedButtons: Qt.LeftButton
						onTapped: NotificationService.clearAll()
					}
				}
			}
		}

		// ─── Разделитель header / list ───────────────────────────────────
		Rectangle {
			id: separator
			anchors.top: actionBar.bottom
			anchors.left: parent.left
			anchors.right: parent.right
			height: Theme.notifPopupSeparatorH
			color: Theme.edge
			opacity: 0.6
		}

		// ─── Зона списка ─────────────────────────────────────────────────
		// Высота ФИКСИРОВАННАЯ (Theme.notifPopupListHeight) — это и есть
		// то, что держит contentHeight попапа константой.
		Item {
			id: listArea
			anchors.top: separator.bottom
			anchors.left: parent.left
			anchors.right: parent.right
			height: Theme.notifPopupListHeight
			clip: true

			// Пустое состояние — рендерится в той же зоне, размер попапа не меняется.
			Text {
				anchors.centerIn: parent
				visible: notifList.count === 0
				text: "Уведомлений нет"
				color: Theme.fgMuted
				font.family: Theme.fontFamily
				font.pixelSize: Theme.fontSizeSmall
				font.italic: true
			}

			ListView {
				id: notifList
				anchors.fill: parent
				visible: count > 0
				clip: true
				spacing: Theme.notifItemSpacing

				// trackedNotifications — source of truth.
				// Обычное направление TopToBottom: новые приходят в конец модели
				// → попадают в нижнюю часть списка. Старые уезжают вверх,
				// скроллятся при переполнении.
				model: NotificationService.server.trackedNotifications

				interactive: contentHeight > height

				// Автоскролл к концу при появлении новых уведомлений.
				// Только при росте count — иначе сработает и на dismiss/clear.
				property int lastCount: 0
				onCountChanged: {
					if (count > lastCount) Qt.callLater(positionViewAtEnd)
					lastCount = count
				}

				// При открытии попапа — сразу к концу, показывая новейшие.
				onVisibleChanged: if (visible) Qt.callLater(positionViewAtEnd)

				delegate: Popups.NotificationItem {
					required property var modelData
					notif: modelData
					width: ListView.view.width
				}

				ScrollBar.vertical: ScrollBar {
					policy: notifList.interactive ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
				}

				add: Transition {
					NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animMed }
				}
				remove: Transition {
					NumberAnimation { property: "opacity"; to: 0; duration: Theme.animFast }
				}
				displaced: Transition {
					NumberAnimation { property: "y"; duration: Theme.animMed; easing.type: Easing.OutCubic }
				}
			}
		}
	}
}
