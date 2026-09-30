pragma ComponentBehavior: Bound
import QtQuick
import org.starship.journal
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.AbstractCard {
    id: card
    objectName: "flightCard"
    required property var flight
    property bool useJxl: false
    property int entranceIndex: 0
    property bool motionEnabled: true
    property bool inViewport: true
    property bool revealed: false
    property real entranceOffset: Kirigami.Units.largeSpacing * 2
    property real interactionOffset: motionEnabled ? (down ? 1 : hovered || activeFocus ? -Kirigami.Units.smallSpacing / 2 : 0) : 0
    transform: Translate { y: card.entranceOffset + card.interactionOffset }
    scale: motionEnabled && down ? 0.985 : 1
    z: hovered || activeFocus ? 1 : 0
    opacity: 0
    Behavior on interactionOffset { enabled: card.motionEnabled; NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
    Behavior on scale { enabled: card.motionEnabled; NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
    function reveal() {
        if (revealed) return
        revealed = true
        if (motionEnabled && Kirigami.Units.longDuration > 0) entrance.start()
        else { opacity = 1; entranceOffset = 0 }
    }
    SequentialAnimation {
        id: entrance
        PauseAnimation { duration: Math.min(card.entranceIndex, 2) * Kirigami.Units.shortDuration / 2 }
        ParallelAnimation {
            NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
            NumberAnimation { target: card; property: "entranceOffset"; to: 0; duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
        }
    }
    Component.onCompleted: if (inViewport || !motionEnabled) reveal()
    onInViewportChanged: if (inViewport) reveal()
    onActiveFocusChanged: if (activeFocus) reveal()
    onMotionEnabledChanged: if (!motionEnabled) { entrance.stop(); revealed = true; opacity = 1; entranceOffset = 0 }
    readonly property alias status: photo.status
    readonly property bool jxlLoaded: photo.useJxl
    signal activated(var flight)
    padding: 0
    showClickFeedback: true
    Accessible.name: "Flight " + flight.id + ": " + flight.title
    background: Rectangle {
        parent: card
        radius: SpaceStyle.radius
        color: card.down ? "#25303b" : card.hovered || card.activeFocus ? SpaceStyle.raised : SpaceStyle.surface
        Behavior on color { enabled: card.motionEnabled; ColorAnimation { duration: Kirigami.Units.shortDuration } }
        border.width: 1
        border.color: card.hovered || card.activeFocus ? SpaceStyle.accent : SpaceStyle.line
        Behavior on border.color { enabled: card.motionEnabled; ColorAnimation { duration: Kirigami.Units.shortDuration } }
    }
    onClicked: activated(flight)
    contentItem: ColumnLayout {
        spacing: 0
        Photo {
            id: photo
            Layout.fillWidth: true
            Layout.preferredHeight: card.width * 9 / 16
            path: card.flight.photo.path
            useJxl: card.useJxl
            description: card.flight.photo.alt
            emphasized: card.hovered || card.activeFocus
            motionEnabled: card.motionEnabled
            Rectangle {
                anchors.fill: parent
                gradient: Gradient { GradientStop { position: 0.3; color: "transparent" } GradientStop { position: 1; color: "#b0090e16" } }
            }
            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 18
                SectionLabel { Layout.fillWidth: true; text: "INTEGRATED FLIGHT TEST"; color: "#dbe2eb"; font.pointSize: 6.75; font.letterSpacing: 1 }
                Rectangle { implicitWidth: 6; implicitHeight: 6; radius: 3; color: card.flight.outcome === "Vehicle lost" ? SpaceStyle.accent : SpaceStyle.positive }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: 20
            spacing: 12
            RowLayout {
                Layout.fillWidth: true
                SectionLabel { Layout.fillWidth: true; text: "FLIGHT / " + String(card.flight.id).padStart(3, "0"); font.pointSize: 7.5; font.letterSpacing: 1 }
                Controls.Label { text: new Date(card.flight.date + "T12:00:00Z").toLocaleDateString(Qt.locale(), "dd MMM yyyy").toUpperCase(); color: SpaceStyle.dim; font.family: SpaceStyle.mono; font.pointSize: 6.75}
            }
            Kirigami.Heading {
                id: heading
                Layout.fillWidth: true
                Layout.minimumHeight: headingMetrics.lineSpacing * 2
                level: 2
                type: Kirigami.Heading.Primary
                text: card.flight.title
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                font.family: SpaceStyle.serif
                font.pointSize: 18.75
                font.letterSpacing: -0.3
                color: card.hovered || card.activeFocus ? SpaceStyle.accent : SpaceStyle.text
                Behavior on color { enabled: card.motionEnabled; ColorAnimation { duration: Kirigami.Units.shortDuration } }
                elide: Text.ElideRight
            }
            FontMetrics { id: headingMetrics; font: heading.font }
            Controls.Label { font.family: SpaceStyle.sans;
                id: summary
                Layout.fillWidth: true
                Layout.minimumHeight: summaryMetrics.lineSpacing * 3 * 1.25 + 4
                text: card.flight.summary
                wrapMode: Text.WordWrap
                lineHeight: 1.25
                maximumLineCount: 3
                elide: Text.ElideRight
                font.pointSize: 9.75
                color: SpaceStyle.muted
            }
            FontMetrics { id: summaryMetrics; font: summary.font }
            RowLayout {
                Layout.fillWidth: true
                Rectangle { implicitWidth: 4; implicitHeight: 4; radius: 2; color: SpaceStyle.cyan }
                Controls.Label { font.family: SpaceStyle.sans; Layout.fillWidth: true; text: card.flight.milestone; elide: Text.ElideRight; color: SpaceStyle.cyan; font.pointSize: 8.25}
            }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: SpaceStyle.line }
            RowLayout {
                Layout.fillWidth: true
                Controls.ToolButton { font.family: SpaceStyle.sans; text: "Read debrief"; icon.name: "go-next"; font.pointSize: 9; onClicked: card.activated(card.flight) }
                Item { Layout.fillWidth: true }
                Controls.ToolButton { font.family: SpaceStyle.sans;
                    text: "Photo credit"
                    icon.name: "camera-photo"
                    display: Controls.AbstractButton.IconOnly
                    onClicked: Qt.openUrlExternally(card.flight.photo.url)
                    Controls.ToolTip.text: card.flight.photo.credit
                    Controls.ToolTip.visible: hovered
                }
            }
        }
    }
}
