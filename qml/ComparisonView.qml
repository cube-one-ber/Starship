pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.starship.journal

ColumnLayout {
    id: comparison
    objectName: "flightComparison"
    required property var flights
    signal openRequested(var flight)
    readonly property var leftFlight: flights[leftChoice.currentIndex] || null
    readonly property var rightFlight: flights[rightChoice.currentIndex] || null
    readonly property var choices: flights.map(flight => "Flight " + flight.id + " · " + flight.date)
    property alias leftControl: leftChoice
    property alias rightControl: rightChoice
    spacing: 16
    function resetSelections() {
        leftChoice.currentIndex = flights.length ? 0 : -1
        rightChoice.currentIndex = flights.length > 1 ? 1 : flights.length ? 0 : -1
    }
    // ComboBox resets its index while applying a new model. Select the defaults
    // after both models have updated, including rapid filter changes.
    onFlightsChanged: Qt.callLater(resetSelections)
    Component.onCompleted: Qt.callLater(resetSelections)
    Kirigami.Heading { Layout.fillWidth: true; text: "Across two flights."; font.family: SpaceStyle.serif; font.pointSize: 24; wrapMode: Text.WordWrap }
    Controls.Label { Layout.fillWidth: true; text: "Choose flights from the current search and year filter."; color: SpaceStyle.muted; wrapMode: Text.WordWrap }
    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        Controls.ComboBox { id: leftChoice; Layout.fillWidth: true; Layout.minimumWidth: 0; model: comparison.choices; Accessible.name: "First flight to compare" }
        Controls.ComboBox { id: rightChoice; Layout.fillWidth: true; Layout.minimumWidth: 0; model: comparison.choices; Accessible.name: "Second flight to compare" }
    }
    Repeater {
        model: [
            { label: "GENERATION / VEHICLES", field: "generation" },
            { label: "MILESTONE", field: "milestone" },
            { label: "PAYLOAD / EXPERIMENT", field: "payload" },
            { label: "TRAJECTORY", field: "trajectory" },
            { label: "SHIP RESULT", field: "ship" },
            { label: "BOOSTER RESULT", field: "booster" }
        ]
        delegate: Controls.Control {
            id: fact
            objectName: "comparisonFact"
            required property var modelData
            Layout.fillWidth: true
            padding: 16
            background: Rectangle { radius: SpaceStyle.radius; color: SpaceStyle.surface; border.color: SpaceStyle.line }
            contentItem: ColumnLayout {
                spacing: 10
                SectionLabel { Layout.fillWidth: true; text: fact.modelData.label }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    Repeater {
                        model: [comparison.leftFlight, comparison.rightFlight]
                        delegate: Controls.Label {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            text: !modelData ? "—" : fact.modelData.field === "generation"
                                ? modelData.generation + " · " + modelData.ship_id + " / " + modelData.booster_id
                                : modelData[fact.modelData.field]
                            color: !modelData ? SpaceStyle.dim : fact.modelData.field === "ship" || fact.modelData.field === "booster"
                                ? (modelData[fact.modelData.field + "_outcome"] === "completed" ? SpaceStyle.positive : SpaceStyle.accent)
                                : SpaceStyle.text
                            wrapMode: Text.WordWrap
                            font.family: SpaceStyle.sans
                            Accessible.name: (modelData ? "Flight " + modelData.id + ", " : "") + fact.modelData.label + ": " + text
                        }
                    }
                }
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        Controls.Button { Layout.fillWidth: true; text: comparison.leftFlight ? "Read Flight " + comparison.leftFlight.id : "Read debrief"; enabled: comparison.leftFlight !== null; onClicked: comparison.openRequested(comparison.leftFlight) }
        Controls.Button { Layout.fillWidth: true; text: comparison.rightFlight ? "Read Flight " + comparison.rightFlight.id : "Read debrief"; enabled: comparison.rightFlight !== null; onClicked: comparison.openRequested(comparison.rightFlight) }
    }
}
