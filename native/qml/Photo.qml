import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: photo
    objectName: "journalPhoto"
    property string path: ""
    property bool useJxl: false
    property string description: ""
    property bool emphasized: false
    property bool motionEnabled: true
    property real restingScale: 1
    property url retainedSource: ""
    readonly property alias status: image.status
    readonly property real imageScale: image.scale
    clip: true
    onMotionEnabledChanged: if (!motionEnabled) { photoFade.complete(); zoom.complete() }

    // Retain the last completed frame until the replacement has loaded and faded in.
    Image {
        anchors.fill: parent
        source: photo.retainedSource
        visible: source.toString().length > 0 && image.opacity < 1
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        scale: image.scale
        sourceSize: image.sourceSize
        Accessible.ignored: true
    }
    Image {
        id: image
        anchors.fill: parent
        asynchronous: true
        source: photo.path ? (photo.useJxl ? "image://jxl" + photo.path + ".jxl" : "qrc:" + photo.path + ".jpg") : ""
        fillMode: Image.PreserveAspectCrop
        opacity: status === Image.Ready ? 1 : 0
        scale: photo.motionEnabled ? photo.restingScale + (photo.emphasized ? 0.045 : 0) : 1
        Behavior on opacity {
            enabled: photo.motionEnabled
            NumberAnimation {
                id: photoFade
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
                onFinished: if (image.status === Image.Ready) photo.retainedSource = image.source
            }
        }
        Behavior on scale {
            enabled: photo.motionEnabled
            NumberAnimation { id: zoom; duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
        }
        sourceSize.width: Math.max(1, Math.round(photo.width * Screen.devicePixelRatio))
        Accessible.role: Accessible.Graphic
        Accessible.name: photo.description
        onStatusChanged: {
            if (status === Image.Error && photo.useJxl) photo.useJxl = false
            if (status === Image.Ready && !photo.motionEnabled) photo.retainedSource = source
        }
    }
}
