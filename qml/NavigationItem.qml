pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.starship.journal

Controls.ItemDelegate {
    id: item
    property bool selected: false
    property string number: ""
    property bool motionEnabled: true
    implicitHeight: 46
    leftPadding: 16
    rightPadding: 14
    Accessible.role: Accessible.PageTab
    Accessible.selected: selected
    Accessible.name: text
    background: Rectangle {
        radius: 8
        color: item.down ? "#34402e" : item.selected ? "#262d31" : item.hovered ? SpaceStyle.surface : "transparent"
        border.color: item.activeFocus ? SpaceStyle.accent : item.selected ? "#55eac38e" : "transparent"
        Behavior on color { enabled: item.motionEnabled; ColorAnimation { duration: Kirigami.Units.shortDuration } }
        Rectangle { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: 2; height: 18; radius: 1; color: SpaceStyle.accent; visible: item.selected }
    }
    contentItem: RowLayout {
        spacing: 12
        Kirigami.Icon { source: item.icon.name; isMask: true; color: item.selected ? SpaceStyle.accent : SpaceStyle.dim; Layout.preferredWidth: 18; Layout.preferredHeight: 18 }
        Controls.Label { Layout.fillWidth: true; text: item.text; color: item.selected ? SpaceStyle.softAccent : SpaceStyle.muted; font.family: SpaceStyle.sans; font.pointSize: 10.5; font.weight: item.selected ? Font.Medium : Font.Normal; elide: Text.ElideRight }
        Controls.Label { text: item.number; color: item.selected ? SpaceStyle.accent : SpaceStyle.dim; font.family: SpaceStyle.mono; font.pointSize: 9 }
    }
}
