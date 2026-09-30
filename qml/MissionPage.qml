pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import QtCore as Core
import org.kde.kirigami as Kirigami
import org.starship.journal

Kirigami.ScrollablePage {
    required property var root
    required property var backend
    id: mission
    required property var flight
    property alias contentMotion: missionContent
    readonly property string activeSection: {
        const scroll = flickable.contentY + 24
        const sections = [
            { name: "overview", target: missionOverview },
            { name: "log", target: missionReport.logTarget },
            { name: "analysis", target: missionReport.analysisTarget },
            { name: "timeline", target: missionReport.timelineTarget },
            { name: "recovery", target: missionReport.recoveryTarget }
        ]
        let active = "overview"
        for (const entry of sections) {
            if (entry.name === "recovery" && !flight.landings.length) continue
            if (entry.target.mapToItem(flickable.contentItem, 0, 0).y <= scroll) active = entry.name
        }
        return active
    }
    function jumpTo(section) {
        const target = section === "overview" ? missionOverview
            : section === "log" ? missionReport.logTarget
            : section === "analysis" ? missionReport.analysisTarget
            : section === "timeline" ? missionReport.timelineTarget : missionReport.recoveryTarget
        const top = target.mapToItem(mission.flickable.contentItem, 0, 0).y - 16
        mission.flickable.contentY = Math.max(0, Math.min(top, mission.flickable.contentHeight - mission.flickable.height))
    }
    function changeFlight(id) {
        const next = JSON.parse(backend.mission(id))
        if (!next) return
        const direction = id > flight.id ? 1 : -1
        missionContent.swap(function() { mission.flight = next; mission.flickable.contentY = 0 }, direction)
    }
    title: "Flight " + flight.id
    padding: root.narrowTest || root.width < 810 ? 20 : 32
    actions: [Kirigami.Action { text: "Official report"; icon.name: "internet-services"; onTriggered: Qt.openUrlExternally(mission.flight.source) }]
    header: Controls.Control {
        leftPadding: mission.padding
        rightPadding: mission.padding
        topPadding: 6
        bottomPadding: 6
        background: Rectangle { color: SpaceStyle.voidColor; Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: SpaceStyle.line } }
        contentItem: ColumnLayout {
            spacing: 2
            RowLayout {
                Layout.fillWidth: true
                Controls.Button { objectName: "returnToArchive"; text: "Flight archive"; icon.name: "view-grid"; font.family: SpaceStyle.sans; onClicked: root.showArchive() }
                Item { Layout.fillWidth: true }
                Controls.ToolButton { text: "Flight " + (mission.flight.id - 1); icon.name: "go-previous"; font.family: SpaceStyle.sans; enabled: mission.flight.id > 1; Accessible.name: "Previous flight, Flight " + (mission.flight.id - 1); onClicked: mission.changeFlight(mission.flight.id - 1) }
                Controls.ToolButton { text: "Flight " + (mission.flight.id + 1); icon.name: "go-next"; font.family: SpaceStyle.sans; visible: mission.flight.id < root.latestFlightId; Accessible.name: "Next flight, Flight " + (mission.flight.id + 1); onClicked: mission.changeFlight(mission.flight.id + 1) }
            }
            Flow {
                Layout.fillWidth: true
                spacing: 4
                Repeater {
                    model: [{ label: "Overview", section: "overview" }, { label: "Flight log", section: "log" }, { label: "Analysis", section: "analysis" }, { label: "Timeline", section: "timeline" }, { label: "Recovery", section: "recovery" }]
                    delegate: Controls.ToolButton {
                        required property var modelData
                        objectName: "missionJump_" + modelData.section
                        visible: modelData.section !== "recovery" || mission.flight.landings.length > 0
                        text: modelData.label
                        checkable: true
                        checked: mission.activeSection === modelData.section
                        font.family: SpaceStyle.sans
                        font.pointSize: 10
                        onClicked: mission.jumpTo(modelData.section)
                    }
                }
            }
        }
    }
    AnimatedColumn {
        id: missionContent
        motionEnabled: root.motionEnabled
        width: mission.availableWidth
        spacing: 20
        Photo {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(mission.width / 3, 200)
            cornerRadius: SpaceStyle.radius
            cornerColor: SpaceStyle.voidColor
            path: mission.flight.photo.path
            useJxl: backend.supports_jxl
            motionEnabled: root.motionEnabled
            description: mission.flight.photo.alt
            Rectangle {
                anchors.fill: parent
                gradient: Gradient { GradientStop { position: 0.35; color: "transparent" } GradientStop { position: 1; color: "#df090e16" } }
            }
            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: mission.width < 600 ? 16 : 24
                spacing: 7
                SectionLabel { Layout.fillWidth: true; text: "MISSION DEBRIEF / STARBASE" }
                Controls.Label { font.family: SpaceStyle.sans; text: "FLIGHT " + String(mission.flight.id).padStart(3, "0"); color: SpaceStyle.text; font.pointSize: (mission.width < 600 ? 26 : 38) * 0.75; font.weight: Font.Light; font.letterSpacing: 3 }
                Controls.Label { Layout.fillWidth: true; text: new Date(mission.flight.date + "T12:00:00Z").toLocaleDateString(Qt.locale(), "dd MMMM yyyy") + "  ·  " + mission.flight.outcome; color: "#dbe2eb"; font.family: SpaceStyle.sans; font.pointSize: 10.5; wrapMode: Text.WordWrap }
            }
        }
        ColumnLayout {
            id: missionOverview
            Layout.fillWidth: true
            Layout.maximumWidth: 860
            Layout.alignment: Qt.AlignHCenter
            spacing: Kirigami.Units.largeSpacing * 2
            Kirigami.Heading { text: mission.flight.title; level: 1; font.family: SpaceStyle.serif; font.pointSize: (mission.width < 600 ? 34 : 44) * 0.75; font.letterSpacing: -0.7; color: SpaceStyle.text; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            Controls.Label { font.family: SpaceStyle.sans; text: mission.flight.summary; wrapMode: Text.WordWrap; Layout.fillWidth: true; color: SpaceStyle.muted; font.pointSize: 12; lineHeight: 1.4 }
            DebriefSummary { Layout.fillWidth: true; flight: mission.flight }
            Controls.Control {
                Layout.fillWidth: true
                padding: 22
                background: Rectangle { radius: SpaceStyle.radius; color: SpaceStyle.surface; border.color: SpaceStyle.line }
                contentItem: GridLayout {
                    columns: mission.width < 650 ? 2 : 3
                    columnSpacing: 24
                    rowSpacing: 24
                    MissionStat { Layout.fillWidth: true; label: "LIFTOFF / UTC"; value: new Date(mission.flight.date + "T12:00:00Z").toLocaleDateString(Qt.locale(), "dd MMM yyyy") + "\n" + mission.flight.launch_time }
                    MissionStat { Layout.fillWidth: true; label: "LAUNCH SITE"; value: mission.flight.launch_site }
                    MissionStat { Layout.fillWidth: true; label: "TRAJECTORY"; value: mission.flight.trajectory }
                    MissionStat { Layout.fillWidth: true; label: "SUPER HEAVY"; value: mission.flight.booster_id + "\n" + mission.flight.booster }
                    MissionStat { Layout.fillWidth: true; label: "STARSHIP / " + mission.flight.generation; value: mission.flight.ship_id + "\n" + mission.flight.ship }
                    MissionStat { Layout.fillWidth: true; label: "PAYLOAD / EXPERIMENT"; value: mission.flight.payload; valueColor: SpaceStyle.cyan }
                }
            }
            Kirigami.Separator { Layout.fillWidth: true }
            MissionReport { id: missionReport; Layout.fillWidth: true; flight: mission.flight }
            Controls.Label { font.family: SpaceStyle.sans; text: mission.flight.photo.credit; color: SpaceStyle.muted; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            Kirigami.ActionToolBar {
                Layout.fillWidth: true
                actions: [
                    Kirigami.Action { text: "Official report & replay"; icon.name: "internet-services"; onTriggered: Qt.openUrlExternally(mission.flight.source) },
                    Kirigami.Action { text: "Photo credit"; icon.name: "camera-photo"; onTriggered: Qt.openUrlExternally(mission.flight.photo.url) }
                ]
            }
            Kirigami.Separator { Layout.fillWidth: true }
            RowLayout {
                Layout.fillWidth: true
                Controls.Button { font.family: SpaceStyle.sans; text: "Previous · Flight " + (mission.flight.id - 1); icon.name: "go-previous"; enabled: mission.flight.id > 1; onClicked: mission.changeFlight(mission.flight.id - 1) }
                Item { Layout.fillWidth: true }
                Controls.Button { font.family: SpaceStyle.sans; text: "Next · Flight " + (mission.flight.id + 1); icon.name: "go-next"; enabled: mission.flight.id < root.latestFlightId; onClicked: mission.changeFlight(mission.flight.id + 1) }
            }
        }
    }
}
