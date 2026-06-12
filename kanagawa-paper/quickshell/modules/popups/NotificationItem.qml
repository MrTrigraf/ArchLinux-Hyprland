import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "../services"
import "../../theme"

Item {
	id: item

	// Notification приходит от родительского delegate'а в попапе.
	required property var notif

	readonly property string tier: NotificationService.tierOf(notif)

	// Состояние раскрытия. По умолчанию свёрнутая карточка.
	property bool expanded: false

	width: parent ? parent.width : Theme.notifPopupWidth
	height: card.implicitHeight

	// Плавное раскрытие/свёртывание. easing подобран мягким — карточка не дёргается.
	Behavior on height {
		NumberAnimation { duration: Theme.animMed; easing.type: Easing.InOutQuad }
	}

	// ─── Карточка ────────────────────────────────────────────────────────
	Rectangle {
		id: card
		anchors.fill: parent
		implicitHeight: contentRow.implicitHeight + 2 * Theme.notifItemPadV
		radius: Theme.notifItemRadius
		color: Theme.notifBgNormal   // единый фон по всем классам
		border.color: Theme.edge
		border.width: 0.5
		clip: true                   // важно: без clip body будет торчать наружу при анимации

		// ─── Полоска класса слева (капсула) ──────────────────────────────
		Rectangle {
			anchors.left: parent.left
			anchors.top: parent.top
			anchors.bottom: parent.bottom
			anchors.leftMargin: 3
			anchors.topMargin: 6
			anchors.bottomMargin: 6
			width: Theme.notifItemStripeW
			radius: width / 2
			color: tier === "critical" ? Theme.notifStripeCritical
				: tier === "system"   ? Theme.notifStripeSystem
				                      : Theme.notifStripeNormal
		}

		// ─── Содержимое ──────────────────────────────────────────────────
		RowLayout {
			id: contentRow
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.top: parent.top
			anchors.leftMargin: Theme.notifItemStripeW + 20
			anchors.rightMargin: Theme.notifItemPadH
			anchors.topMargin: Theme.notifItemPadV
			anchors.bottomMargin: Theme.notifItemPadV
			spacing: 10

			// Колонка текста.
			ColumnLayout {
				Layout.fillWidth: true
				Layout.alignment: Qt.AlignTop
				spacing: 2

				// Строка "appName · timeAgo".
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

				// Summary (bold).
				Text {
					Layout.fillWidth: true
					visible: text !== ""
					text: notif ? (notif.summary || "") : ""
					color: Theme.notifSummaryFg
					font.family: Theme.fontFamily
					font.pixelSize: Theme.notifSummarySize
					font.weight: Font.Medium
					elide: Text.ElideRight
					maximumLineCount: 1
				}

				// Body. В свёрнутом виде — 2 строки, в раскрытом — без ограничения.
				// При смене maximumLineCount контент сам пересчитывает высоту,
				// card.implicitHeight подхватывает, item.height анимируется через Behavior.
				Text {
					Layout.fillWidth: true
					visible: text !== ""
					text: notif ? (notif.body || "") : ""
					color: Theme.notifBodyFg
					font.family: Theme.fontFamily
					font.pixelSize: Theme.notifBodySize
					wrapMode: Text.WordWrap
					maximumLineCount: item.expanded ? 999 : 2
					elide: item.expanded ? Text.ElideNone : Text.ElideRight
					textFormat: Text.StyledText   // bodyMarkupSupported в сервере
				}
			}

			// Крестик ×.
			Text {
				Layout.alignment: Qt.AlignTop
				Layout.topMargin: 2
				text: "close"
				font.family: Theme.iconFamily
				font.pixelSize: 16
				color: closeHover.hovered ? Theme.fg : Theme.fgMuted

				HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
				TapHandler {
					acceptedButtons: Qt.LeftButton
					// Крестик закрывает уведомление полностью — уходит из trackedNotifications.
					onTapped: NotificationService.dismiss(item.notif)
				}
			}
		}

		// Hover-индикация всей карточки (мягкое подсвечивание фона).
		HoverHandler { id: cardHover }

		// Клик по карточке вне крестика — toggle expanded.
		TapHandler {
			acceptedButtons: Qt.LeftButton
			onTapped: item.expanded = !item.expanded
		}

		// Состояние hover: чуть светлее фон.
		states: State {
			name: "hovered"
			when: cardHover.hovered && !item.expanded
			PropertyChanges { card.color: Qt.lighter(Theme.notifBgNormal, 1.1) }
		}
		transitions: Transition {
			ColorAnimation { duration: Theme.animFast }
		}
	}
}
