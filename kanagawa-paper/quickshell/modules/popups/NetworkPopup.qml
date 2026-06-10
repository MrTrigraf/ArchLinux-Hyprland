import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../services"
import "../../theme"

// ─────────────────────────────────────────────────────────────────────────────
// NetworkPopup.qml — единый попап «связь»: Wi-Fi + Ethernet + Bluetooth + VPN.
//
// Архитектура (close+reopen для tab switch):
//
//   [1] ШАПКА-СЕЛЕКТОР
//       ┌──────────────────────────────────┐
//       │  Wi-Fi-строка       (выбрана)    │ ← полоска statusOk/error
//       │  ────────────────────────────    │
//       │  BT-строка          (приглушена) │ ← visible: BluetoothModel.available
//       └──────────────────────────────────┘
//       Клик по невыбранной строке = переключить вкладку. Технически —
//       popup закрывается с fade-out, через animMed+50 ms открывается
//       заново с новым selectedTab. Это даёт чистый xdg_popup destroy →
//       create в Wayland, без ghost-rendering (артефакта старого surface
//       поверх нового, который мы видели при простом resize). Длительность
//       перехода ≈490ms (220ms fade-out + 50ms gap + 220ms fade-in).
//
//   ── разделитель ──
//
//   [2] ПЕРЕКЛЮЧАЕМЫЙ КОНТЕНТ (visible: selectedTab === ...)
//       "wifi"      → блок Wi-Fi (заголовок «ДОСТУПНЫЕ СЕТИ», тогл,
//                     список, инлайн-плашки PSK/forget)
//       "bluetooth" → блок Bluetooth (заголовок «BLUETOOTH-УСТРОЙСТВА»,
//                     тогл, кнопка «скан», кнопка «+» blueman, список)
//
//   ── разделитель ──
//
//   [3] VPN (без изменений)
//
// API:
//   - NetworkModel:   wifi/Ethernet + VPN-источники.
//   - VpnModel:       profiles[], connect/disconnect/openEditor.
//   - BluetoothModel: available, enabled, discovering, sortedDevices,
//                     activeDevice, togglePower, toggleDiscovery,
//                     connect/disconnect/pair/forget, openPairingHelper,
//                     deviceGlyph (XDG icon → Material Symbols).
// ─────────────────────────────────────────────────────────────────────────────
PopupBase {
	id: popup

	contentWidth:  Theme.networkPopupWidth
	contentHeight: layout.implicitHeight + 24

	// ── Состояние попапа ────────────────────────────────────────────────
	// Какая вкладка активна. Изменения этого свойства теперь МГНОВЕННО
	// меняют видимый блок (visible-биндинги в [2-WIFI] и [2-BLUETOOTH]).
	// Это работает без артефактов потому что content-area внутри обоих
	// блоков имеет ФИКСИРОВАННУЮ высоту (Theme.networkRowHeight *
	// networkMaxVisibleWifi/Bt — см. ниже), поэтому суммарный
	// implicitHeight попапа НЕ меняется при переключении вкладок.
	// xdg_popup resize не происходит → Wayland-compositor не показывает
	// ghost-rendering.
	property string selectedTab: "wifi"

	// Какая сеть сейчас раскрыта с инлайн-плашкой (PSK или forget).
	property var selectedNetwork: null

	// ── Жизненный цикл попапа ───────────────────────────────────────────
	// При открытии всегда стартуем с Wi-Fi-вкладки (явное решение
	// пользователя). При закрытии — отложенный сброс через Timer.
	onIsOpenChanged: {
		if (isOpen) {
			closeCleanupTimer.stop()
			selectedTab = "wifi"
			selectedNetwork = null
			NetworkModel.setScanning(true)
		} else {
			closeCleanupTimer.restart()
		}
	}

	Timer {
		id: closeCleanupTimer
		interval: Theme.animMed + 50
		repeat: false
		onTriggered: {
			NetworkModel.setScanning(false)
			if (BluetoothModel.available && BluetoothModel.discovering) {
				BluetoothModel.toggleDiscovery()
			}
			popup.selectedNetwork = null
		}
	}

	ColumnLayout {
		id: layout
		anchors.fill: parent
		anchors.margins: 12
		spacing: Theme.networkPopupSectionGap

		// ════════════════════════════════════════════════════════════════
		//  Блок [1]: шапка-селектор (Wi-Fi-строка + BT-строка)
		// ════════════════════════════════════════════════════════════════
		Item {
			Layout.fillWidth: true
			implicitHeight: selectorColumn.implicitHeight

			Column {
				id: selectorColumn
				width: parent.width
				spacing: 0

				// ── СТРОКА Wi-Fi ─────────────────────────────────────
				Rectangle {
					id: wifiRow
					width: parent.width
					implicitHeight: wifiRowContent.implicitHeight + Theme.networkActiveBlockPadV * 2
					radius: Theme.networkActiveBlockRadius

					color: popup.selectedTab === "wifi"
						? (NetworkModel.anyConnected
							? Theme.networkActiveBgOk
							: Theme.networkActiveBgError)
						: "transparent"

					opacity: popup.selectedTab === "wifi"
						? 1.0
						: Theme.networkSelectorDimOpacity

					Rectangle {
						visible: popup.selectedTab === "wifi"
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
						id: wifiRowContent
						anchors.fill: parent
						anchors.leftMargin:   Theme.networkActiveBlockBorderW + Theme.networkActiveBlockPadH
						anchors.rightMargin:  Theme.networkActiveBlockPadH
						anchors.topMargin:    Theme.networkActiveBlockPadV
						anchors.bottomMargin: Theme.networkActiveBlockPadV
						spacing: 8

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

						Text {
							visible: popup.selectedTab === "wifi" && NetworkModel.anyConnected
							text: "Отключиться"
							color: Theme.statusError
							font.family: Theme.fontFamily
							font.pixelSize: Theme.networkRowMetaSize
							padding: 4
							Layout.alignment: Qt.AlignVCenter

							HoverHandler { id: wifiDisconnectHover; cursorShape: Qt.PointingHandCursor }
							TapHandler {
								acceptedButtons: Qt.LeftButton
								onTapped: NetworkModel.disconnectActive()
							}
							opacity: wifiDisconnectHover.hovered ? 1.0 : 0.75
						}

						Text {
							visible: popup.selectedTab !== "wifi"
							text: "chevron_right"
							font.family: Theme.iconFamily
							font.pixelSize: Theme.networkRowIconSize
							color: Theme.fgSubtle
							Layout.alignment: Qt.AlignVCenter
						}
					}

					HoverHandler {
						enabled: popup.selectedTab !== "wifi"
						cursorShape: Qt.PointingHandCursor
					}
					TapHandler {
						acceptedButtons: Qt.LeftButton
						onTapped: popup.selectedTab = "wifi"
					}
				}

				// ── Разделитель внутри селектора (только если есть BT) ──
				Rectangle {
					visible: BluetoothModel.available
					width: parent.width
					height: 1
					color: Theme.networkSeparatorColor
					opacity: 0.25
				}

				// ── СТРОКА Bluetooth ─────────────────────────────────
				Rectangle {
					id: btRow
					visible: BluetoothModel.available
					width: parent.width
					implicitHeight: btRowContent.implicitHeight + Theme.networkActiveBlockPadV * 2
					radius: Theme.networkActiveBlockRadius

					color: popup.selectedTab === "bluetooth"
						? Theme.networkActiveBgBt
						: "transparent"

					opacity: popup.selectedTab === "bluetooth"
						? 1.0
						: Theme.networkSelectorDimOpacity

					Rectangle {
						visible: popup.selectedTab === "bluetooth"
						anchors.left: parent.left
						anchors.top: parent.top
						anchors.bottom: parent.bottom
						width: Theme.networkActiveBlockBorderW
						color: Theme.networkActiveBorderBt
						topLeftRadius:    Theme.networkActiveBlockRadius
						bottomLeftRadius: Theme.networkActiveBlockRadius
					}

					RowLayout {
						id: btRowContent
						anchors.fill: parent
						anchors.leftMargin:   Theme.networkActiveBlockBorderW + Theme.networkActiveBlockPadH
						anchors.rightMargin:  Theme.networkActiveBlockPadH
						anchors.topMargin:    Theme.networkActiveBlockPadV
						anchors.bottomMargin: Theme.networkActiveBlockPadV
						spacing: 8

						Text {
							Layout.alignment: Qt.AlignVCenter
							text: {
								if (!BluetoothModel.enabled) return "bluetooth_disabled"
								if (BluetoothModel.hasActiveConnection) {
									return BluetoothModel.deviceGlyph(BluetoothModel.activeDevice)
								}
								return "bluetooth"
							}
							font.family: Theme.iconFamily
							font.pixelSize: Theme.networkActiveIconSize
							color: BluetoothModel.hasActiveConnection
								? Theme.accent
								: Theme.fgSubtle
						}

						ColumnLayout {
							Layout.fillWidth: true
							Layout.alignment: Qt.AlignVCenter
							spacing: 2

							Text {
								Layout.fillWidth: true
								text: {
									if (BluetoothModel.hasActiveConnection) {
										var d = BluetoothModel.activeDevice
										return d.name || d.deviceName || "Устройство"
									}
									return "Bluetooth"
								}
								color: Theme.fg
								font.family: Theme.fontFamily
								font.pixelSize: Theme.networkActiveTitleSize
								font.weight: Font.Medium
								elide: Text.ElideRight
							}

							Text {
								Layout.fillWidth: true
								text: {
									if (!BluetoothModel.enabled) return "Bluetooth выключен"
									if (BluetoothModel.hasActiveConnection) {
										var d = BluetoothModel.activeDevice
										if (d.batteryAvailable) {
											return "Bluetooth · батарея " + Math.round(d.battery * 100) + "%"
										}
										return "Подключено"
									}
									return "Нет подключений"
								}
								color: Theme.fgSubtle
								font.family: Theme.fontFamily
								font.pixelSize: Theme.networkActiveSubtitleSize
								elide: Text.ElideRight
							}
						}

						Text {
							visible: popup.selectedTab === "bluetooth"
								&& BluetoothModel.hasActiveConnection
							text: "Отключить"
							color: Theme.statusError
							font.family: Theme.fontFamily
							font.pixelSize: Theme.networkRowMetaSize
							padding: 4
							Layout.alignment: Qt.AlignVCenter

							HoverHandler { id: btDisconnectHover; cursorShape: Qt.PointingHandCursor }
							TapHandler {
								acceptedButtons: Qt.LeftButton
								onTapped: BluetoothModel.disconnectDevice(BluetoothModel.activeDevice)
							}
							opacity: btDisconnectHover.hovered ? 1.0 : 0.75
						}

						Text {
							visible: popup.selectedTab !== "bluetooth"
							text: "chevron_right"
							font.family: Theme.iconFamily
							font.pixelSize: Theme.networkRowIconSize
							color: Theme.fgSubtle
							Layout.alignment: Qt.AlignVCenter
						}
					}

					HoverHandler {
						enabled: popup.selectedTab !== "bluetooth"
						cursorShape: Qt.PointingHandCursor
					}
					TapHandler {
						acceptedButtons: Qt.LeftButton
						onTapped: popup.selectedTab = "bluetooth"
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
		//  Блок [2-WIFI]
		// ════════════════════════════════════════════════════════════════
		ColumnLayout {
			visible: popup.selectedTab === "wifi"
			Layout.fillWidth: true
			spacing: 4

			RowLayout {
				Layout.fillWidth: true
				Layout.leftMargin:  Theme.networkSectionLabelPadH
				Layout.rightMargin: Theme.networkSectionLabelPadH
				// Фиксированная высота заголовка секции — синхронизирована
				// с BT-секцией (где иконки refresh/add тянут RowLayout
				// выше из-за padding). Без этого общая высота попапа
				// различается на ~4px между вкладками → xdg_popup resize
				// → ghost-rendering остаточного surface.
				Layout.preferredHeight: 22

				Text {
					Layout.fillWidth: true
					Layout.alignment: Qt.AlignVCenter
					text: "ДОСТУПНЫЕ СЕТИ"
					color: Theme.fgSubtle
					font.family: Theme.fontFamily
					font.pixelSize: Theme.networkSectionLabelSize
					font.letterSpacing: 0.5
				}

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

			// ── Контентная область фиксированной высоты ─────────────────
			// Внутри живут либо ListView (когда есть сети), либо один из
			// плейсхолдеров (когда Wi-Fi off / нет устройства / поиск).
			// Все они anchors-позиционированы и занимают одну и ту же
			// область — Wi-Fi-секция НЕ меняет высоту при тогле адаптера
			// или появлении/исчезновении сетей. Это убирает ghost-rendering
			// xdg_popup при resize popup-window: высота попапа стабильна
			// пока пользователь находится внутри одной вкладки.
			Item {
				Layout.fillWidth: true
				Layout.preferredHeight: Theme.networkRowHeight * Theme.networkMaxVisibleWifi

				Text {
					anchors.centerIn: parent
					visible: !NetworkModel.hasWifi
					text: "Wi-Fi-модуль отсутствует"
					color: Theme.fgMuted
					font.family: Theme.fontFamily
					font.pixelSize: Theme.networkRowMetaSize
					font.italic: true
				}

				Text {
					anchors.centerIn: parent
					visible: NetworkModel.hasWifi && !NetworkModel.wifiEnabled
					text: "включите Wi-Fi, чтобы увидеть сети"
					color: Theme.fgMuted
					font.family: Theme.fontFamily
					font.pixelSize: Theme.networkRowMetaSize
					font.italic: true
				}

				Text {
					anchors.centerIn: parent
					visible: NetworkModel.hasWifi && NetworkModel.wifiEnabled
						&& NetworkModel.wifiNetworks.length === 0
					text: "поиск сетей..."
					color: Theme.fgMuted
					font.family: Theme.fontFamily
					font.pixelSize: Theme.networkRowMetaSize
					font.italic: true
				}

				ListView {
					id: wifiListView
					anchors.fill: parent
					visible: NetworkModel.hasWifi && NetworkModel.wifiEnabled
						&& NetworkModel.wifiNetworks.length > 0
					clip: true
					spacing: 0
					interactive: contentHeight > height
					model: NetworkModel.sortedWifiNetworks

					delegate: Column {
						width: ListView.view.width
						spacing: 0

						readonly property var net: modelData
						readonly property bool isActive: net && net.connected
						readonly property bool isKnown: net && net.known
						readonly property bool isSelected: popup.selectedNetwork === net

						Rectangle {
							width: parent.width
							height: Theme.networkRowHeight
							radius: Theme.networkRowRadius
							color: parent.isSelected
								? Theme.networkRowSelectedBg
								: (rowHover.hovered ? Theme.networkRowHoverBg : "transparent")
							Behavior on color { ColorAnimation { duration: Theme.animFast } }

							RowLayout {
								anchors.fill: parent
								anchors.leftMargin: Theme.networkRowPadH
								anchors.rightMargin: Theme.networkRowPadH
								spacing: 6

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

								Text {
									Layout.fillWidth: true
									text: parent.parent.parent.net ? (parent.parent.parent.net.name || "") : ""
									color: parent.parent.parent.isActive || parent.parent.parent.isKnown
										? Theme.fg
										: Theme.fgSubtle
									font.family: Theme.fontFamily
									font.pixelSize: Theme.networkRowFontSize
									font.weight: parent.parent.parent.isActive ? Font.Medium : Font.Normal
									elide: Text.ElideRight
								}

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
									if (parent.parent.net.connected) return
									if (parent.parent.net.security === 0) {
										NetworkModel.connectKnown(parent.parent.net)
										return
									}
									if (popup.selectedNetwork === parent.parent.net) {
										popup.selectedNetwork = null
										wifiListView.forceLayout()
										return
									}
									popup.selectedNetwork = parent.parent.net
								}
							}
						}

						Loader {
							width: parent.width
							active: parent.isSelected
							sourceComponent: parent.net && parent.net.known
								? forgetFormComponent
								: pskFormComponent
							height: active && item ? item.implicitHeight : 0
						}
					}
				}
			}
		}

		// ── Компонент формы ввода пароля ────────────────────────────────
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
								if (text.length > 0 && popup.selectedNetwork) {
									NetworkModel.connectWithPsk(popup.selectedNetwork, text)
									popup.selectedNetwork = null
									wifiListView.forceLayout()
								}
							}
						}
					}

					RowLayout {
						Layout.fillWidth: true
						spacing: 6

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
								onTapped: {
									popup.selectedNetwork = null
									wifiListView.forceLayout()
								}
							}
						}

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
									if (pskInput.text.length > 0 && popup.selectedNetwork) {
										NetworkModel.connectWithPsk(popup.selectedNetwork, pskInput.text)
										popup.selectedNetwork = null
										wifiListView.forceLayout()
									}
								}
							}
						}
					}
				}
			}
		}

		// ── Компонент плашки forget/connect ─────────────────────────────
		Component {
			id: forgetFormComponent

			Rectangle {
				implicitHeight: forgetRow.implicitHeight + 16
				color: Theme.networkRowSelectedBg
				radius: Theme.networkRowRadius

				RowLayout {
					id: forgetRow
					anchors.fill: parent
					anchors.margins: 8
					spacing: 6

					Rectangle {
						Layout.fillWidth: true
						implicitHeight: 24
						radius: Theme.networkRowRadius
						color: forgetHover.hovered ? Theme.networkRowHoverBg : "transparent"
						border.color: Theme.statusError
						border.width: 1
						Behavior on color { ColorAnimation { duration: Theme.animFast } }

						Text {
							anchors.centerIn: parent
							text: "Забыть"
							color: Theme.statusError
							font.family: Theme.fontFamily
							font.pixelSize: Theme.networkRowMetaSize
						}

						HoverHandler { id: forgetHover; cursorShape: Qt.PointingHandCursor }
						TapHandler {
							acceptedButtons: Qt.LeftButton
							onTapped: {
								if (popup.selectedNetwork) {
									NetworkModel.forgetNetwork(popup.selectedNetwork)
									popup.selectedNetwork = null
									wifiListView.forceLayout()
								}
							}
						}
					}

					Rectangle {
						Layout.fillWidth: true
						implicitHeight: 24
						radius: Theme.networkRowRadius
						color: reconnectHover.hovered ? Qt.lighter(Theme.accent, 1.1) : Theme.accent
						Behavior on color { ColorAnimation { duration: Theme.animFast } }

						Text {
							anchors.centerIn: parent
							text: "Подключиться"
							color: Theme.bg
							font.family: Theme.fontFamily
							font.pixelSize: Theme.networkRowMetaSize
							font.weight: Font.Medium
						}

						HoverHandler { id: reconnectHover; cursorShape: Qt.PointingHandCursor }
						TapHandler {
							acceptedButtons: Qt.LeftButton
							onTapped: {
								if (popup.selectedNetwork) {
									NetworkModel.connectKnown(popup.selectedNetwork)
									popup.selectedNetwork = null
									wifiListView.forceLayout()
								}
							}
						}
					}
				}
			}
		}

		// ════════════════════════════════════════════════════════════════
		//  Блок [2-BLUETOOTH]
		// ════════════════════════════════════════════════════════════════
		ColumnLayout {
			visible: popup.selectedTab === "bluetooth"
			Layout.fillWidth: true
			spacing: 4

			RowLayout {
				Layout.fillWidth: true
				Layout.leftMargin:  Theme.networkSectionLabelPadH
				Layout.rightMargin: Theme.networkSectionLabelPadH
				// Тот же Layout.preferredHeight, что у Wi-Fi-заголовка —
				// синхронизация общей высоты попапа между вкладками.
				Layout.preferredHeight: 22
				spacing: 6

				Text {
					Layout.fillWidth: true
					Layout.alignment: Qt.AlignVCenter
					text: "BLUETOOTH-УСТРОЙСТВА"
					color: Theme.fgSubtle
					font.family: Theme.fontFamily
					font.pixelSize: Theme.networkSectionLabelSize
					font.letterSpacing: 0.5
				}

				// Кнопка «скан» — тогл discovering. Только при включённом
				// адаптере. Пульсация opacity показывает что идёт скан.
				Text {
					visible: BluetoothModel.enabled
					text: BluetoothModel.discovering ? "sync" : "refresh"
					font.family: Theme.iconFamily
					font.pixelSize: Theme.networkRowIconSize
					color: BluetoothModel.discovering
						? Theme.accent
						: (scanHover.hovered ? Theme.fg : Theme.fgSubtle)
					padding: 2
					Layout.alignment: Qt.AlignVCenter
					Behavior on color { ColorAnimation { duration: Theme.animFast } }

					SequentialAnimation on opacity {
						running: BluetoothModel.discovering
						loops: Animation.Infinite
						NumberAnimation { from: 1.0; to: 0.5; duration: 800 }
						NumberAnimation { from: 0.5; to: 1.0; duration: 800 }
					}

					HoverHandler { id: scanHover; cursorShape: Qt.PointingHandCursor }
					TapHandler {
						acceptedButtons: Qt.LeftButton
						onTapped: BluetoothModel.toggleDiscovery()
					}
				}

				// Тогл BT-питания (через rfkill — см. BluetoothModel).
				Rectangle {
					width: 32; height: 14
					radius: 7
					color: BluetoothModel.enabled ? Theme.accent : Theme.fgMuted
					Behavior on color { ColorAnimation { duration: Theme.animFast } }
					Layout.alignment: Qt.AlignVCenter

					Rectangle {
						width: 10; height: 10
						radius: 5
						color: Theme.bg
						x: BluetoothModel.enabled ? parent.width - width - 2 : 2
						y: 2
						Behavior on x { NumberAnimation { duration: Theme.animFast } }
					}

					HoverHandler { cursorShape: Qt.PointingHandCursor }
					TapHandler {
						acceptedButtons: Qt.LeftButton
						onTapped: BluetoothModel.togglePower()
					}
				}

				// Кнопка «+» — открывает blueman-manager.
				Text {
					text: "add"
					font.family: Theme.iconFamily
					font.pixelSize: Theme.networkRowIconSize
					color: addHover.hovered ? Theme.fg : Theme.fgSubtle
					padding: 2
					Layout.alignment: Qt.AlignVCenter
					Behavior on color { ColorAnimation { duration: Theme.animFast } }

					HoverHandler { id: addHover; cursorShape: Qt.PointingHandCursor }
					TapHandler {
						acceptedButtons: Qt.LeftButton
						onTapped: BluetoothModel.openPairingHelper()
					}
				}
			}

			// ── Контентная область фиксированной высоты ─────────────────
			// Аналогично Wi-Fi-секции — высота не меняется при тогле BT
			// или появлении/исчезновении устройств.
			Item {
				Layout.fillWidth: true
				Layout.preferredHeight: Theme.networkRowHeight * Theme.networkMaxVisibleBt

				Text {
					anchors.centerIn: parent
					visible: !BluetoothModel.enabled
					text: "включите Bluetooth, чтобы увидеть устройства"
					color: Theme.fgMuted
					font.family: Theme.fontFamily
					font.pixelSize: Theme.networkRowMetaSize
					font.italic: true
				}

				Text {
					anchors.centerIn: parent
					visible: BluetoothModel.enabled
						&& BluetoothModel.sortedDevices.length === 0
					text: BluetoothModel.discovering
						? "поиск устройств..."
						: "нет известных устройств — нажмите ⟳ или +"
					color: Theme.fgMuted
					font.family: Theme.fontFamily
					font.pixelSize: Theme.networkRowMetaSize
					font.italic: true
				}

				ListView {
					id: btListView
					anchors.fill: parent
					visible: BluetoothModel.enabled
						&& BluetoothModel.sortedDevices.length > 0
					clip: true
					spacing: 0
					interactive: contentHeight > height
					model: BluetoothModel.sortedDevices

					delegate: Rectangle {
						width: ListView.view.width
						height: Theme.networkRowHeight
						radius: Theme.networkRowRadius
						color: btRowHover.hovered ? Theme.networkRowHoverBg : "transparent"
						Behavior on color { ColorAnimation { duration: Theme.animFast } }

						readonly property var dev: modelData
						readonly property bool isConnected: dev && dev.connected
						readonly property bool isPaired:    dev && dev.paired
						readonly property bool isPairing:   dev && dev.pairing

						RowLayout {
							anchors.fill: parent
							anchors.leftMargin: Theme.networkRowPadH
							anchors.rightMargin: Theme.networkRowPadH
							spacing: 6

							Text {
								text: BluetoothModel.deviceGlyph(parent.parent.dev)
								font.family: Theme.iconFamily
								font.pixelSize: Theme.networkRowIconSize
								color: parent.parent.isConnected
									? Theme.accent
									: (parent.parent.isPaired
										? Theme.networkSignalFull
										: Theme.networkSignalLow)
							}

							Text {
								Layout.fillWidth: true
								text: {
									var d = parent.parent.dev
									if (!d) return ""
									return d.name || d.deviceName || "Без имени"
								}
								color: parent.parent.isConnected || parent.parent.isPaired
									? Theme.fg
									: Theme.fgSubtle
								font.family: Theme.fontFamily
								font.pixelSize: Theme.networkRowFontSize
								font.weight: parent.parent.isConnected ? Font.Medium : Font.Normal
								elide: Text.ElideRight
							}

							RowLayout {
								visible: parent.parent.isConnected
									&& parent.parent.dev
									&& parent.parent.dev.batteryAvailable
								spacing: 3
								Text {
									text: "battery_5_bar"
									font.family: Theme.iconFamily
									font.pixelSize: Theme.networkBatteryIconSize
									color: Theme.fgSubtle
								}
								Text {
									text: parent.parent.parent.dev
										? Math.round(parent.parent.parent.dev.battery * 100) + "%"
										: ""
									color: Theme.fgSubtle
									font.family: Theme.fontFamily
									font.pixelSize: Theme.networkRowMetaSize
								}
							}

							Text {
								visible: !(parent.parent.isConnected
									&& parent.parent.dev
									&& parent.parent.dev.batteryAvailable)
								text: {
									if (parent.parent.isPairing)   return "сопряжение..."
									if (parent.parent.isConnected) return "подключено"
									if (parent.parent.isPaired)    return "сопряжено"
									return "найдено"
								}
								color: Theme.fgMuted
								font.family: Theme.fontFamily
								font.pixelSize: Theme.networkRowMetaSize
							}
						}

						HoverHandler { id: btRowHover; cursorShape: Qt.PointingHandCursor }
						TapHandler {
							acceptedButtons: Qt.LeftButton
							onTapped: {
								var d = parent.dev
								if (!d) return
								if (d.connected) {
									BluetoothModel.disconnectDevice(d)
								} else if (d.paired) {
									BluetoothModel.connectDevice(d)
								} else {
									BluetoothModel.pairDevice(d)
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

				Text {
					text: "more_horiz"
					font.family: Theme.iconFamily
					font.pixelSize: Theme.networkRowIconSize
					color: editorHover.hovered ? Theme.fg : Theme.fgSubtle
					padding: 2
					Behavior on color { ColorAnimation { duration: Theme.animFast } }

					HoverHandler { id: editorHover; cursorShape: Qt.PointingHandCursor }
					TapHandler {
						acceptedButtons: Qt.LeftButton
						onTapped: VpnModel.openEditor("")
					}
				}
			}

			Text {
				visible: VpnModel.profiles.length === 0
				Layout.fillWidth: true
				horizontalAlignment: Text.AlignHCenter
				text: "Нет VPN-профилей. Добавьте через ⋯"
				color: Theme.fgMuted
				font.family: Theme.fontFamily
				font.pixelSize: Theme.networkRowMetaSize
				font.italic: true
				padding: 6
			}

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

				delegate: Rectangle {
					width: ListView.view.width
					height: Theme.networkRowHeight
					radius: Theme.networkRowRadius
					color: vpnRowHover.hovered ? Theme.networkRowHoverBg : "transparent"
					Behavior on color { ColorAnimation { duration: Theme.animFast } }

					readonly property var profile: modelData

					RowLayout {
						anchors.fill: parent
						anchors.leftMargin: Theme.networkRowPadH
						anchors.rightMargin: Theme.networkRowPadH
						spacing: 6

						Rectangle {
							width: 8; height: 8
							radius: 4
							color: parent.parent.profile && parent.parent.profile.active
								? Theme.statusOk
								: "transparent"
							border.color: Theme.fgMuted
							border.width: parent.parent.profile && parent.parent.profile.active ? 0 : 1.5
						}

						Text {
							text: parent.parent.profile ? parent.parent.profile.name : ""
							color: parent.parent.profile && parent.parent.profile.active
								? Theme.fg
								: Theme.fgSubtle
							font.family: Theme.fontFamily
							font.pixelSize: Theme.networkRowFontSize
							font.weight: parent.parent.profile && parent.parent.profile.active
								? Font.Medium : Font.Normal
							elide: Text.ElideRight
						}

						Text {
							Layout.fillWidth: true
							text: parent.parent.profile ? parent.parent.profile.type : ""
							color: Theme.fgMuted
							font.family: Theme.fontFamily
							font.pixelSize: Theme.networkRowMetaSize
						}
					}

					HoverHandler { id: vpnRowHover; cursorShape: Qt.PointingHandCursor }
					TapHandler {
						acceptedButtons: Qt.LeftButton
						onTapped: {
							if (!parent.profile) return
							if (parent.profile.active) {
								VpnModel.disconnectProfile(parent.profile.uuid)
							} else {
								VpnModel.connectProfile(parent.profile.uuid)
							}
						}
					}
				}
			}
		}
	}
}
