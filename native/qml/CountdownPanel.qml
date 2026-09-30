pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.AbstractCard {
    id: panel
    required property var schedule
    property var countdown: null
    property bool busy: false
    property string errorMessage: ""
    signal refreshRequested()
    padding: Kirigami.Units.largeSpacing * 2
    background: Rectangle {
        parent: panel
        radius: Kirigami.Units.cornerRadius
        color: Kirigami.Theme.backgroundColor
        border.color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.12)
    }
    contentItem: ColumnLayout {
        spacing: Kirigami.Units.largeSpacing * 2
        GridLayout {
            Layout.fillWidth: true
            columns: panel.width > Kirigami.Units.gridUnit * 36 ? 2 : 1
            columnSpacing: Kirigami.Units.gridUnit * 2
            rowSpacing: Kirigami.Units.largeSpacing * 2
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing * 2
                Kirigami.Icon { source: "chronometer"; Layout.preferredWidth: Kirigami.Units.iconSizes.medium; Layout.preferredHeight: width; color: Kirigami.Theme.highlightColor }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    Controls.Label { text: "Next launch"; color: Kirigami.Theme.disabledTextColor }
                    Kirigami.Heading { text: "Flight " + panel.schedule.flight; level: 2; type: Kirigami.Heading.Primary }
                    Controls.Label { Layout.fillWidth: true; text: panel.schedule.location; color: Kirigami.Theme.disabledTextColor; wrapMode: Text.WordWrap }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing
                RowLayout {
                    Layout.fillWidth: true
                    visible: panel.countdown !== null
                    spacing: Kirigami.Units.largeSpacing * 2
                    Repeater {
                        model: ["days", "hours", "minutes", "seconds"]
                        delegate: ColumnLayout {
                            id: unit
                            required property string modelData
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing
                            Kirigami.Heading { Layout.alignment: Qt.AlignHCenter; text: panel.countdown ? panel.countdown[unit.modelData] : "—"; level: 1; font.family: "monospace" }
                            Controls.Label { Layout.alignment: Qt.AlignHCenter; text: unit.modelData; color: Kirigami.Theme.disabledTextColor }
                        }
                    }
                }
                Kirigami.Heading {
                    Layout.fillWidth: true
                    visible: panel.countdown === null
                    text: panel.schedule.status
                    level: 3
                    type: Kirigami.Heading.Primary
                    wrapMode: Text.WordWrap
                }
                Controls.Label {
                    Layout.fillWidth: true
                    text: panel.countdown ? (panel.countdown.elapsed ? "Launch window reached. Awaiting confirmation." : "Target launch time · subject to change") : "The countdown begins when a precise launch time is announced."
                    color: Kirigami.Theme.disabledTextColor
                    wrapMode: Text.WordWrap
                    lineHeight: 1.3
                }
            }
        }
        Kirigami.InlineMessage { Layout.fillWidth: true; visible: panel.errorMessage.length > 0; text: panel.errorMessage; type: Kirigami.MessageType.Warning }
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            Controls.Label { Layout.fillWidth: true; text: "Updated " + panel.schedule.checkedAt + " · " + panel.schedule.provider; color: Kirigami.Theme.disabledTextColor; wrapMode: Text.WordWrap; font: Kirigami.Theme.smallFont }
            Controls.BusyIndicator { running: panel.busy; visible: running; Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium; Layout.preferredHeight: width }
            Controls.ToolButton { text: "Refresh"; icon.name: "view-refresh"; display: Controls.AbstractButton.IconOnly; enabled: !panel.busy; onClicked: panel.refreshRequested(); Controls.ToolTip.text: text; Controls.ToolTip.visible: hovered }
            Controls.ToolButton { text: "Launch updates"; icon.name: "internet-services"; display: Controls.AbstractButton.IconOnly; onClicked: Qt.openUrlExternally(panel.schedule.source); Controls.ToolTip.text: text; Controls.ToolTip.visible: hovered }
        }
    }
}
