pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: panel
    property bool motionEnabled: true
    property real offsetX: 0
    property real offsetY: Kirigami.Units.largeSpacing
    property int direction: 0
    property var pendingChange: null
    readonly property bool transitioning: departure.running || arrival.running
    opacity: 0
    // Visual translation leaves the layout-owned x/y and dimensions untouched.
    // qmllint disable Quick.layout-positioning
    transform: Translate { x: panel.offsetX; y: panel.offsetY }
    // qmllint enable Quick.layout-positioning

    // Replace all related content together. Rapid requests keep the latest update.
    function swap(change, travelDirection = 0) {
        pendingChange = change
        if (!motionEnabled || Kirigami.Units.longDuration === 0) {
            finishImmediately()
            return
        }
        if (departure.running) return
        direction = travelDirection
        arrival.stop()
        departure.start()
    }
    function finishImmediately() {
        departure.stop()
        arrival.stop()
        const change = pendingChange
        pendingChange = null
        if (change) change()
        opacity = 1
        offsetX = 0
        offsetY = 0
    }
    Component.onCompleted: {
        if (motionEnabled && Kirigami.Units.longDuration > 0) arrival.start()
        else finishImmediately()
    }
    onMotionEnabledChanged: if (!motionEnabled) finishImmediately()

    ParallelAnimation {
        id: departure
        NumberAnimation { target: panel; property: "opacity"; to: 0; duration: Kirigami.Units.shortDuration; easing.type: Easing.InCubic }
        NumberAnimation { target: panel; property: "offsetX"; to: -panel.direction * Kirigami.Units.gridUnit; duration: Kirigami.Units.shortDuration; easing.type: Easing.InCubic }
        NumberAnimation { target: panel; property: "offsetY"; to: panel.direction === 0 ? -Kirigami.Units.smallSpacing : 0; duration: Kirigami.Units.shortDuration; easing.type: Easing.InCubic }
        onFinished: {
            const change = panel.pendingChange
            panel.pendingChange = null
            if (change) change()
            panel.offsetX = panel.direction * Kirigami.Units.gridUnit
            panel.offsetY = panel.direction === 0 ? Kirigami.Units.largeSpacing : 0
            arrival.start()
        }
    }
    ParallelAnimation {
        id: arrival
        NumberAnimation { target: panel; property: "opacity"; to: 1; duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
        NumberAnimation { target: panel; property: "offsetX"; to: 0; duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
        NumberAnimation { target: panel; property: "offsetY"; to: 0; duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
    }
}
