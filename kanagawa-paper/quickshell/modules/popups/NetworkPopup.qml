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
//   [2] Wi-Fi сети           ← список + инлайн-плашка под выбранной сетью
//   ── разделитель ──
//   [3] VPN-профили          ← список + кнопка "⋯" (открывает nm-connection-editor)
//
// Логика выбора сети в блоке [2]:
//   - активная               → клик игнорируется (отключение через блок [1])
//   - открытая (security==0) → подключение напрямую, без плашки
//   - известная защищённая   → плашка forget/connect (две кнопки)
//   - неизвестная защищённая → плашка ввода пароля
//
// Визуальное отличие known сетей: яркое имя (Theme.fg). Unknown — приглушённое
// (Theme.fgSubtle). Активная — дополнительно Font.Medium.
//
// API:
//   - NetworkModel: данные о Wi-Fi/Ethernet, sortedWifiNetworks для списка,
//                   connectKnown/connectWithPsk/disconnectActive/toggleWifi/
//                   forgetNetwork.
//   - VpnModel:     profiles[], connectProfile/disconnectProfile/openEditor.
//                   CRUD профилей делается в nm-connection-editor.
// ─────────────────────────────────────────────────────────────────────────────
PopupBase {
	id: popup

	contentWidth:  Theme.networkPopupWidth
	contentHeight: layout.implicitHeight + 24

	// Какая сеть сейчас в выделенном состоянии (с раскрытой инлайн-плашкой).
	// null — плашек нет; объект WifiNetwork — плашка раскрыта под этой строкой.
	// Тип плашки выбирается Loader'ом по net.known.
	property var selectedNetwork: null

	// При открытии включаем Wi-Fi-сканер и сбрасываем "хвосты" прошлого сеанса
	// (раскрытую плашку). При закрытии — отложенный сброс через Timer, иначе
	// layout схлопывается одновременно с анимацией закрытия и виден
	// "половинный" попап.
	onIsOpenChanged: {
		if (isOpen) {
			closeCleanupTimer.stop()    // если успели снова открыть — отменяем сброс
			// Состояние раскрытых плашек сбрасываем мгновенно — попап
			// всегда открывается "чистым", без хвостов от прошлого раза.
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
			popup.selectedNetwork = null
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

			// Плейсхолдер на время инициализации сканера: Wi-Fi уже включён,
			// но первый ответ от nm не пришёл — иначе попап мигает пустым
			// блоком сетей пока идёт скан.
			Text {
				visible: NetworkModel.hasWifi && NetworkModel.wifiEnabled
					&& NetworkModel.wifiNetworks.length === 0
				Layout.fillWidth: true
				horizontalAlignment: Text.AlignHCenter
				text: "поиск сетей..."
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
					&& NetworkModel.wifiNetworks.length > 0
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
					readonly property bool isKnown: net && net.known
					readonly property bool isSelected: popup.selectedNetwork === net

					// ── Строка сети ────────────────────────────────────
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
							// Цвет: активная или known → яркий Theme.fg;
							// unknown → приглушённый Theme.fgSubtle (это и есть
							// визуальное отличие "знакомых" сетей от незнакомых).
							// Bold — только у активной.
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
								// Открытая сеть — подключаемся напрямую, без плашки.
								if (parent.parent.net.security === 0) {
									NetworkModel.connectKnown(parent.parent.net)
									return
								}
								// Повторный тап по уже выделенной сети — закрываем плашку (toggle).
								if (popup.selectedNetwork === parent.parent.net) {
									popup.selectedNetwork = null
									wifiListView.forceLayout()
									return
								}
								// Защищённая (known или unknown) — раскрываем плашку.
								// Конкретный компонент выбирает Loader по net.known.
								popup.selectedNetwork = parent.parent.net
							}
						}
					}

					// ── Инлайн-плашка под строкой ──────────────────────
					// Тип плашки выбирается по net.known:
					//   - known   → forgetFormComponent (две кнопки)
					//   - unknown → pskFormComponent    (поле пароля + две кнопки)
					//
					// Явный height нужен, чтобы Column-delegate пересчитал свою
					// implicitHeight сразу после деактивации Loader'а. Без этого
					// пустое место остаётся до следующего события в ListView.
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

		// ── Компонент формы ввода пароля (для unknown защищённой сети) ──
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
								if (text.length > 0 && popup.selectedNetwork) {
									NetworkModel.connectWithPsk(popup.selectedNetwork, text)
									popup.selectedNetwork = null
									wifiListView.forceLayout()
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
								onTapped: {
									popup.selectedNetwork = null
									wifiListView.forceLayout()
								}
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

		// ── Компонент плашки forget/connect (для known защищённой сети) ─
		// Без подписи, только две кнопки: "Забыть" (красная) + "Подключиться".
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

					// Забыть — красная (border + текст в statusError).
					// После forget сеть становится unknown; selectedNetwork
					// сбрасываем, чтобы Loader не переключился на pskFormComponent.
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

					// Подключиться — accent. Известная сеть, пароль уже в NM,
					// никаких запросов не будет.
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

			// Заголовок секции + кнопка "⋯" справа.
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

				// Кнопка "⋯": открывает nm-connection-editor. Всё управление
				// VPN-профилями (создание, правка, удаление) — там. В попапе
				// оставляем только подключение/отключение.
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

			// Плейсхолдер, если профилей нет.
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

				// Делегат — Rectangle напрямую, без Column-обёртки. Меню
				// "три точки" убрано: всё управление профилями делается
				// через nm-connection-editor.
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

						// Индикатор-точка: filled при активном, контур при неактивном.
						Rectangle {
							width: 8; height: 8
							radius: 4
							color: parent.parent.profile && parent.parent.profile.active
								? Theme.statusOk
								: "transparent"
							border.color: Theme.fgMuted
							border.width: parent.parent.profile && parent.parent.profile.active ? 0 : 1.5
						}

						// Имя профиля.
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

						// Мета: тип VPN ("vpn" / "wireguard").
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
