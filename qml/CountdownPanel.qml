pragma ComponentBehavior: Bound
import QtQuick
import org.starship.journal
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.AbstractCard {
    id: panel
    objectName: "launchPanel"
    required property var schedule
    required property var scheduleState
    readonly property bool collapsed: collapsible && !expanded
    readonly property string freshnessText: {
        const state = scheduleState
        if (state.origin === "bundled") return "Bundled snapshot · " + schedule.checkedAt
        if (state.ageSeconds === null) return "Saved schedule · update time unknown"
        const minutes = Math.floor(state.ageSeconds / 60)
        const age = minutes < 1 ? "just now" : minutes < 60 ? minutes + " min ago"
            : minutes < 1440 ? Math.floor(minutes / 60) + " h ago" : Math.floor(minutes / 1440) + " days ago"
        return (state.origin === "live" ? "Updated " : "Saved · updated ") + age
    }
    property var countdown: null
    property bool busy: false
    property bool motionEnabled: true
    property bool compact: false
    property bool collapsible: false
    property bool expanded: false
    readonly property bool detailsVisible: !collapsible || expanded
    readonly property string windowText: schedule.launchAt && !isNaN(Date.parse(schedule.launchAt))
        ? new Date(schedule.launchAt).toISOString().slice(0, 16).replace("T", " · ") + " UTC"
        : schedule.status.split(" · ")[0]
    property string errorMessage: ""
    signal refreshRequested()
    padding: collapsed ? 12 : 16
    background: Rectangle {
        parent: panel
        radius: SpaceStyle.radius
        gradient: Gradient { GradientStop { position: 0; color: "#192b38" } GradientStop { position: 1; color: SpaceStyle.surface } }
        border.width: 1
        border.color: SpaceStyle.line
        clip: true
        OrbitalArtwork { anchors.fill: parent; ink: SpaceStyle.accent; grid: true; opacity: panel.detailsVisible ? 0.55 : 0.25 }
        Controls.Label { anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 24; text: String(panel.schedule.flight).padStart(2, "0"); color: SpaceStyle.accent; opacity: 0.065; font.family: SpaceStyle.mono; font.pointSize: panel.compact ? 67.5 : 90; Accessible.ignored: true }
        Rectangle { width: 40; height: 2; color: SpaceStyle.accent; x: 24; y: 0 }
    }
    contentItem: ColumnLayout {
        spacing: 8
        RowLayout {
            Layout.fillWidth: true
            SectionLabel { Layout.fillWidth: true; text: "UP NEXT / FLIGHT " + String(panel.schedule.flight).padStart(3, "0"); font.pointSize: 9; font.letterSpacing: 0.6 }
            Controls.BusyIndicator { running: panel.busy; visible: running; Layout.preferredWidth: 22; Layout.preferredHeight: 22 }
            JournalButton { flat: true;
                font.family: SpaceStyle.sans
                text: "Refresh schedule"
                icon.name: "view-refresh"
                display: Controls.AbstractButton.IconOnly
                enabled: !panel.busy
                onClicked: panel.refreshRequested()
                Controls.ToolTip.text: text
                Controls.ToolTip.visible: hovered
            }
        }
        Controls.Label {
            objectName: "launchWindow"
            Layout.fillWidth: true
            text: panel.windowText
            FadeBehavior on text { motionEnabled: panel.motionEnabled }
            font.family: SpaceStyle.serif
            font.pointSize: panel.collapsed ? 17 : panel.compact ? 21 : 24
            font.letterSpacing: -0.5
            color: SpaceStyle.text
            wrapMode: Text.WordWrap
        }
        Controls.Label {
            Layout.fillWidth: true
            visible: !panel.collapsed
            text: panel.scheduleState.stale ? "Timing needs a refresh" : panel.countdown
                ? (panel.countdown.elapsed ? "Launch window reached · awaiting confirmation" : "Target launch time · subject to change")
                : (panel.schedule.status.indexOf(" · ") >= 0 ? panel.schedule.status.split(" · ").slice(1).join(" · ") : "No confirmed liftoff time")
            font.family: SpaceStyle.sans
            font.pointSize: 10.5
            color: SpaceStyle.cyan
            wrapMode: Text.WordWrap
        }
        RowLayout {
            Layout.fillWidth: true
            visible: panel.countdown !== null
            spacing: 8
            Repeater {
                model: ["days", "hours", "minutes", "seconds"]
                delegate: ColumnLayout {
                    id: unit
                    required property string modelData
                    Layout.fillWidth: true
                    spacing: 4
                    Controls.Label { text: panel.countdown ? String(panel.countdown[unit.modelData]).padStart(2, "0") : "—"; FadeBehavior on text { motionEnabled: panel.motionEnabled } font.family: SpaceStyle.mono; font.pointSize: 21; color: SpaceStyle.accent }
                    SectionLabel { text: unit.modelData.toUpperCase(); color: SpaceStyle.dim; font.pointSize: 9; font.letterSpacing: 0 }
                }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            visible: panel.detailsVisible
            spacing: 6
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Kirigami.Icon { source: "mark-location"; isMask: true; color: SpaceStyle.dim; Layout.preferredWidth: 14; Layout.preferredHeight: 14 }
                Controls.Label { font.family: SpaceStyle.sans; Layout.fillWidth: true; text: panel.schedule.location; color: SpaceStyle.muted; font.pointSize: 10; wrapMode: Text.WordWrap }
            }
            Controls.Label {
                Layout.fillWidth: true
                visible: panel.countdown === null
                text: "Countdown starts when a precise launch time is announced."
                color: SpaceStyle.muted
                font.family: SpaceStyle.sans
                font.pointSize: 10
                wrapMode: Text.WordWrap
            }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: SpaceStyle.line }
            Controls.Label {
                Layout.fillWidth: true
                text: panel.schedule.provider + " · " + panel.schedule.checkedAt
                color: SpaceStyle.dim
                font.family: SpaceStyle.sans
                font.pointSize: 9
                wrapMode: Text.WordWrap
            }
        }
        Controls.Label {
            objectName: "scheduleFreshness"
            Layout.fillWidth: true
            text: panel.freshnessText + (panel.scheduleState.stale ? " · stale" : "")
            color: panel.scheduleState.stale ? SpaceStyle.accent : SpaceStyle.dim
            font.family: SpaceStyle.sans
            font.pointSize: 9
            wrapMode: Text.WordWrap
            Accessible.description: panel.scheduleState.stale ? "Schedule is stale. Refresh to confirm launch timing. Countdown paused." : "Schedule timing is current."
        }
        // Failed refreshes stay visible even when the launch summary is collapsed.
        Kirigami.InlineMessage { Layout.fillWidth: true; visible: panel.errorMessage.length > 0; text: panel.errorMessage; type: Kirigami.MessageType.Warning }
        RowLayout {
            Layout.fillWidth: true
            JournalButton { flat: true;
                objectName: "launchDetailsToggle"
                visible: panel.collapsible
                text: panel.expanded ? "Hide details" : "Launch details"
                icon.name: panel.expanded ? "go-up" : "go-down"
                font.family: SpaceStyle.sans
                font.pointSize: 10
                Accessible.description: panel.expanded ? "Launch details expanded" : "Launch details collapsed"
                onClicked: panel.expanded = !panel.expanded
            }
            Item { Layout.fillWidth: true; visible: panel.collapsible }
            JournalButton { flat: true;
                visible: panel.detailsVisible
                text: "Launch updates"
                icon.name: "internet-services"
                font.family: SpaceStyle.sans
                font.pointSize: 10
                onClicked: Qt.openUrlExternally(panel.schedule.source)
            }
        }
    }
}
