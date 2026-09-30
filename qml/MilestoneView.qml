pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.starship.journal

ColumnLayout {
    id: milestones
    objectName: "flightMilestones"
    required property var flights
    signal openRequested(var flight)
    spacing: 12
    Kirigami.Heading { Layout.fillWidth: true; text: "Step by step."; font.family: SpaceStyle.serif; font.pointSize: 24; wrapMode: Text.WordWrap }
    Controls.Label { Layout.fillWidth: true; text: "Chronological milestones from the current search and year filter."; color: SpaceStyle.muted; wrapMode: Text.WordWrap }
    Repeater {
        model: milestones.flights
        delegate: Kirigami.AbstractCard {
            id: milestone
            objectName: "milestoneEntry"
            required property var modelData
            Layout.fillWidth: true
            padding: 18
            Accessible.name: "Flight " + modelData.id + ": " + modelData.milestone
            onClicked: milestones.openRequested(modelData)
            background: Rectangle { radius: SpaceStyle.radius; color: milestone.hovered || milestone.activeFocus ? SpaceStyle.raised : SpaceStyle.surface; border.color: milestone.activeFocus ? SpaceStyle.accent : SpaceStyle.line }
            contentItem: ColumnLayout {
                spacing: 8
                SectionLabel { Layout.fillWidth: true; text: milestone.modelData.date + " / FLIGHT " + String(milestone.modelData.id).padStart(3, "0"); color: SpaceStyle.dim }
                Kirigami.Heading { Layout.fillWidth: true; text: milestone.modelData.milestone; font.family: SpaceStyle.serif; font.pointSize: 20; wrapMode: Text.WordWrap; color: SpaceStyle.accent }
                Controls.Label { Layout.fillWidth: true; text: milestone.modelData.debrief.changed; wrapMode: Text.WordWrap; color: SpaceStyle.muted }
                Controls.Label { Layout.fillWidth: true; text: milestone.modelData.generation + " · " + milestone.modelData.ship_id + " / " + milestone.modelData.booster_id + "   → Read debrief"; wrapMode: Text.WordWrap; color: SpaceStyle.dim; font.pointSize: 10 }
            }
        }
    }
}
