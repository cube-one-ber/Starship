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
    property real cornerRadius: 0
    property color cornerColor: "#0a1018"
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
    // Paint just the outside corners; this also works with Qt's software renderer.
    Canvas {
        id: corners
        anchors.fill: parent
        z: 100
        visible: photo.cornerRadius > 0
        Accessible.ignored: true
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Connections {
            target: photo
            function onCornerRadiusChanged() { corners.requestPaint() }
            function onCornerColorChanged() { corners.requestPaint() }
        }
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const r = Math.min(photo.cornerRadius, width / 2, height / 2)
            ctx.fillStyle = photo.cornerColor
            const positions = [[0, 0], [width, 0], [width, height], [0, height]]
            for (let i = 0; i < 4; i++) {
                ctx.save()
                ctx.translate(positions[i][0], positions[i][1])
                ctx.rotate(i * Math.PI / 2)
                ctx.beginPath()
                ctx.moveTo(0, 0)
                ctx.lineTo(r, 0)
                ctx.arc(r, r, r, -Math.PI / 2, -Math.PI, true)
                ctx.closePath()
                ctx.fill()
                ctx.restore()
            }
        }
    }
}
