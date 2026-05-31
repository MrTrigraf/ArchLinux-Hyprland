pragma Singleton
import Quickshell
import QtQuick

// PopupManager - координатор попапов.
// Singleton на весь shell. Гарантирует, что одновременно открыт один попап.
Singleton {
    id: root

    // Текущий открытый попап (или null).
    property var currentPopup: null

    function open(popup) {
        if (!popup) return
        if (currentPopup == popup) return
        if (currentPopup) {
            currentPopup.close()
        }
        currentPopup = popup
        popup.open()
    }

    function close() {
        if (currentPopup) {
            var p = currentPopup
            currentPopup = null
            p.close()
        }
    }

    function toggle(popup) {
        if (!popup) return
        if (currentPopup == popup) {
            close()
        } else {
            open(popup)
        }
    }

    // Вызывается из PopupBase в onIsOpenChanged при isOpen -> false.
    function notifyClosed(popup) {
        if (currentPopup == popup) {
            currentPopup = null
        }
    }
}
