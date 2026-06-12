import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "../services"
import "../../theme"

// ─────────────────────────────────────────────────────────────────────────────
// Toast.qml — карточка одного всплывающего уведомления.
//
// Delegate для ListView в ToastsWindow. Получает Notification напрямую
// через property notif (set из delegate'а в ToastsWindow). Никакого поиска
// по id — ScriptModel вычистил все stale-ссылки до нас.
// ─────────────────────────────────────────────────────────────────────────────
Item {
	id: toast

	// Notification приходит напрямую от ScriptModel-delegate'а.
	required property var notif

	readonly property string tier: NotificationService.tierOf(notif)

	implicitWidth: Theme.notifToastWidth
	width: parent ? parent.width : implicitWidth
	implicitHeight: visible ? card.implicitHeight : 0
	visible: notif !== null && notif !== undefined

	// Если notif исчез (closed извне) — убираем тост из очереди.
	onNotifChanged: {
		if (!notif) NotificationService.expireToast(notifId)
	}

	// ─── Длительность жизни тоста (мс) ───────────────────────────────────
	// Приоритет: expireTimeout от клиента, потом дефолт по tier.
	// 0 = висит до клика (Critical).
	readonly property int lifetimeMs: {
		if (!notif) return 0
		if (notif.expireTimeout && notif.expireTimeout > 0) return notif.expireTimeout
		if (tier === "critical") return Theme.notifLifetimeCriticalMs
		if (tier === "system")   return Theme.notifLifetimeSystemMs
		return Theme.notifLifetimeNormalMs
	}

	// ─── Карточка ────────────────────────────────────────────────────────
	Rectangle {
		id: card
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.top: parent.top
		implicitHeight: contentRow.implicitHeight + 2 * Theme.notifToastPadV
		radius: Theme.notifToastRadius
		color: Theme.notifToastBgNormal
		border.color: Theme.edge
		border.width: 0.5

		// Полоска класса слева.
		Rectangle {
			anchors.left: parent.left
			anchors.top: parent.top
			anchors.bottom: parent.bottom
			width: tier === "normal" ? Theme.notifToastStripeWNormal : Theme.notifToastStripeW
			color: tier === "critical" ? Theme.notifStripeCritical
				: tier === "system"   ? Theme.notifStripeSystem
				                      : Theme.notifStripeNormal
			radius: width / 2
			anchors.topMargin: 4
			anchors.bottomMargin: 4
		}

		// Содержимое.
		RowLayout {
			id: contentRow
			anchors.fill: parent
			anchors.leftMargin: Theme.notifToastStripeW + Theme.notifToastPadH
			anchors.rightMargin: Theme.notifToastPadH
			anchors.topMargin: Theme.notifToastPadV
			anchors.bottomMargin: Theme.notifToastPadV
			spacing: 10

			// AppIcon / image.
			IconImage {
				visible: source !== ""
				source: NotificationService.iconFor(notif)
				implicitSize: Theme.notifToastIconSize
				Layout.alignment: Qt.AlignTop
			}

			// Текст.
			ColumnLayout {
				Layout.fillWidth: true
				Layout.alignment: Qt.AlignVCenter
				spacing: 2

				// Строка "appName · сейчас".
				RowLayout {
					Layout.fillWidth: true
					spacing: 4

					Text {
						text: notif ? (notif.appName || "?") : ""
						color: Theme.notifAppNameFg
						font.family: Theme.fontFamily
						font.pixelSize: Theme.notifAppNameSize
						font.weight: Font.Medium
						elide: Text.ElideRight
					}
					Text {
						text: notif ? "· " + NotificationService.timeAgo(notif) : ""
						color: Theme.notifTimeAgoFg
						font.family: Theme.fontFamily
						font.pixelSize: Theme.notifTimeAgoSize
					}
					Item { Layout.fillWidth: true }
				}

				// Summary (жирно).
				Text {
					Layout.fillWidth: true
					visible: text !== ""
					text: notif ? (notif.summary || "") : ""
					color: tier === "critical" ? Theme.notifSummaryFgCritical : Theme.notifSummaryFg
					font.family: Theme.fontFamily
					font.pixelSize: Theme.notifSummarySize
					font.weight: Font.Medium
					elide: Text.ElideRight
				}

				// Body (приглушённо, до 3 строк).
				Text {
					Layout.fillWidth: true
					visible: text !== ""
					text: notif ? (notif.body || "") : ""
					color: tier === "critical" ? Theme.notifBodyFgCritical : Theme.notifBodyFg
					font.family: Theme.fontFamily
					font.pixelSize: Theme.notifBodySize
					wrapMode: Text.WordWrap
					maximumLineCount: 3
					elide: Text.ElideRight
					textFormat: Text.StyledText
				}
			}

			// Крестик ×.
			Text {
				Layout.alignment: Qt.AlignTop
				text: "close"
				font.family: Theme.iconFamily
				font.pixelSize: 16
				color: closeHover.hovered ? Theme.fg : Theme.fgMuted

				HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
				TapHandler {
					acceptedButtons: Qt.LeftButton
					onTapped: NotificationService.expireToast(toast.notif.id)
				}
			}
		}

		// Hover по самому тосту — пауза таймера.
		HoverHandler { id: cardHover }

		// Клик по карточке (вне крестика) — тоже убирает тост.
		TapHandler {
			acceptedButtons: Qt.LeftButton
			onTapped: NotificationService.expireToast(toast.notif.id)
		}
	}

	// ─── Авто-исчезновение по таймеру ────────────────────────────────────
	Timer {
		id: expireTimer
		interval: toast.lifetimeMs
		repeat: false
		running: toast.lifetimeMs > 0 && !cardHover.hovered && toast.notif !== null
		onTriggered: NotificationService.expireToast(toast.notif.id)
	}
}
