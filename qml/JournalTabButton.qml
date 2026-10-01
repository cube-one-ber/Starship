import QtQuick
import QtQuick.Controls.Basic as Basic
import org.starship.journal

Basic.TabButton {
    id: tab
    implicitHeight: 40
    padding: 8
    font.family: SpaceStyle.sans
    hoverEnabled: true
    contentItem: Basic.Label {
        text: tab.text
        font: tab.font
        color: tab.checked ? SpaceStyle.softAccent : SpaceStyle.muted
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        radius: 7
        color: tab.checked ? "#30eac38e" : tab.hovered ? SpaceStyle.raised : "transparent"
        border.color: tab.visualFocus ? SpaceStyle.accent : tab.checked ? "#60eac38e" : "transparent"
        border.width: tab.visualFocus ? 2 : 1
    }
}
