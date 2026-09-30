pragma ComponentBehavior: Bound
import QtQuick
import org.starship.journal
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.AbstractCard {
    id: panel
    required property var schedule
    property var countdown: null
    property bool busy: false
    property bool motionEnabled: true
    property string errorMessage: ""
    signal refreshRequested()
    padding: 26
    background: Rectangle {
        parent: panel
        radius: SpaceStyle.radius
        color: SpaceStyle.surface
        border.width: 1
        border.color: SpaceStyle.line
        clip: true
        OrbitalArtwork { anchors.fill: parent; grid: true }
        Rectangle { width: 40; height: 2; color: SpaceStyle.accent; x: 26; y: 0 }
    }
    contentItem: ColumnLayout {
        spacing: 18
        RowLayout {
            Layout.fillWidth: true
            SectionLabel { Layout.fillWidth: true; text: "UP NEXT / LAUNCH WINDOW" }
            Kirigami.Icon { source: "chronometer"; isMask: true; color: SpaceStyle.accent; Layout.preferredWidth: 18; Layout.preferredHeight: 18 }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5
            Controls.Label {
                text: "Flight " + panel.schedule.flight
                FadeBehavior on text { motionEnabled: panel.motionEnabled }
                color: SpaceStyle.text
                font.family: SpaceStyle.sans
                font.pointSize: 27
                font.weight: Font.Light
                font.letterSpacing: -0.8
            }
            Controls.Label { font.family: SpaceStyle.sans; Layout.fillWidth: true; text: panel.schedule.location; color: SpaceStyle.muted; font.pointSize: 9.75; wrapMode: Text.WordWrap }
        }
        Item { Layout.fillHeight: true; Layout.preferredHeight: 2 }
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: SpaceStyle.line }
        RowLayout {
            Layout.fillWidth: true
            visible: panel.countdown !== null
            spacing: 12
            Repeater {
                model: ["days", "hours", "minutes", "seconds"]
                delegate: ColumnLayout {
                    id: unit
                    required property string modelData
                    Layout.fillWidth: true
                    spacing: 6
                    Controls.Label { text: panel.countdown ? String(panel.countdown[unit.modelData]).padStart(2, "0") : "—"; FadeBehavior on text { motionEnabled: panel.motionEnabled } font.family: SpaceStyle.mono; font.pointSize: 21; color: SpaceStyle.accent }
                    SectionLabel { text: unit.modelData.toUpperCase(); color: SpaceStyle.dim; font.pointSize: 6; font.letterSpacing: 1 }
                }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            visible: panel.countdown === null
            spacing: 9
            SectionLabel { text: "AWAITING CONFIRMED LIFTOFF"; color: SpaceStyle.cyan; font.pointSize: 6.75; font.letterSpacing: 1 }
            Controls.Label { font.family: SpaceStyle.sans;
                Layout.fillWidth: true
                text: panel.schedule.status
                FadeBehavior on text { motionEnabled: panel.motionEnabled }
                color: SpaceStyle.text
                font.pointSize: 12.75
                font.weight: Font.Medium
                wrapMode: Text.WordWrap
            }
        }
        Controls.Label { font.family: SpaceStyle.sans;
            Layout.fillWidth: true
            text: panel.countdown ? (panel.countdown.elapsed ? "Launch window reached. Awaiting confirmation." : "Target launch time · subject to change") : "Countdown starts when a precise launch time is announced."
            color: SpaceStyle.muted
            font.pointSize: 9.75
            wrapMode: Text.WordWrap
            lineHeight: 1.35
        }
        Kirigami.InlineMessage { Layout.fillWidth: true; visible: panel.errorMessage.length > 0; text: panel.errorMessage; type: Kirigami.MessageType.Warning }
        Item { Layout.fillHeight: true; Layout.preferredHeight: 3 }
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                SectionLabel { text: panel.schedule.provider.toUpperCase(); color: SpaceStyle.dim; font.pointSize: 6.75; font.letterSpacing: 1 }
                Controls.Label { font.family: SpaceStyle.sans; text: "Updated " + panel.schedule.checkedAt; color: SpaceStyle.dim; font.pointSize: 8.25}
            }
            Controls.BusyIndicator { running: panel.busy; visible: running; Layout.preferredWidth: 22; Layout.preferredHeight: 22 }
            Controls.ToolButton { font.family: SpaceStyle.sans; text: "Refresh"; icon.name: "view-refresh"; display: Controls.AbstractButton.IconOnly; enabled: !panel.busy; onClicked: panel.refreshRequested(); Controls.ToolTip.text: text; Controls.ToolTip.visible: hovered }
            Controls.ToolButton { font.family: SpaceStyle.sans; text: "Launch updates"; icon.name: "internet-services"; display: Controls.AbstractButton.IconOnly; onClicked: Qt.openUrlExternally(panel.schedule.source); Controls.ToolTip.text: text; Controls.ToolTip.visible: hovered }
        }
    }
}
