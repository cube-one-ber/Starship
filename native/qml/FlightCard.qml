pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.AbstractCard {
    id: card
    objectName: "flightCard"
    required property var flight
    property bool useJxl: false
    readonly property alias status: photo.status
    readonly property bool jxlLoaded: photo.useJxl
    signal activated(var flight)
    padding: 0
    showClickFeedback: true
    Accessible.name: "Flight " + flight.id + ": " + flight.title
    background: Rectangle {
        parent: card
        radius: Kirigami.Units.cornerRadius
        color: Kirigami.Theme.backgroundColor
        border.color: card.hovered || card.activeFocus ? Kirigami.Theme.highlightColor
            : Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.12)
        Behavior on border.color { ColorAnimation { duration: Kirigami.Units.shortDuration } }
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
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.largeSpacing * 2
            spacing: Kirigami.Units.largeSpacing
            RowLayout {
                Layout.fillWidth: true
                Controls.Label { Layout.fillWidth: true; text: "Flight " + card.flight.id; font.bold: true; color: Kirigami.Theme.linkColor }
                Controls.Label { text: new Date(card.flight.date + "T12:00:00Z").toLocaleDateString(Qt.locale(), "dd MMM yyyy"); color: Kirigami.Theme.disabledTextColor }
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
                elide: Text.ElideRight
            }
            FontMetrics { id: headingMetrics; font: heading.font }
            Controls.Label {
                id: summary
                Layout.fillWidth: true
                Layout.minimumHeight: summaryMetrics.lineSpacing * 3 * 1.25 + 4
                text: card.flight.summary
                wrapMode: Text.WordWrap
                lineHeight: 1.25
                maximumLineCount: 3
                elide: Text.ElideRight
                color: Kirigami.Theme.disabledTextColor
            }
            FontMetrics { id: summaryMetrics; font: summary.font }
            RowLayout {
                Layout.fillWidth: true
                Kirigami.Icon {
                    source: card.flight.outcome === "Vehicle lost" ? "dialog-warning" : "dialog-ok-apply"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: width
                    isMask: true
                    color: card.flight.outcome === "Vehicle lost" ? Kirigami.Theme.neutralTextColor : Kirigami.Theme.positiveTextColor
                }
                Controls.Label { Layout.fillWidth: true; text: card.flight.milestone; elide: Text.ElideRight }
            }
            Kirigami.Separator { Layout.fillWidth: true }
            RowLayout {
                Layout.fillWidth: true
                Controls.ToolButton { text: "Read debrief"; icon.name: "go-next"; onClicked: card.activated(card.flight) }
                Item { Layout.fillWidth: true }
                Controls.ToolButton {
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
