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
    property bool latest: false
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
    Accessible.description: "Ship: " + flight.ship + ". Booster: " + flight.booster + ". " + flight.summary + " Milestone: " + flight.milestone
    background: Rectangle {
        id: cardBackground
        parent: card
        radius: SpaceStyle.radius
        color: card.down ? "#25303b" : card.hovered || card.activeFocus ? SpaceStyle.raised : SpaceStyle.surface
        Behavior on color { enabled: card.motionEnabled; ColorAnimation { duration: Kirigami.Units.shortDuration } }
        border.width: 1
        border.color: card.hovered || card.activeFocus ? SpaceStyle.accent : card.latest ? "#75674f" : SpaceStyle.line
        Behavior on border.color { enabled: card.motionEnabled; ColorAnimation { duration: Kirigami.Units.shortDuration } }
    }
    onClicked: activated(flight)
    contentItem: ColumnLayout {
        spacing: 0
        Photo {
            id: photo
            Layout.fillWidth: true
            Layout.preferredHeight: (card.width - 12) * 0.5
            Layout.margins: 6
            Layout.bottomMargin: 0
            cornerRadius: 8
            cornerColor: cardBackground.color
            path: card.flight.photo.path
            useJxl: card.useJxl
            description: card.flight.photo.alt
            emphasized: card.hovered || card.activeFocus
            motionEnabled: card.motionEnabled
            Rectangle {
                anchors.fill: parent
                gradient: Gradient { GradientStop { position: 0.3; color: "transparent" } GradientStop { position: 1; color: "#b0090e16" } }
            }
            Controls.Label {
                visible: card.latest
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 12
                text: "LATEST / " + String(card.flight.id).padStart(3, "0")
                font.family: SpaceStyle.mono
                font.pointSize: 9
                font.letterSpacing: 0.5
                color: SpaceStyle.softAccent
                padding: 7
                leftPadding: 10
                rightPadding: 10
                background: Rectangle { radius: 13; color: "#e0121d29"; border.color: "#80eac38e" }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: 16
            spacing: 10
            RowLayout {
                Layout.fillWidth: true
                SectionLabel { Layout.fillWidth: true; text: "FLIGHT / " + String(card.flight.id).padStart(3, "0"); font.pointSize: 9; font.letterSpacing: 0.5 }
                Controls.Label { text: new Date(card.flight.date + "T12:00:00Z").toLocaleDateString(Qt.locale(), "dd MMM yyyy").toUpperCase(); color: SpaceStyle.dim; font.family: SpaceStyle.mono; font.pointSize: 9}
            }
            Kirigami.Heading {
                id: heading
                Layout.fillWidth: true
                level: 2
                type: Kirigami.Heading.Primary
                text: card.flight.title
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                font.family: SpaceStyle.serif
                font.pointSize: 21
                font.letterSpacing: -0.3
                color: card.hovered || card.activeFocus ? SpaceStyle.accent : SpaceStyle.text
                Behavior on color { enabled: card.motionEnabled; ColorAnimation { duration: Kirigami.Units.shortDuration } }
                elide: Text.ElideRight
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                Repeater {
                    model: [{ label: "Ship", result: card.flight.ship }, { label: "Booster", result: card.flight.booster }]
                    delegate: RowLayout {
                        id: vehicleResult
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 8
                        Controls.Label { text: vehicleResult.modelData.label; Layout.preferredWidth: 54; font.family: SpaceStyle.sans; font.pointSize: 9.75; color: SpaceStyle.dim }
                        Controls.Label {
                            Layout.fillWidth: true
                            text: vehicleResult.modelData.result
                            font.family: SpaceStyle.sans
                            font.pointSize: 9.75
                            font.weight: Font.Medium
                            wrapMode: Text.WordWrap
                            color: /lost|terminated|did not|hard|impact/i.test(text) ? SpaceStyle.accent : SpaceStyle.positive
                        }
                    }
                }
            }
            Controls.Label { font.family: SpaceStyle.sans;
                id: summary
                Layout.fillWidth: true
                Layout.minimumHeight: summaryMetrics.lineSpacing * 2 * 1.25 + 4
                text: card.flight.summary
                wrapMode: Text.WordWrap
                lineHeight: 1.25
                maximumLineCount: 2
                elide: Text.ElideRight
                font.pointSize: 10.5
                color: SpaceStyle.muted
                Controls.ToolTip.text: text
                Controls.ToolTip.visible: summaryHover.hovered
                HoverHandler { id: summaryHover }
            }
            FontMetrics { id: summaryMetrics; font: summary.font }
            RowLayout {
                Layout.fillWidth: true
                Rectangle { implicitWidth: 4; implicitHeight: 4; radius: 2; color: SpaceStyle.cyan }
                Controls.Label { font.family: SpaceStyle.sans; Layout.fillWidth: true; text: card.flight.milestone; elide: Text.ElideRight; color: SpaceStyle.cyan; font.pointSize: 9; Controls.ToolTip.text: text; Controls.ToolTip.visible: milestoneHover.hovered; HoverHandler { id: milestoneHover } }
            }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: SpaceStyle.line }
            RowLayout {
                Layout.fillWidth: true
                Controls.ToolButton {
                    font.family: SpaceStyle.sans
                    text: "Read debrief"
                    font.pointSize: 9.75
                    onClicked: card.activated(card.flight)
                    contentItem: RowLayout {
                        spacing: 8
                        Controls.Label { text: "Read debrief"; color: SpaceStyle.text; font.family: SpaceStyle.sans; font.pointSize: 9.75 }
                        Kirigami.Icon { source: "go-next"; isMask: true; color: SpaceStyle.accent; Layout.preferredWidth: 14; Layout.preferredHeight: 14 }
                    }
                }
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
