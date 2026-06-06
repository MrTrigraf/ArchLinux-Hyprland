import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../services"
import "../../theme"

// ─────────────────────────────────────────────────────────────────────────────
// NetworkPopup.qml — попап сетевого индикатора.
//
// Универсален для ноута и десктопа: разница только в данных. Если на машине
// нет Wi-Fi-устройства — блок [2] показывает плейсхолдер.
//
// Структура:
//   [1] Активный коннект     ← полоска statusOk/statusError + иконка + статус
//   ── разделитель ──
//   [2] Wi-Fi сети           ← список + инлайн-форма пароля под выбранной сетью
//   ── разделитель ──
//   [3] VPN-профили          ← список с тогом, меню "⋯", кнопка "+"
//
// API:
//   - NetworkModel: данные о Wi-Fi/Ethernet, sortedWifiNetworks для списка,
//                   connectKnown/connectWithPsk/disconnectActive/toggleWifi.
//   - VpnModel:     profiles[], connectProfile/disconnectProfile/removeProfile/openEditor.
// ─────────────────────────────────────────────────────────────────────────────
PopupBase {
	id: popup

	contentWidth:  Theme.networkPopupWidth
	contentHeight: layout.implicitHeight + 24

	// Какая сеть сейчас в режиме ввода пароля.
	// null — формы нет; объект WifiNetwork — форма раскрыта под этой строкой.
	property var pskTargetNetwork: null

	// У какого VPN-профиля сейчас открыто меню "⋯".
	// null — меню закрыто; строка-uuid — меню открыто для этого профиля.
	property string vpnMenuUuid: ""

	// При открытии включаем Wi-Fi-сканер; при закрытии выключаем и сбрасываем
	// раскрытые формы. Сканер потребляет энергию — держать только пока попап
	// открыт.
	onIsOpenChanged: {
		if (isOpen) {
			NetworkModel.setScanning(true)
		} else {
			NetworkModel.setScanning(false)
			pskTargetNetwork = null
			vpnMenuUuid = ""
		}
	}

	ColumnLayout {
		id: layout
		anchors.fill: parent
		anchors.margins: 12
		spacing: Theme.networkPopupSectionGap

		// ════════════════════════════════════════════════════════════════
		//  Блок [1]: активный коннект
		// ════════════════════════════════════════════════════════════════
		Rectangle {
			Layout.fillWidth: true
			implicitHeight: activeBlockContent.implicitHeight + Theme.networkActiveBlockPadV * 2
			radius: Theme.networkActiveBlockRadius
			color: NetworkModel.anyConnected
				? Theme.networkActiveBgOk
				: Theme.networkActiveBgError

			// Левая цветная полоска-индикатор.
			Rectangle {
				anchors.left: parent.left
				anchors.top: parent.top
				anchors.bottom: parent.bottom
				width: Theme.networkActiveBlockBorderW
				color: NetworkModel.anyConnected
					? Theme.networkActiveBorderOk
					: Theme.networkActiveBorderError
				topLeftRadius:    Theme.networkActiveBlockRadius
				bottomLeftRadius: Theme.networkActiveBlockRadius
			}

			RowLayout {
				id: activeBlockContent
				anchors.fill: parent
				anchors.leftMargin:   Theme.networkActiveBlockBorderW + Theme.networkActiveBlockPadH
				anchors.rightMargin:  Theme.networkActiveBlockPadH
				anchors.topMargin:    Theme.networkActiveBlockPadV
				anchors.bottomMargin: Theme.networkActiveBlockPadV
				spacing: 8

				// Иконка типа коннекта (Material Symbols Rounded — Theme.iconFamily).
				Text {
					Layout.alignment: Qt.AlignVCenter
					text: {
						if (NetworkModel.wifiConnected)  return "signal_wifi_4_bar"
						if (NetworkModel.wiredConnected) return "settings_ethernet"
						return "signal_wifi_off"
					}
					font.family: Theme.iconFamily
					font.pixelSize: Theme.networkActiveIconSize
					color: NetworkModel.anyConnected
						? Theme.fg
						: Theme.networkActiveBorderError
				}

				ColumnLayout {
					Layout.fillWidth: true
					Layout.alignment: Qt.AlignVCenter
					spacing: 2

					// Заголовок: SSID / "Ethernet · <iface>" / "Нет подключения".
					Text {
						Layout.fillWidth: true
						text: {
							if (NetworkModel.wifiConnected)  return NetworkModel.activeSsid
							if (NetworkModel.wiredConnected) return "Ethernet · " + NetworkModel.wiredDevice.name
							return "Нет подключения"
						}
						color: Theme.fg
						font.family: Theme.fontFamily
						font.pixelSize: Theme.networkActiveTitleSize
						font.weight: Font.Medium
						elide: Text.ElideRight
					}

					// Подпись: процент сигнала / "Подключено" / причина отсутствия.
					Text {
						Layout.fillWidth: true
						text: {
							if (NetworkModel.wifiConnected) {
								return "Подключено · " + Math.round(NetworkModel.activeSignal * 100) + "%"
							}
							if (NetworkModel.wiredConnected) return "Подключено"
							if (NetworkModel.hasWifi && !NetworkModel.wifiEnabled) return "Wi-Fi выключен"
							return "Нет соединения"
						}
						color: Theme.fgSubtle
						font.family: Theme.fontFamily
						font.pixelSize: Theme.networkActiveSubtitleSize
						elide: Text.ElideRight
					}
				}

				// Кнопка "Отключиться" — справа от текста, только когда есть активный коннект.
				Text {
					visible: NetworkModel.anyConnected
					text: "Отключиться"
					color: Theme.statusError
					font.family: Theme.fontFamily
					font.pixelSize: Theme.networkRowMetaSize
					padding: 4
					Layout.alignment: Qt.AlignVCenter

					HoverHandler { id: disconnectHover; cursorShape: Qt.PointingHandCursor }
					TapHandler {
						acceptedButtons: Qt.LeftButton
						onTapped: NetworkModel.disconnectActive()
					}
					opacity: disconnectHover.hovered ? 1.0 : 0.75
					Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
				}
			}
		}

		// ── Разделитель ────────────────────────────────────────────────
		Rectangle {
			Layout.fillWidth: true
			Layout.leftMargin: 4
			Layout.rightMargin: 4
			implicitHeight: Theme.networkSeparatorH
			color: Theme.networkSeparatorColor
			opacity: 0.4
		}

		// ════════════════════════════════════════════════════════════════
		//  Блок [2]: Wi-Fi сети
		// ════════════════════════════════════════════════════════════════
		ColumnLayout {
			Layout.fillWidth: true
			spacing: 4

			// Заголовок секции + тогл Wi-Fi справа (если есть устройство).
			RowLayout {
				Layout.fillWidth: true
				Layout.leftMargin:  Theme.networkSectionLabelPadH
				Layout.rightMargin: Theme.networkSectionLabelPadH

				Text {
					Layout.fillWidth: true
					text: "ДОСТУПНЫЕ СЕТИ"
					color: Theme.fgSubtle
					font.family: Theme.fontFamily
					font.pixelSize: Theme.networkSectionLabelSize
					font.letterSpacing: 0.5
				}

				// Тогл Wi-Fi: показываем только если на машине есть Wi-Fi-устройство.
				Rectangle {
					visible: NetworkModel.hasWifi
					width: 32; height: 14
					radius: 7
					color: NetworkModel.wifiEnabled ? Theme.accent : Theme.fgMuted
					Behavior on color { ColorAnimation { duration: Theme.animFast } }
					Layout.alignment: Qt.AlignVCenter

					Rectangle {
						width: 10; height: 10
						radius: 5
						color: Theme.bg
						x: NetworkModel.wifiEnabled ? parent.width - width - 2 : 2
						y: 2
						Behavior on x { NumberAnimation { duration: Theme.animFast } }
					}

					HoverHandler { cursorShape: Qt.PointingHandCursor }
					TapHandler {
						acceptedButtons: Qt.LeftButton
						onTapped: NetworkModel.toggleWifi()
					}
				}
			}

			// Плейсхолдер для машин без Wi-Fi-устройства (десктоп).
			Text {
				visible: !NetworkModel.hasWifi
				Layout.fillWidth: true
				horizontalAlignment: Text.AlignHCenter
				text: "Wi-Fi-модуль отсутствует"
				color: Theme.fgMuted
				font.family: Theme.fontFamily
				font.pixelSize: Theme.networkRowMetaSize
				font.italic: true
				padding: 6
			}

			// Плейсхолдер для случая "Wi-Fi есть, но выключен".
			Text {
				visible: NetworkModel.hasWifi && !NetworkModel.wifiEnabled
				Layout.fillWidth: true
				horizontalAlignment: Text.AlignHCenter
				text: "включите Wi-Fi, чтобы увидеть сети"
				color: Theme.fgMuted
				font.family: Theme.fontFamily
				font.pixelSize: Theme.networkRowMetaSize
				font.italic: true
				padding: 6
			}

			// Список сетей: ListView с ограниченной высотой, скролл при >max.
			ListView {
				id: wifiListView
				visible: NetworkModel.hasWifi && NetworkModel.wifiEnabled
				Layout.fillWidth: true
				Layout.preferredHeight: Math.min(
					contentHeight,
					Theme.networkRowHeight * Theme.networkMaxVisibleWifi
				)
				clip: true
				spacing: 0
				interactive: contentHeight > height
				model: NetworkModel.sortedWifiNetworks

				delegate: Column {
					width: ListView.view.width
					spacing: 0

					readonly property var net: modelData
					readonly property bool isActive: net && net.connected
					readonly property bool isPskTarget: popup.pskTargetNetwork === net

					// ── Строка сети ────────────────────────────────────
					Rectangle {
						width: parent.width
						height: Theme.networkRowHeight
						radius: Theme.networkRowRadius
						color: parent.isPskTarget
							? Theme.networkRowSelectedBg
							: (rowHover.hovered ? Theme.networkRowHoverBg : "transparent")
						Behavior on color { ColorAnimation { duration: Theme.animFast } }

						RowLayout {
							anchors.fill: parent
							anchors.leftMargin: Theme.networkRowPadH
							anchors.rightMargin: Theme.networkRowPadH
							spacing: 6

							// Иконка Wi-Fi (градация цвета по сигналу).
							Text {
								text: "signal_wifi_4_bar"
								font.family: Theme.iconFamily
								font.pixelSize: Theme.networkRowIconSize
								color: {
									var s = parent.parent.parent.net ? (parent.parent.parent.net.signalStrength || 0) : 0
									if (s >= 0.75) return Theme.networkSignalFull
									if (s >= 0.50) return Theme.networkSignalMid
									return Theme.networkSignalLow
								}
							}

							// Имя сети.
							Text {
								Layout.fillWidth: true
								text: parent.parent.parent.net ? (parent.parent.parent.net.name || "") : ""
								color: parent.parent.parent.isActive ? Theme.fg : Theme.fgSubtle
								font.family: Theme.fontFamily
								font.pixelSize: Theme.networkRowFontSize
								font.weight: parent.parent.parent.isActive ? Font.Medium : Font.Normal
								elide: Text.ElideRight
							}

							// Замок для защищённых сетей. В Quickshell 0.3.0
							// WifiSecurityType.None — это enum=0 (без шифрования).
							Text {
								visible: parent.parent.parent.net && parent.parent.parent.net.security !== 0
								text: "lock"
								font.family: Theme.iconFamily
								font.pixelSize: 11
								color: Theme.fgMuted
							}
						}

						HoverHandler { id: rowHover; cursorShape: Qt.PointingHandCursor }
						TapHandler {
							acceptedButtons: Qt.LeftButton
							onTapped: {
								if (!parent.parent.net) return
								// Активная сеть — клик ничего не делает (отключение через "Отключиться" в блоке 1).
								if (parent.parent.net.connected) return
								// Известная сеть (с сохранённым в NM PSK) — подключаемся напрямую.
								// Также для открытых сетей (security === 0).
								if (parent.parent.net.known || parent.parent.net.security === 0) {
									NetworkModel.connectKnown(parent.parent.net)
									return
								}
								// Иначе — раскрываем инлайн-форму ввода пароля.
								popup.pskTargetNetwork = parent.parent.net
							}
						}
					}

					// ── Инлайн-форма ввода пароля (раскрыта только под целевой сетью) ─
					Loader {
						width: parent.width
						active: parent.isPskTarget
						sourceComponent: pskFormComponent
					}
				}
			}
		}

		// ── Компонент формы ввода пароля ───────────────────────────────
		Component {
			id: pskFormComponent

			Rectangle {
				implicitHeight: pskColumn.implicitHeight + 16
				color: Theme.networkRowSelectedBg
				radius: Theme.networkRowRadius

				ColumnLayout {
					id: pskColumn
					anchors.fill: parent
					anchors.margins: 8
					spacing: 6

					Text {
						text: "Пароль"
						color: Theme.fgSubtle
						font.family: Theme.fontFamily
						font.pixelSize: Theme.networkRowMetaSize
					}

					// Поле ввода.
					Rectangle {
						Layout.fillWidth: true
						implicitHeight: pskInput.implicitHeight + 10
						radius: Theme.networkRowRadius
						color: Theme.sectionBg
						border.color: Theme.accent
						border.width: 1

						TextInput {
							id: pskInput
							anchors.fill: parent
							anchors.leftMargin: 8
							anchors.rightMargin: 8
							verticalAlignment: TextInput.AlignVCenter
							echoMode: TextInput.Password
							color: Theme.fg
							font.family: Theme.fontFamily
							font.pixelSize: Theme.networkRowFontSize
							focus: true
							onAccepted: {
								// Enter — подтверждение.
								if (text.length > 0 && popup.pskTargetNetwork) {
									NetworkModel.connectWithPsk(popup.pskTargetNetwork, text)
									popup.pskTargetNetwork = null
								}
							}
						}
					}

					// Кнопки.
					RowLayout {
						Layout.fillWidth: true
						spacing: 6

						// Отмена.
						Rectangle {
							Layout.fillWidth: true
							implicitHeight: 24
							radius: Theme.networkRowRadius
							color: cancelHover.hovered ? Theme.networkRowHoverBg : "transparent"
							border.color: Theme.fgMuted
							border.width: 1
							Behavior on color { ColorAnimation { duration: Theme.animFast } }

							Text {
								anchors.centerIn: parent
								text: "Отмена"
								color: Theme.fgSubtle
								font.family: Theme.fontFamily
								font.pixelSize: Theme.networkRowMetaSize
							}

							HoverHandler { id: cancelHover; cursorShape: Qt.PointingHandCursor }
							TapHandler {
								acceptedButtons: Qt.LeftButton
								onTapped: { popup.pskTargetNetwork = null }
							}
						}

						// Подключиться.
						Rectangle {
							Layout.fillWidth: true
							implicitHeight: 24
							radius: Theme.networkRowRadius
							color: connectHover.hovered ? Qt.lighter(Theme.accent, 1.1) : Theme.accent
							Behavior on color { ColorAnimation { duration: Theme.animFast } }

							Text {
								anchors.centerIn: parent
								text: "Подключиться"
								color: Theme.bg
								font.family: Theme.fontFamily
								font.pixelSize: Theme.networkRowMetaSize
								font.weight: Font.Medium
							}

							HoverHandler { id: connectHover; cursorShape: Qt.PointingHandCursor }
							TapHandler {
								acceptedButtons: Qt.LeftButton
								onTapped: {
									if (pskInput.text.length > 0 && popup.pskTargetNetwork) {
										NetworkModel.connectWithPsk(popup.pskTargetNetwork, pskInput.text)
										popup.pskTargetNetwork = null
									}
								}
							}
						}
					}
				}
			}
		}

		// ── Разделитель ────────────────────────────────────────────────
		Rectangle {
			Layout.fillWidth: true
			Layout.leftMargin: 4
			Layout.rightMargin: 4
			implicitHeight: Theme.networkSeparatorH
			color: Theme.networkSeparatorColor
			opacity: 0.4
		}

		// ════════════════════════════════════════════════════════════════
		//  Блок [3]: VPN-профили
		// ════════════════════════════════════════════════════════════════
		ColumnLayout {
			Layout.fillWidth: true
			spacing: 4

			// Заголовок секции + кнопка "+" справа.
			RowLayout {
				Layout.fillWidth: true
				Layout.leftMargin:  Theme.networkSectionLabelPadH
				Layout.rightMargin: Theme.networkSectionLabelPadH

				Text {
					text: "shield_lock"
					font.family: Theme.iconFamily
					font.pixelSize: Theme.networkRowIconSize
					color: VpnModel.anyActive ? Theme.statusOk : Theme.accent
				}

				Text {
					Layout.fillWidth: true
					text: "VPN"
					color: Theme.fgSubtle
					font.family: Theme.fontFamily
					font.pixelSize: Theme.networkSectionLabelSize
					font.letterSpacing: 0.5
					Layout.leftMargin: 6
				}

				// Кнопка "+": открывает nm-connection-editor для создания профиля.
				Text {
					text: "add"
					font.family: Theme.iconFamily
					font.pixelSize: Theme.networkRowIconSize
					color: addHover.hovered ? Theme.fg : Theme.fgSubtle
					padding: 2
					Behavior on color { ColorAnimation { duration: Theme.animFast } }

					HoverHandler { id: addHover; cursorShape: Qt.PointingHandCursor }
					TapHandler {
						acceptedButtons: Qt.LeftButton
						onTapped: VpnModel.openEditor("")
					}
				}
			}

			// Плейсхолдер, если профилей нет.
			Text {
				visible: VpnModel.profiles.length === 0
				Layout.fillWidth: true
				horizontalAlignment: Text.AlignHCenter
				text: "Нет VPN-профилей. Добавьте через +"
				color: Theme.fgMuted
				font.family: Theme.fontFamily
				font.pixelSize: Theme.networkRowMetaSize
				font.italic: true
				padding: 6
			}

			// Список VPN-профилей.
			ListView {
				id: vpnListView
				visible: VpnModel.profiles.length > 0
				Layout.fillWidth: true
				Layout.preferredHeight: Math.min(
					contentHeight,
					Theme.networkRowHeight * Theme.networkMaxVisibleVpn
				)
				clip: true
				spacing: 0
				interactive: contentHeight > height
				model: VpnModel.profiles

				delegate: Column {
					width: ListView.view.width
					spacing: 0

					readonly property var profile: modelData
					readonly property bool isMenuOpen: popup.vpnMenuUuid === (profile ? profile.uuid : "")

					// ── Строка VPN-профиля ─────────────────────────────
					Rectangle {
						width: parent.width
						height: Theme.networkRowHeight
						radius: Theme.networkRowRadius
						color: vpnRowHover.hovered ? Theme.networkRowHoverBg : "transparent"
						Behavior on color { ColorAnimation { duration: Theme.animFast } }

						RowLayout {
							anchors.fill: parent
							anchors.leftMargin: Theme.networkRowPadH
							anchors.rightMargin: Theme.networkRowPadH
							spacing: 6

							// Индикатор-точка: filled при активном, contour при неактивном.
							Rectangle {
								width: 8; height: 8
								radius: 4
								color: parent.parent.parent.profile && parent.parent.parent.profile.active
									? Theme.statusOk
									: "transparent"
								border.color: Theme.fgMuted
								border.width: parent.parent.parent.profile && parent.parent.parent.profile.active ? 0 : 1.5
							}

							// Имя профиля.
							Text {
								text: parent.parent.parent.profile ? parent.parent.parent.profile.name : ""
								color: parent.parent.parent.profile && parent.parent.parent.profile.active
									? Theme.fg
									: Theme.fgSubtle
								font.family: Theme.fontFamily
								font.pixelSize: Theme.networkRowFontSize
								font.weight: parent.parent.parent.profile && parent.parent.parent.profile.active
									? Font.Medium : Font.Normal
								elide: Text.ElideRight
							}

							// Мета: тип VPN ("openvpn", "wireguard", ...).
							Text {
								Layout.fillWidth: true
								text: parent.parent.parent.profile ? parent.parent.parent.profile.type : ""
								color: Theme.fgMuted
								font.family: Theme.fontFamily
								font.pixelSize: Theme.networkRowMetaSize
							}

							// Меню "три точки".
							Text {
								text: "more_horiz"
								font.family: Theme.iconFamily
								font.pixelSize: Theme.networkRowIconSize
								color: menuHover.hovered ? Theme.fg : Theme.fgSubtle
								padding: 2

								HoverHandler { id: menuHover; cursorShape: Qt.PointingHandCursor }
								TapHandler {
									acceptedButtons: Qt.LeftButton
									onTapped: {
										if (!parent.parent.parent.parent.profile) return
										if (popup.vpnMenuUuid === parent.parent.parent.parent.profile.uuid) {
											popup.vpnMenuUuid = ""
										} else {
											popup.vpnMenuUuid = parent.parent.parent.parent.profile.uuid
										}
									}
								}
							}
						}

						HoverHandler { id: vpnRowHover; cursorShape: Qt.PointingHandCursor }
						TapHandler {
							acceptedButtons: Qt.LeftButton
							onTapped: {
								if (!parent.parent.profile) return
								// Клик по строке — toggle подключения.
								if (parent.parent.profile.active) {
									VpnModel.disconnectProfile(parent.parent.profile.uuid)
								} else {
									VpnModel.connectProfile(parent.parent.profile.uuid)
								}
							}
						}
					}

					// ── Выпадающее меню ────────────────────────────────
					Loader {
						width: parent.width - 20
						x: 20
						active: parent.isMenuOpen
						sourceComponent: vpnMenuComponent
						property var menuProfile: parent.profile
					}
				}
			}
		}

		// ── Компонент выпадающего меню VPN ─────────────────────────────
		Component {
			id: vpnMenuComponent

			Rectangle {
				implicitHeight: menuColumn.implicitHeight + 8
				color: Theme.sectionBg
				radius: Theme.networkRowRadius
				border.color: Theme.fgMuted
				border.width: 1

				property var profile: parent && parent.menuProfile ? parent.menuProfile : null

				ColumnLayout {
					id: menuColumn
					anchors.fill: parent
					anchors.margins: 4
					spacing: 0

					// Подключиться / Отключиться.
					Rectangle {
						Layout.fillWidth: true
						implicitHeight: 28
						radius: Theme.networkRowRadius
						color: toggleHover.hovered ? Theme.networkRowHoverBg : "transparent"
						Behavior on color { ColorAnimation { duration: Theme.animFast } }

						RowLayout {
							anchors.fill: parent
							anchors.leftMargin: 10
							spacing: 8
							Text {
								text: parent.parent.parent.parent.profile && parent.parent.parent.parent.profile.active
									? "stop" : "play_arrow"
								font.family: Theme.iconFamily
								font.pixelSize: 12
								color: parent.parent.parent.parent.profile && parent.parent.parent.parent.profile.active
									? Theme.statusError : Theme.statusOk
							}
							Text {
								Layout.fillWidth: true
								text: parent.parent.parent.parent.profile && parent.parent.parent.parent.profile.active
									? "Отключиться" : "Подключиться"
								color: Theme.fg
								font.family: Theme.fontFamily
								font.pixelSize: Theme.networkRowMetaSize
							}
						}
						HoverHandler { id: toggleHover; cursorShape: Qt.PointingHandCursor }
						TapHandler {
							acceptedButtons: Qt.LeftButton
							onTapped: {
								var p = parent.parent.parent.profile
								if (!p) return
								if (p.active) VpnModel.disconnectProfile(p.uuid)
								else          VpnModel.connectProfile(p.uuid)
								popup.vpnMenuUuid = ""
							}
						}
					}

					// Изменить — открывает nm-connection-editor с этим профилем.
					Rectangle {
						Layout.fillWidth: true
						implicitHeight: 28
						radius: Theme.networkRowRadius
						color: editHover.hovered ? Theme.networkRowHoverBg : "transparent"
						Behavior on color { ColorAnimation { duration: Theme.animFast } }

						RowLayout {
							anchors.fill: parent
							anchors.leftMargin: 10
							spacing: 8
							Text {
								text: "edit"
								font.family: Theme.iconFamily
								font.pixelSize: 12
								color: Theme.fgSubtle
							}
							Text {
								Layout.fillWidth: true
								text: "Изменить..."
								color: Theme.fg
								font.family: Theme.fontFamily
								font.pixelSize: Theme.networkRowMetaSize
							}
						}
						HoverHandler { id: editHover; cursorShape: Qt.PointingHandCursor }
						TapHandler {
							acceptedButtons: Qt.LeftButton
							onTapped: {
								var p = parent.parent.parent.profile
								if (!p) return
								VpnModel.openEditor(p.uuid)
								popup.vpnMenuUuid = ""
							}
						}
					}

					// Удалить — без подтверждения (можно добавить позже).
					Rectangle {
						Layout.fillWidth: true
						implicitHeight: 28
						radius: Theme.networkRowRadius
						color: deleteHover.hovered ? Theme.networkRowHoverBg : "transparent"
						Behavior on color { ColorAnimation { duration: Theme.animFast } }

						RowLayout {
							anchors.fill: parent
							anchors.leftMargin: 10
							spacing: 8
							Text {
								text: "delete"
								font.family: Theme.iconFamily
								font.pixelSize: 12
								color: Theme.statusError
							}
							Text {
								Layout.fillWidth: true
								text: "Удалить"
								color: Theme.statusError
								font.family: Theme.fontFamily
								font.pixelSize: Theme.networkRowMetaSize
							}
						}
						HoverHandler { id: deleteHover; cursorShape: Qt.PointingHandCursor }
						TapHandler {
							acceptedButtons: Qt.LeftButton
							onTapped: {
								var p = parent.parent.parent.profile
								if (!p) return
								VpnModel.removeProfile(p.uuid)
								popup.vpnMenuUuid = ""
							}
						}
					}
				}
			}
		}
	}
}