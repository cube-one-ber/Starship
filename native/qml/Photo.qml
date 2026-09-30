import QtQuick

Item {
    id: photo
    objectName: "journalPhoto"
    property string path: ""
    property bool useJxl: false
    property string description: ""
    readonly property alias status: image.status
    clip: true
    Image {
        id: image
        anchors.fill: parent
        asynchronous: true
        source: photo.path ? (photo.useJxl ? "image://jxl" + photo.path + ".jxl" : "qrc:" + photo.path + ".jpg") : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: Math.max(1, Math.round(photo.width * Screen.devicePixelRatio))
        Accessible.role: Accessible.Graphic
        Accessible.name: photo.description
        onStatusChanged: if (status === Image.Error && photo.useJxl) photo.useJxl = false
    }
}
