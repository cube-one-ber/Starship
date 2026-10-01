pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.starship.journal

ColumnLayout {
    id: report
    required property var flight
    spacing: 28
    readonly property alias logTarget: logHeading
    readonly property alias analysisTarget: analysisHeading
    readonly property alias timelineTarget: timelineHeading
    readonly property alias recoveryTarget: recoveryHeading

    SectionLabel { id: logHeading; Layout.fillWidth: true; text: "FLIGHT LOG / WHAT HAPPENED" }
    Repeater {
        model: report.flight.details
        delegate: ColumnLayout {
            id: entry
            required property var modelData
            required property int index
            Layout.fillWidth: true
            spacing: 10
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                SectionLabel { text: String(entry.index + 1).padStart(2, "0"); font.letterSpacing: 0 }
                Kirigami.Heading {
                    objectName: "missionLogHeading"
                    Layout.fillWidth: true
                    text: entry.modelData.heading
                    level: 3
                    font.family: SpaceStyle.serif
                    font.pointSize: 18
                    color: SpaceStyle.text
                    wrapMode: Text.WordWrap
                }
            }
            Kirigami.SelectableLabel {
                Layout.fillWidth: true
                text: entry.modelData.body
                font.family: SpaceStyle.sans
                font.pointSize: 11.25
                color: SpaceStyle.muted
                wrapMode: Text.WordWrap
            }
        }
    }
    Kirigami.Separator { Layout.fillWidth: true }
    ColumnLayout {
        objectName: "independentAnalysis"
        Layout.fillWidth: true
        spacing: 16
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            SectionLabel { id: analysisHeading; Layout.fillWidth: true; text: "INDEPENDENT ANALYSIS"; elide: Text.ElideNone; wrapMode: Text.WordWrap }
            Controls.Label {
                Layout.fillWidth: true
                text: "Reconstructions, observations and estimates."
                font.family: SpaceStyle.sans
                font.pointSize: 9.75
                color: SpaceStyle.dim
                wrapMode: Text.WordWrap
            }
        }
        Repeater {
            model: report.flight.analysis
            delegate: Controls.Control {
                id: analysisEntry
                objectName: "independentAnalysisEntry"
                required property var modelData
                Layout.fillWidth: true
                padding: report.width < 440 ? 18 : 24
                background: Rectangle { radius: SpaceStyle.radius; color: SpaceStyle.surface; border.color: SpaceStyle.line }
                contentItem: ColumnLayout {
                    spacing: 12
                    SectionLabel {
                        Layout.fillWidth: true
                        text: analysisEntry.modelData.kind.toUpperCase() + " · " + analysisEntry.modelData.published
                        color: SpaceStyle.cyan
                        font.letterSpacing: 0.5
                        elide: Text.ElideNone
                        wrapMode: Text.WordWrap
                    }
                    Kirigami.Heading {
                        Layout.fillWidth: true
                        text: analysisEntry.modelData.title
                        font.family: SpaceStyle.serif
                        font.pointSize: 18
                        color: SpaceStyle.text
                        wrapMode: Text.WordWrap
                    }
                    Kirigami.SelectableLabel {
                        Layout.fillWidth: true
                        text: analysisEntry.modelData.summary
                        font.family: SpaceStyle.sans
                        font.pointSize: 10.5
                        color: SpaceStyle.muted
                        wrapMode: Text.WordWrap
                    }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 8
                        Controls.ToolButton {
                            font.family: SpaceStyle.sans
                            action: Kirigami.Action {
                                text: "Open analysis"
                                icon.name: "internet-services"
                                onTriggered: Qt.openUrlExternally(analysisEntry.modelData.source)
                            }
                        }
                        Controls.ToolButton {
                            visible: analysisEntry.modelData.context !== null
                            font.family: SpaceStyle.sans
                            action: Kirigami.Action {
                                text: analysisEntry.modelData.context_label
                                icon.name: "document-open"
                                onTriggered: { if (analysisEntry.modelData.context) Qt.openUrlExternally(analysisEntry.modelData.context) }
                            }
                        }
                    }
                }
            }
        }
    }
    Kirigami.Separator { Layout.fillWidth: true }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8
        SectionLabel { id: timelineHeading; Layout.fillWidth: true; text: "MISSION TIMELINE" }
        Controls.Label {
            Layout.fillWidth: true
            text: "Elapsed time from liftoff · approximate event times"
            font.family: SpaceStyle.sans
            font.pointSize: 9.75
            color: SpaceStyle.dim
            wrapMode: Text.WordWrap
        }
    }
    ColumnLayout {
        objectName: "missionTimeline"
        Layout.fillWidth: true
        spacing: 0
        Repeater {
            model: report.flight.timeline
            delegate: Controls.Control {
                id: eventRow
                required property var modelData
                required property int index
                Layout.fillWidth: true
                padding: 16
                background: Rectangle {
                    radius: 6
                    color: eventRow.index % 2 === 0 ? SpaceStyle.surface : "transparent"
                }
                contentItem: GridLayout {
                    columns: report.width < 440 ? 1 : 2
                    columnSpacing: 24
                    rowSpacing: 7
                    Controls.Label {
                        Layout.preferredWidth: report.width < 440 ? -1 : 146
                        Layout.alignment: Qt.AlignTop
                        text: eventRow.modelData.time
                        font.family: SpaceStyle.mono
                        font.pointSize: 10.5
                        color: SpaceStyle.cyan
                        wrapMode: Text.WordWrap
                    }
                    Controls.Label {
                        Layout.fillWidth: true
                        text: eventRow.modelData.event
                        font.family: SpaceStyle.sans
                        font.pointSize: 10.5
                        color: SpaceStyle.text
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
    SectionLabel { id: recoveryHeading; Layout.fillWidth: true; visible: report.flight.landings.length > 0; text: "RECOVERY GEOGRAPHY" }
    Repeater {
        model: report.flight.landings
        delegate: Controls.Control {
            id: landingPanel
            objectName: "landingEstimate"
            required property var modelData
            readonly property var estimate: modelData
            Layout.fillWidth: true
            padding: report.width < 440 ? 18 : 24
            background: Rectangle { radius: SpaceStyle.radius; color: SpaceStyle.surface; border.color: SpaceStyle.line }
            contentItem: ColumnLayout {
                spacing: 15
                Kirigami.Heading {
                    Layout.fillWidth: true
                    text: landingPanel.estimate ? landingPanel.estimate.vehicle : ""
                    font.family: SpaceStyle.serif
                    font.pointSize: 20
                    color: SpaceStyle.text
                    wrapMode: Text.WordWrap
                }
                Kirigami.SelectableLabel {
                    objectName: "landingCoordinates"
                    Layout.fillWidth: true
                    text: landingPanel.estimate ? landingPanel.estimate.coordinates : ""
                    font.family: SpaceStyle.mono
                    font.pointSize: report.width < 440 ? 15 : 21
                    color: SpaceStyle.cyan
                    wrapMode: Text.WordWrap
                }
                SectionLabel { Layout.fillWidth: true; text: landingPanel.estimate ? landingPanel.estimate.precision.toUpperCase() : ""; color: SpaceStyle.dim; font.letterSpacing: 0.8 }
                Kirigami.SelectableLabel {
                    Layout.fillWidth: true
                    text: landingPanel.estimate ? landingPanel.estimate.note : ""
                    font.family: SpaceStyle.sans
                    font.pointSize: 10.5
                    color: SpaceStyle.muted
                    wrapMode: Text.WordWrap
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 8
                    Controls.ToolButton {
                        font.family: SpaceStyle.sans
                        action: Kirigami.Action {
                            text: "View on map"
                            icon.name: "mark-location"
                            onTriggered: {
                                const location = landingPanel.estimate
                                if (location) Qt.openUrlExternally("https://www.openstreetmap.org/?mlat=" + location.latitude + "&mlon=" + location.longitude + "#map=7/" + location.latitude + "/" + location.longitude)
                            }
                        }
                    }
                    Controls.ToolButton {
                        font.family: SpaceStyle.sans
                        action: Kirigami.Action {
                            text: "Original analysis"
                            icon.name: "internet-services"
                            onTriggered: { if (landingPanel.estimate) Qt.openUrlExternally(landingPanel.estimate.source) }
                        }
                    }
                }
            }
        }
    }
}
