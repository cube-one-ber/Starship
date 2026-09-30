import QtQuick
import org.kde.kirigami as Kirigami

// Qt Quick's text-change behavior, timed with KDE's animation preference.
Behavior {
    id: behavior
    property bool motionEnabled: true
    property QtObject fadeTarget: targetProperty.object
    enabled: motionEnabled && Kirigami.Units.shortDuration > 0
    onMotionEnabledChanged: if (!motionEnabled) fade.complete()
    SequentialAnimation {
        id: fade
        NumberAnimation { target: behavior.fadeTarget; property: "opacity"; to: 0; duration: Kirigami.Units.shortDuration / 2; easing.type: Easing.InQuad }
        PropertyAction {}
        NumberAnimation { target: behavior.fadeTarget; property: "opacity"; to: 1; duration: Kirigami.Units.shortDuration; easing.type: Easing.OutQuad }
    }
}
