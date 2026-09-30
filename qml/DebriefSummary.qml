pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.starship.journal

GridLayout {
    id: summary
    objectName: "debriefSummary"
    required property var flight
    columns: width < 650 ? 1 : 3
    columnSpacing: 12
    rowSpacing: 12
    Repeater {
        model: [
            { label: "WHAT CHANGED", text: summary.flight.debrief.changed, color: SpaceStyle.cyan },
            { label: "WHAT WORKED", text: summary.flight.debrief.worked, color: SpaceStyle.positive },
            { label: "WHAT FELL SHORT", text: summary.flight.debrief.fell_short, color: SpaceStyle.accent }
        ]
        delegate: Controls.Control {
            id: finding
            required property var modelData
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            padding: 16
            background: Rectangle { radius: SpaceStyle.radius; color: SpaceStyle.surface; border.color: SpaceStyle.line }
            contentItem: ColumnLayout {
                spacing: 8
                SectionLabel { Layout.fillWidth: true; text: finding.modelData.label; color: finding.modelData.color }
                Controls.Label { Layout.fillWidth: true; text: finding.modelData.text; wrapMode: Text.WordWrap; color: SpaceStyle.text; font.family: SpaceStyle.sans; font.pointSize: 10.5 }
            }
        }
    }
}
