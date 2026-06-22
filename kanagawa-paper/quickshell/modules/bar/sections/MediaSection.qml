import QtQuick
import QtQuick.Layouts
import "../components"
import "../../../components"
import "../../services"
import "../../../theme"

// ─────────────────────────────────────────────────────────────────────────────
// MediaSection — секция между LeftSection и CenterSection. Видна тогда и только
// тогда, когда cmus подключён по MPRIS и есть непустое название трека
// (MprisModel.available). PlaybackState (Playing/Paused) на видимость не влияет
// — на паузе секция остаётся, кнопка play оживляет трек.
// ─────────────────────────────────────────────────────────────────────────────
ColumnLayout {
	id: root
	spacing: 5

	// ─── Видимость и плавное появление/исчезание ──────────────────────────
	// enabled блокирует обработку кликов когда opacity=0 (Qt не отключает
	// события при opacity=0 сам — без enabled можно случайно «попасть»
	// по невидимой кнопке).
	enabled: MprisModel.available
	opacity: MprisModel.available ? 1.0 : 0.0
	scale:   MprisModel.available ? 1.0 : Theme.trayAppearScaleFrom

	Behavior on opacity {
		NumberAnimation { duration: Theme.trayAppearDuration; easing.type: Easing.OutCubic }
	}
	Behavior on scale {
		NumberAnimation { duration: Theme.trayAppearDuration; easing.type: Easing.OutBack }
	}

	// ─── Ряд: 3 кнопки управления + marquee с названием ───────────────────
	RowLayout {
		spacing: 0   // зазоры задаются на каждом элементе через Layout.leftMargin
		Layout.alignment: Qt.AlignLeft | Qt.AlignBottom

		// ─── Кнопка skip_previous ─────────────────────────────────────────
		Item {
			id: prevBtn
			implicitWidth:  Theme.iconSizeBar
			implicitHeight: Theme.iconSizeBar
			readonly property bool isHovered: prevHover.hovered

			BarIcon {
				anchors.centerIn: parent
				name: "skip_previous"
				iconColor: prevBtn.isHovered ? Theme.accent : Theme.fg
				// hover-анимация цвета встроена в BarIcon (Behavior on color)
			}

			HoverHandler { id: prevHover; cursorShape: Qt.PointingHandCursor }
			TapHandler {
				acceptedButtons: Qt.LeftButton
				onTapped: MprisModel.previous()
			}
		}

		// ─── Кнопка play / pause ──────────────────────────────────────────
		// Глиф переключается реактивно по MprisModel.playing.
		Item {
			id: playBtn
			implicitWidth:  Theme.iconSizeBar
			implicitHeight: Theme.iconSizeBar
			Layout.leftMargin: Theme.mediaButtonGap
			readonly property bool isHovered: playHover.hovered

			BarIcon {
				anchors.centerIn: parent
				name: MprisModel.playing ? "pause" : "play_arrow"
				iconColor: playBtn.isHovered ? Theme.accent : Theme.fg
			}

			HoverHandler { id: playHover; cursorShape: Qt.PointingHandCursor }
			TapHandler {
				acceptedButtons: Qt.LeftButton
				onTapped: MprisModel.playPause()
			}
		}

		// ─── Кнопка skip_next ─────────────────────────────────────────────
		Item {
			id: nextBtn
			implicitWidth:  Theme.iconSizeBar
			implicitHeight: Theme.iconSizeBar
			Layout.leftMargin: Theme.mediaButtonGap
			readonly property bool isHovered: nextHover.hovered

			BarIcon {
				anchors.centerIn: parent
				name: "skip_next"
				iconColor: nextBtn.isHovered ? Theme.accent : Theme.fg
			}

			HoverHandler { id: nextHover; cursorShape: Qt.PointingHandCursor }
			TapHandler {
				acceptedButtons: Qt.LeftButton
				onTapped: MprisModel.next()
			}
		}

		// ─── Marquee-окно с названием трека ───────────────────────────────
		// implicitWidth = min(contentWidth, maxWidth):
		//   короткие треки занимают только нужное место (компактнее);
		//   длинные — ровно maxWidth, остаток скрыт clip и движется marquee.
		Item {
			id: marqueeViewport
			Layout.leftMargin: Theme.mediaTitleLeftPadding
			Layout.alignment: Qt.AlignVCenter
			implicitWidth:  Math.min(titleText.contentWidth, Theme.mediaTitleMaxWidth)
			implicitHeight: titleText.implicitHeight
			clip: true

			Row {
				id: marqueeRow
				spacing: Theme.mediaMarqueeGap

				// Реактивно: текст шире окна → нужен скролл.
				readonly property bool scrolling: titleText.contentWidth > marqueeViewport.width
				// Полная длина одного цикла (текст + gap).
				// При x = -cycleWidth начало 2-го Text совпадает с тем,
				// где было начало 1-го → бесшовный loop.
				readonly property real cycleWidth: titleText.contentWidth + spacing

				Text {
					id: titleText
					text: MprisModel.trackTitle
					color: Theme.fg
					font.family: Theme.fontFamily
					font.pixelSize: Theme.mediaTitleFontSize
					verticalAlignment: Text.AlignVCenter
				}
				Text {
					// Дубль для seamless-loop. Показывается только когда
					// marquee активен — иначе торчит лишним «эхо» справа
					// от первого текста на коротких треках.
					text: MprisModel.trackTitle
					visible: marqueeRow.scrolling
					color: Theme.fg
					font.family: Theme.fontFamily
					font.pixelSize: Theme.mediaTitleFontSize
					verticalAlignment: Text.AlignVCenter
				}

				// Сброс x в 0 когда marquee выключается (короткий трек /
				// смена с длинного на короткий). Анимация останавливается
				// через running: scrolling, но x может «застрять».
				Binding {
					target: marqueeRow
					property: "x"
					value: 0
					when: !marqueeRow.scrolling
				}

				// Рестарт анимации при смене длины трека.
				// NumberAnimation с loops:Infinite не перечитывает from/to
				// внутри запущенной петли, поэтому форсируем stop/start.
				onCycleWidthChanged: {
					marqueeAnim.stop()
					marqueeRow.x = 0
					if (scrolling) marqueeAnim.start()
				}
			}

			SequentialAnimation {
				id: marqueeAnim
				running: marqueeRow.scrolling
				loops: Animation.Infinite

				NumberAnimation {
					target: marqueeRow
					property: "x"
					from: 0
					to: -marqueeRow.cycleWidth
					duration: marqueeRow.cycleWidth * Theme.mediaMarqueeSpeedMsPerPx
				}
			}
		}
	}

	// ─── Подчёркивание секции (лавандовая линия снизу, как у Tray) ────────
	SectionUnderline {
		Layout.fillWidth: true
		Layout.leftMargin: Theme.sectionPaddingH
		Layout.rightMargin: Theme.sectionPaddingH
	}
}