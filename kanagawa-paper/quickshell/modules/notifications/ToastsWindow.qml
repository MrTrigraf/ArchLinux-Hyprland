import QtQuick
import Quickshell
import Quickshell.Wayland
import "." as Notif
import "../services"
import "../../theme"

PanelWindow {
	id: root

	color: "transparent"

	WlrLayershell.layer: WlrLayer.Overlay
	WlrLayershell.namespace: "qs-notifications-toasts"

	anchors {
		top: true
		right: true
	}

	implicitWidth: Theme.notifToastWidth + 2 * Theme.notifToastEdgeMargin
	implicitHeight: Math.max(1, listView.contentHeight + 2 * Theme.notifToastTopMargin)

	Component.onCompleted: console.log("[toasts] window created on screen:",
		root.screen ? root.screen.name : "?")

	ListView {
		id: listView
		anchors.fill: parent
		anchors.topMargin: Theme.notifToastTopMargin
		anchors.rightMargin: Theme.notifToastEdgeMargin
		anchors.leftMargin: Theme.notifToastEdgeMargin

		spacing: Theme.notifToastSpacing
		interactive: false

		// ScriptModel — правильный паттерн по доке Quickshell:
		// reactivly отображает JS-выражение как model. Когда toastIds
		// или trackedNotifications.values меняются — ScriptModel пересчитывается
		// и обновляет ListView без полного destroy delegate'ов.
		model: ScriptModel {
			values: NotificationService.toastIds
				.map(function (id) {
					return NotificationService.server.trackedNotifications.values
						.find(function (n) { return n && n.id === id })
				})
				.filter(function (n) { return n != null })
		}

		onCountChanged: console.log("[toasts] ListView count =", count)

		delegate: Notif.Toast {
			required property var modelData
			width: ListView.view.width
			notif: modelData
			Component.onCompleted: console.log("[toast-delegate] for notif id =",
			                                    modelData ? modelData.id : "?")
		}
	}
}